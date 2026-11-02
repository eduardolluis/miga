begin;

-- Repair a bucket created as private before the recipe catalog migration.
-- Published recipe photography is public content and cannot require a login.
do $$ begin
  if to_regclass('storage.buckets') is not null then
    insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
      values ('recipe-photos', 'recipe-photos', true, 8388608,
        array['image/jpeg', 'image/webp', 'image/png'])
      on conflict (id) do update set
        public = excluded.public,
        file_size_limit = excluded.file_size_limit,
        allowed_mime_types = excluded.allowed_mime_types;
    if not exists (
      select 1 from pg_policies
      where schemaname = 'storage' and tablename = 'objects'
        and policyname = 'recipe_photos_read'
    ) then
      execute 'create policy recipe_photos_read on storage.objects for select to anon, authenticated using (bucket_id = ''recipe-photos'')';
    end if;
  end if;
end $$;

commit;
