import assert from 'node:assert/strict';
import { readFile } from 'node:fs/promises';
import { PGlite } from '@electric-sql/pglite';
import { pgcrypto } from '@electric-sql/pglite/contrib/pgcrypto';

const pg = new PGlite({ extensions: { pgcrypto } });
const users = ['00000000-0000-4000-8000-000000000001', '00000000-0000-4000-8000-000000000002', '00000000-0000-4000-8000-000000000003'];
let checks = 0;
async function check(name, run) { await run(); checks++; console.log(`ok ${checks} - ${name}`); }
async function asUser(id, role = 'authenticated') {
  await pg.exec('reset role');
  await pg.query("select set_config('request.jwt.claim.sub', $1, false)", [id ?? '']);
  await pg.exec(`set role ${role}`);
}
const value = async (sql, params = []) => (await pg.query(sql, params)).rows[0].value;
const denied = (operation, code = '42501') => assert.rejects(operation, (error) => error.code === code);

try {
  await pg.exec(`
    create role anon;
    create role authenticated;
    create role service_role bypassrls;
    create schema auth;
    create schema extensions;
    create table auth.users(id uuid primary key);
    create function auth.uid() returns uuid language sql stable as
      $$ select nullif(current_setting('request.jwt.claim.sub', true), '')::uuid $$;
    grant usage on schema auth, public, extensions to anon, authenticated, service_role;
    alter default privileges in schema public grant all on tables to anon, authenticated, service_role;
    create publication supabase_realtime;
  `);
  const migration = await readFile(new URL('../migrations/202610310001_miga_data.sql', import.meta.url), 'utf8');
  await pg.exec(migration);
  const surpriseMigration = await readFile(new URL('../migrations/202610310002_surprise_quota.sql', import.meta.url), 'utf8');
  await pg.exec(surpriseMigration);
  await pg.exec(await readFile(new URL('../migrations/202611010001_recipe_catalog.sql', import.meta.url), 'utf8'));
  for (const id of users) await pg.query('insert into auth.users values ($1)', [id]);
  await asUser(users[0]);
  await check('Owner creates and reads their complete state', async () => {
    assert.equal(await value("select public.miga_put_document('state', '{\"home\":{},\"plan\":{}}', 0) as value"), 1);
    assert.equal(await value('select count(*)::int as value from public.miga_documents'), 1);
  });
  await check('State update requires the current revision', async () => {
    await denied(() => pg.query("select public.miga_put_document('state', '{}', 0)"), '40001');
    assert.equal(await value("select public.miga_put_document('state', '{}', 1) as value"), 2);
    await denied(() => pg.query("select public.miga_put_document('state', '{}', 1)"), '40001');
  });
  await check('Direct document writes cannot bypass revision checks', async () => {
    await denied(() => pg.query("update public.miga_documents set data = '{}'"));
    await denied(() => pg.query('delete from public.miga_documents'));
  });
  await asUser(users[1]);
  await check('Another account cannot read the owner state', async () => {
    assert.equal(await value('select count(*)::int as value from public.miga_documents'), 0);
    assert.equal(await value("select public.miga_put_document('state', '{}', 0) as value"), 1);
    assert.equal(await value('select count(*)::int as value from public.miga_documents'), 1);
  });
  await asUser(null, 'anon');
  await check('Anonymous clients cannot read or mutate state', async () => {
    assert.equal(await value('select count(*)::int as value from public.miga_documents'), 0);
    await denied(() => pg.query("select public.miga_put_document('state', '{}', 0)"));
  });
  await asUser(users[0]);
  const invitation = await value("select public.miga_create_list('[{\"name\":\"Rice\"}]') as value");
  await asUser(users[1]);
  await check('Shared lists remain private before joining', async () => {
    assert.equal(await value('select count(*)::int as value from public.miga_shared_lists'), 0);
    await denied(() => pg.query('select public.miga_update_list($1, 1, $2::jsonb)', [invitation.id, '[]']));
    await denied(() => pg.query('insert into public.miga_list_members values($1, $2)', [invitation.id, users[1]]));
  });
  await check('Invalid invitations cannot add members', async () => {
    await denied(() => pg.query("select public.miga_join_list('wrong')"), 'P0001');
  });
  await check('Invitation grants access only to the matching list', async () => {
    assert.equal(await value('select public.miga_join_list($1) as value', [invitation.invitation]), invitation.id);
    assert.equal(await value('select count(*)::int as value from public.miga_shared_lists'), 1);
    assert.equal(await value('select public.miga_update_list($1, 1, $2::jsonb) as value', [invitation.id, '[{"name":"Milk"}]']), 2);
  });
  await asUser(users[0]);
  await check('Stale shared edits cannot overwrite a member update', async () => {
    await denied(() => pg.query('select public.miga_update_list($1, 1, $2::jsonb)', [invitation.id, '[]']), '40001');
    const rows = await pg.query('select data from public.miga_shared_lists');
    assert.equal(rows.rows[0].data[0].name, 'Milk');
  });
  await asUser(users[2]);
  await check('A third account cannot see or edit a joined list', async () => {
    assert.equal(await value('select count(*)::int as value from public.miga_shared_lists'), 0);
    await denied(() => pg.query('select public.miga_update_list($1, 2, $2::jsonb)', [invitation.id, '[]']));
  });
  await check('Clients cannot grant themselves Pro or read store tokens', async () => {
    await denied(() => pg.query('insert into public.miga_entitlements values($1, $2, $3, $4, now(), now())', [users[2], 'apple', 'pro', 'fake']));
    await denied(() => pg.query('select public.miga_record_subscription($1,$2,$3,$4,$5,now())', [users[2], 'apple', 'pro', 'fake', 'fake']));
    await denied(() => pg.query('select * from public.miga_purchase_sources'));
  });
  await check('Live sharing requires a server-verified unexpired entitlement', async () => {
    await pg.exec('reset role');
    await pg.query('update public.miga_configuration set pro_required = true');
    await asUser(users[0]);
    await denied(() => pg.query("select public.miga_create_list('[]')"));
    await pg.exec('reset role');
    await pg.query("select public.miga_record_subscription($1, 'apple', 'pro', 'verified-server-fixture', 'fixture', now() + interval '1 day')", [users[0]]);
    await asUser(users[0]);
    assert.ok(await value("select public.miga_create_list('[]') as value"));
    await pg.exec('reset role');
    await pg.query("update public.miga_entitlements set expires_at = now() - interval '1 second'");
    await asUser(users[1]);
    await denied(() => pg.query('select public.miga_update_list($1, 2, $2::jsonb)', [invitation.id, '[]']));
  });
  await asUser(users[2]);
  await check('Surprise me uses three free credits per account', async () => {
    assert.equal((await value('select public.miga_surprise_remaining() as value')).remaining, 3);
    for (const remaining of [2, 1, 0]) {
      const result = await value('select public.miga_consume_surprise() as value');
      assert.equal(result.allowed, true);
      assert.equal(result.remaining, remaining);
    }
    const blocked = await value('select public.miga_consume_surprise() as value');
    assert.equal(blocked.allowed, false);
    assert.equal(blocked.remaining, 0);
    await denied(() => pg.query('update public.miga_surprise_uses set used=0'));
    await denied(() => pg.query('delete from public.miga_surprise_uses'));
  });
  await asUser(users[1]);
  await check('Another account gets its own three Surprise credits', async () => {
    assert.equal((await value('select public.miga_surprise_remaining() as value')).remaining, 3);
    assert.equal((await value('select public.miga_consume_surprise() as value')).remaining, 2);
  });
  await asUser(null, 'anon');
  await check('Anonymous users cannot call Surprise RPCs', async () => {
    await denied(() => pg.query('select public.miga_consume_surprise()'));
    await denied(() => pg.query('select public.miga_surprise_remaining()'));
  });
  await pg.exec('reset role');
  await pg.query("update public.miga_entitlements set expires_at = now() + interval '1 day' where user_id = $1", [users[0]]);
  await asUser(users[0]);
  await check('Server-verified Pro gets unlimited Surprise use', async () => {
    for (let i = 0; i < 5; i++) {
      const result = await value('select public.miga_consume_surprise() as value');
      assert.equal(result.allowed, true);
      assert.equal(result.pro, true);
      assert.equal(result.remaining, 3);
    }
  });
  await pg.exec('reset role');
  await check('Account deletion cascades to owned state, shared lists and memberships', async () => {
    await pg.query('delete from auth.users where id = $1', [users[0]]);
    assert.equal(await value('select count(*)::int as value from public.miga_shared_lists'), 0);
    assert.equal(await value('select count(*)::int as value from public.miga_list_members'), 0);
    assert.equal(await value('select count(*)::int as value from public.miga_documents'), 1);
  });
  await pg.exec('reset role');
  const catalog = JSON.parse(await readFile(new URL('../catalog/recipes.json', import.meta.url), 'utf8')).recipes;
  await check('All 54 migrated recipes pass database content validation', async () => {
    for (const recipe of catalog) {
      assert.equal(await value('select public.miga_recipe_content_valid($1::jsonb) as value', [JSON.stringify(recipe)]), true, recipe.id);
      await pg.query("insert into public.miga_recipes(id,data,status) values ($1,$2,'published')", [recipe.id, JSON.stringify(recipe)]);
    }
    const draft = {...catalog[0], id:'editorial-draft'};
    await pg.query("insert into public.miga_recipes(id,data) values ($1,$2)", [draft.id, JSON.stringify(draft)]);
  });
  for (const role of ['anon','authenticated']) {
    await asUser(role === 'anon' ? null : users[1], role);
    await check(`${role} can only read published catalog content`, async () => {
      assert.equal(await value('select count(*)::int as value from public.miga_recipes'), 54);
      assert.equal((await value('select public.miga_recipe_snapshot() as value')).length, 54);
      assert.equal(await value("select count(*)::int as value from public.miga_recipes where id='editorial-draft'"), 0);
      await denied(() => pg.query("insert into public.miga_recipes(id,data) values ('unauthorized','{}')"));
      await denied(() => pg.query("update public.miga_recipes set status='published'"));
      await denied(() => pg.query('delete from public.miga_recipes'));
    });
  }
  await check('Server search preserves order, filters language/slot and pages without duplicates', async () => {
    const ids = catalog.map(r => r.id).reverse();
    const first = await value('select public.miga_search_recipes($1,$2,$3,$4,$5,$6) as value',[ids,'','en',null,0,6]);
    const second = await value('select public.miga_search_recipes($1,$2,$3,$4,$5,$6) as value',[ids,'','en',null,6,6]);
    assert.equal(first.total,54);
    assert.deepEqual(first.recipes.map(r => r.id),ids.slice(0,6));
    assert.deepEqual(second.recipes.map(r => r.id),ids.slice(6,12));
    const breakfast = await value('select public.miga_search_recipes($1,$2,$3,$4,$5,$6) as value',[ids,'','es','breakfast',0,100]);
    assert.equal(breakfast.total,18);
    const found = await value('select public.miga_search_recipes($1,$2,$3,$4,$5,$6) as value',[ids,'apple cinnamon','en',null,0,6]);
    assert.equal(found.total,1);
    const hidden = await value('select public.miga_search_recipes($1) as value',[['editorial-draft']]);
    assert.equal(hidden.total,0);
    await denied(() => pg.query("select public.miga_search_recipes($1,'','en',null,0,1000)",[ids]),'22023');
  });
  await pg.exec('reset role');
  await check('Invalid amounts/translations/identity cannot be published', async () => {
    for (const change of [r => r.amounts=[], r => r.amounts[0].amount=-1,
      r => r.amounts[0].ingredient='unsupported', r => r.es.steps=[], r => r.photo.path='../escape.jpg',
      r => r.nutrition.calories=null, r => r.slot=null, r => r.id=null]) {
      const bad = structuredClone(catalog[0]); change(bad);
      await denied(() => pg.query('update public.miga_recipes set data=$1 where id=$2',[JSON.stringify(bad),catalog[0].id]),'23514');
    }
    await denied(() => pg.query("insert into public.miga_recipes(id,data) values ('wrong-id',$1)",[JSON.stringify(catalog[0])]),'23514');
  });
  await check('Reimport preserves IDs and first-publication dates; drafts can be published', async () => {
    const first = await value('select published_at::text as value from public.miga_recipes where id=$1',[catalog[0].id]);
    await pg.query('update public.miga_recipes set data=$1 where id=$2',[JSON.stringify(catalog[0]),catalog[0].id]);
    assert.equal(await value('select published_at::text as value from public.miga_recipes where id=$1',[catalog[0].id]),first);
    await pg.exec("update public.miga_recipes set status='published' where id='editorial-draft'");
    assert.equal(await value("select published_at is not null as value from public.miga_recipes where id='editorial-draft'"),true);
  });
  console.log(`${checks} PostgreSQL migration and RLS checks passed`);
} finally { await pg.close(); }
