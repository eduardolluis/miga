begin;

-- Content is administered by trusted tooling with the service role. Public app
-- clients can only read published recipes; no admin credential ships in Flutter.
create or replace function public.miga_recipe_content_valid(d jsonb)
returns boolean language plpgsql immutable set search_path = '' as $$
declare a jsonb; locale text; ingredient_ids text[] := '{}';
begin
  if jsonb_typeof(d) <> 'object' or octet_length(d::text) > 200000 then return false; end if;
  if not (d ?& array['id','slot','minutes','servings','sort_order','photo','amounts','es','en','source']) then return false; end if;
  if jsonb_typeof(d->'id') <> 'string' or jsonb_typeof(d->'slot') <> 'string' or d->>'id' !~ '^[a-z0-9]+(-[a-z0-9]+)*$' or length(d->>'id') > 100 or
    d->>'slot' not in ('breakfast','lunch','dinner') or
    jsonb_typeof(d->'minutes') <> 'number' or (d->>'minutes')::numeric not between 1 and 1440 or
    (d->>'minutes')::numeric <> trunc((d->>'minutes')::numeric) or
    jsonb_typeof(d->'servings') <> 'number' or (d->>'servings')::numeric not between 1 and 24 or
    (d->>'servings')::numeric <> trunc((d->>'servings')::numeric) or
    jsonb_typeof(d->'sort_order') <> 'number' or (d->>'sort_order')::numeric < 0 or
    (d->>'sort_order')::numeric <> trunc((d->>'sort_order')::numeric) or
    jsonb_typeof(d->'source') <> 'string' or length(trim(d->>'source')) = 0 then return false; end if;
  if jsonb_typeof(d->'photo') <> 'object' or
    not ((d->'photo') ?& array['path','width','height']) or
    d->'photo'->>'path' !~ '^[a-zA-Z0-9_/-]+[.](jpg|jpeg|webp|png)$' or
    position('..' in d->'photo'->>'path') > 0 or
    left(d->'photo'->>'path', 1) = '/' or
    jsonb_typeof(d->'photo'->'width') <> 'number' or jsonb_typeof(d->'photo'->'height') <> 'number' or
    (d->'photo'->>'width')::int not between 1 and 10000 or
    (d->'photo'->>'height')::int not between 1 and 10000 then return false; end if;
  if jsonb_typeof(d->'amounts') <> 'array' or jsonb_array_length(d->'amounts') not between 1 and 100 then return false; end if;
  for a in select value from jsonb_array_elements(d->'amounts') loop
    if not (a ?& array['ingredient','amount','unit']) or
      jsonb_typeof(a->'ingredient') <> 'string' or
      a->>'ingredient' = any(ingredient_ids) or
      a->>'ingredient' not in ('oats','milk','banana','walnuts','cinnamon','bread','avocado','eggs','tomatoes','oliveOil','salt','pepper','yogurt','mango','strawberries','granola','salmon','potatoes','broccoli','lemon','herbs','chicken','rice','carrot','garlic','chickpeas','cucumber','onion','pasta','basil','cheese','sweetPotato','spinach','lentils','celery','vegetableStock','apple','peanutButter','tortilla','blackBeans','tuna','groundBeef','bellPepper','mushrooms','zucchini','pineapple','tofu','quinoa') or
      a->>'unit' not in ('grams','milliliters','pieces') or
      jsonb_typeof(a->'amount') <> 'number' or (a->>'amount')::numeric not between 0.000001 and 1000000 or
      (a ? 'grams_per_piece' and (jsonb_typeof(a->'grams_per_piece') <> 'number' or (a->>'grams_per_piece')::numeric <= 0)) then return false; end if;
    ingredient_ids := array_append(ingredient_ids, a->>'ingredient');
  end loop;
  foreach locale in array array['es','en'] loop
    a := d->locale;
    if jsonb_typeof(a) <> 'object' or not (a ?& array['title','description','ingredients','steps']) or
      jsonb_typeof(a->'title') <> 'string' or length(trim(a->>'title')) = 0 or
      jsonb_typeof(a->'description') <> 'string' or length(trim(a->>'description')) = 0 or
      jsonb_typeof(a->'ingredients') <> 'array' or jsonb_array_length(a->'ingredients') = 0 or
      jsonb_typeof(a->'steps') <> 'array' or jsonb_array_length(a->'steps') = 0 then return false; end if;
    if exists(select 1 from jsonb_array_elements((a->'ingredients') || (a->'steps')) e
      where jsonb_typeof(e) <> 'string' or length(trim(e #>> '{}')) = 0) then return false; end if;
  end loop;
  if d ? 'nutrition' and d->'nutrition' <> 'null'::jsonb then
    a := d->'nutrition';
    if jsonb_typeof(a) <> 'object' or not (a ?& array['calories','protein_grams','carbs_grams','estimated']) or
      jsonb_typeof(a->'estimated') <> 'boolean' then return false; end if;
    if jsonb_typeof(a->'calories') <> 'number' or jsonb_typeof(a->'protein_grams') <> 'number' or jsonb_typeof(a->'carbs_grams') <> 'number' then return false; end if;
    foreach locale in array array['calories','protein_grams','carbs_grams','fat_grams'] loop
      if a ? locale and a->locale <> 'null'::jsonb and
        (jsonb_typeof(a->locale) <> 'number' or (a->>locale)::numeric < 0 or
          (a->>locale)::numeric <> trunc((a->>locale)::numeric)) then return false; end if;
    end loop;
  end if;
  if d ? 'tags' and (jsonb_typeof(d->'tags') <> 'array' or exists(
    select 1 from jsonb_array_elements(d->'tags') e where jsonb_typeof(e) <> 'string')) then return false; end if;
  return true;
exception when others then return false;
end $$;

create table public.miga_recipes (
  id text primary key,
  data jsonb not null,
  status text not null default 'draft' check (status in ('draft','review','published','archived')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  published_at timestamptz,
  constraint recipe_identity check (id = data->>'id'),
  constraint recipe_content check (public.miga_recipe_content_valid(data)),
  constraint published_recipe_date check (status <> 'published' or published_at is not null)
);
create index miga_recipes_published on public.miga_recipes ((data->>'slot'), ((data->>'sort_order')::int), id)
  where status = 'published';
alter table public.miga_recipes enable row level security;
create policy published_recipes_read on public.miga_recipes for select to anon, authenticated
  using (status = 'published');
revoke all on public.miga_recipes from anon, authenticated;
grant select on public.miga_recipes to anon, authenticated;
grant all on public.miga_recipes to service_role;

create or replace function public.miga_recipe_timestamp()
returns trigger language plpgsql set search_path = '' as $$
begin
  new.updated_at := now();
  if tg_op = 'UPDATE' then
    new.created_at := old.created_at;
    new.published_at := coalesce(old.published_at, new.published_at);
  end if;
  if new.status = 'published' and new.published_at is null then new.published_at := now(); end if;
  return new;
end $$;
create trigger miga_recipe_timestamp before insert or update on public.miga_recipes
  for each row execute function public.miga_recipe_timestamp();

-- Return a single JSON value to avoid PostgREST's row limit truncating the
-- downloaded offline catalog. This statement reads a consistent DB snapshot.
create or replace function public.miga_recipe_snapshot()
returns jsonb language sql stable security invoker set search_path = '' as $$
  select coalesce(jsonb_agg(data order by (data->>'sort_order')::int, id), '[]'::jsonb)
  from public.miga_recipes where status = 'published';
$$;

-- Eligibility/order includes local pantry, budget, portions and restrictions.
-- Text, language, meal-slot filtering and pagination execute on the server.
create or replace function public.miga_search_recipes(
  p_ids text[], p_query text default '', p_language text default 'es',
  p_slot text default null, p_offset int default 0, p_limit int default 6
) returns jsonb language plpgsql stable security invoker set search_path = '' as $$
declare result jsonb;
begin
  if p_limit not between 1 and 100 or p_offset < 0 or p_offset is null or p_limit is null or
    coalesce(cardinality(p_ids), 0) > 10000 or length(coalesce(p_query, '')) > 200 or
    p_language not in ('es','en') or p_language is null or
    (p_slot is not null and p_slot not in ('breakfast','lunch','dinner')) then
    raise exception 'Invalid recipe query' using errcode = '22023';
  end if;
  with filtered as (
    select id, data, array_position(p_ids, id) as position
    from public.miga_recipes where status = 'published' and id = any(p_ids)
      and (p_slot is null or data->>'slot' = p_slot)
      and strpos(lower(data->p_language->>'title'), lower(trim(coalesce(p_query, '')))) > 0
  ), page as (select data from filtered order by position, id limit p_limit offset p_offset)
  select jsonb_build_object('total', (select count(*) from filtered),
    'recipes', coalesce((select jsonb_agg(data) from page), '[]'::jsonb)) into result;
  return result;
end $$;
revoke all on function public.miga_recipe_snapshot() from public;
revoke all on function public.miga_search_recipes(text[],text,text,text,int,int) from public;
grant execute on function public.miga_recipe_snapshot() to anon, authenticated, service_role;
grant execute on function public.miga_search_recipes(text[],text,text,text,int,int) to anon, authenticated, service_role;

-- Storage is managed by Supabase; the guard also permits standalone SQL tests.
do $$ begin
  if to_regclass('storage.buckets') is not null then
    insert into storage.buckets(id, name, public, file_size_limit, allowed_mime_types)
      values ('recipe-photos', 'recipe-photos', true, 8388608,
        array['image/jpeg','image/webp','image/png']) on conflict(id) do nothing;
    execute 'create policy recipe_photos_read on storage.objects for select to anon, authenticated using (bucket_id = ''recipe-photos'')';
  end if;
end $$;
commit;
