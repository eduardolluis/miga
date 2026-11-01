import test from 'node:test';
import assert from 'node:assert/strict';
import { readFile, mkdtemp, writeFile, rm } from 'node:fs/promises';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import { validateCatalog, importCatalog, imageDimensions } from './import_recipes.mjs';
const file = new URL('../supabase/catalog/recipes.json', import.meta.url);
const photosDir = new URL('../assets/images/recipes/v2/', import.meta.url).pathname;
const original = JSON.parse(await readFile(file, 'utf8'));

test('All 54 original recipes and real photo dimensions pass a credential-free dry run', async () => {
  const result = await importCatalog({file,photosDir,env:{},request:()=>assert.fail('dry run made a request')});
  assert.deepEqual(result,{recipes:54,photos:54,status:'draft',applied:false});
});
test('Bad identities, quantities, unknown ingredients and missing translations fail validation', () => {
  for (const change of [c => c.recipes.push(c.recipes[0]), c => c.recipes[0].amounts[0].amount=0,
    c => c.recipes[0].amounts[0].ingredient='unknown', c => c.recipes[0].en.steps=[],
    c => c.recipes[0].photo.path='../escape.jpg', c => c.recipes[0].nutrition.calories=null]) {
    const catalog = structuredClone(original); change(catalog);
    assert.throws(()=>validateCatalog(catalog));
  }
});
test('Apply uploads immutable photo paths before one transactional catalog upsert', async () => {
  const requests=[];
  const request=async (url,options) => {requests.push({url,...options});return new Response(null,{status:201});};
  const env={SUPABASE_URL:'https://example.supabase.co',SUPABASE_SERVICE_ROLE_KEY:'test-operator-key'};
  const result=await importCatalog({file,photosDir,status:'published',apply:true,env,request});
  assert.equal(result.applied,true);
  assert.equal(requests.length,55);
  assert.ok(requests.slice(0,54).every(r=>/recipe-photos\/.+-[a-f0-9]{16}\.jpg$/.test(r.url)));
  const last=requests.at(-1);
  assert.match(last.url,/rest\/v1\/miga_recipes\?on_conflict=id$/);
  const rows=JSON.parse(last.body);
  assert.equal(rows.length,54);
  assert.ok(rows.every(r=>r.status==='published'));
  assert.equal(rows[0].id,original.recipes[0].id);
  assert.equal(rows[0].data.nutrition.estimated,true);
  assert.equal(last.headers.Prefer,'resolution=merge-duplicates,return=minimal');
  assert.equal(JSON.stringify(rows).includes('test-operator-key'),false);
});
test('Photo failures never write metadata; identical photos are safe to reimport', async () => {
  const env={SUPABASE_URL:'https://example.supabase.co',SUPABASE_SERVICE_ROLE_KEY:'test-key'};
  const calls=[];
  await assert.rejects(importCatalog({file,photosDir,apply:true,env,request:async url=>{
    calls.push(url);return new Response(null,{status:500});
  }}),/Photo upload failed/);
  assert.equal(calls.length,1);
  let written=false;
  await importCatalog({file,photosDir,apply:true,env,request:async url=>{
    if(url.includes('/rest/')){written=true;return new Response(null,{status:201});}
    return new Response(JSON.stringify({statusCode:'409',error:'Duplicate'}),{status:400});
  }});
  assert.equal(written,true);
});
test('Missing credentials and wrong photo metadata fail before any network request', async () => {
  await assert.rejects(importCatalog({file,photosDir,apply:true,env:{},request:()=>assert.fail()}),/operator environment/);
  const dir=await mkdtemp(join(tmpdir(),'miga-import-test-'));
  try {
    const catalog=structuredClone(original);catalog.recipes[0].photo.width++;
    const altered=join(dir,'recipes.json');await writeFile(altered,JSON.stringify(catalog));
    await assert.rejects(importCatalog({file:altered,photosDir}),/dimensions/);
  } finally {await rm(dir,{recursive:true,force:true});}
  assert.throws(()=>imageDimensions(Buffer.from('not an image')),/corrupt/);
});

test('Authenticated CLI import uses its session without reading or exporting credentials', async () => {
  const calls=[];
  const result=await importCatalog({file,photosDir,status:'published',apply:true,useCli:true,
    projectRef:'qythwojltifyhlkarzdh',env:{},request:()=>assert.fail('CLI must not extract keys'),
    runCommand:async(command,args)=>{
      calls.push({command,args});
      if(args[0]==='db'){
        const sql=await readFile(args.at(-1),'utf8');
        assert.match(sql,/begin;/);assert.match(sql,/on conflict\(id\)/);assert.match(sql,/commit;/);
        const encoded=sql.match(/decode\('([^']+)'/)[1];
        assert.equal(JSON.parse(Buffer.from(encoded,'base64').toString()).length,54);
      }
      return {stdout:'',stderr:''};
    }});
  assert.equal(result.applied,true);assert.equal(calls.length,55);
  assert.ok(calls.every(c=>c.command==='supabase'&&!c.args.includes('api-keys')));
  assert.equal(calls.at(-1).args[0],'db');
});
