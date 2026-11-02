-- Allow editorial draft/review rows without a photograph. Published recipes
-- still require the exact same complete validation as before.
-- Does not add a placeholder image or modify any of the 54 published recipes.
begin;

create or replace function public.miga_recipe_content_valid_for_status(d jsonb, recipe_status text)
returns boolean
language sql immutable set search_path = '' as $$
  select case
    when recipe_status in ('draft', 'review')
      and jsonb_typeof(d->'photo') = 'null'
      and d ? 'photo'
    then public.miga_recipe_content_valid(
      jsonb_set(d, '{photo}',
        '{"path":"pending-validation-only.webp","width":1,"height":1}'::jsonb)
    )
    else public.miga_recipe_content_valid(d)
  end;
$$;

alter table public.miga_recipes drop constraint if exists recipe_content;
alter table public.miga_recipes
  add constraint recipe_content
  check (public.miga_recipe_content_valid_for_status(data, status));

commit;
