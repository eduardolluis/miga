begin;
create extension if not exists pgcrypto with schema extensions;

create table if not exists public.miga_documents (
  user_id uuid not null references auth.users(id) on delete cascade,
  kind text not null check (kind = 'state'),
  data jsonb not null check (jsonb_typeof(data) = 'object'),
  revision bigint not null default 1 check (revision > 0),
  updated_at timestamptz not null default now(),
  primary key (user_id, kind)
);
alter table public.miga_documents enable row level security;
create policy documents_owner_read on public.miga_documents for select to authenticated using (user_id = (select auth.uid()));
-- Writes go through the CAS function, so direct API calls cannot bypass revisions.
grant select on public.miga_documents to authenticated;
revoke insert, update, delete on public.miga_documents from anon, authenticated;

create or replace function public.miga_put_document(p_kind text, p_data jsonb, p_revision bigint)
returns bigint language plpgsql security definer set search_path = '' as $$
declare result bigint;
begin
  if auth.uid() is null then raise insufficient_privilege; end if;
  if p_kind <> 'state' or jsonb_typeof(p_data) <> 'object' or octet_length(p_data::text) > 2000000 then
    raise exception 'Invalid document' using errcode = '22023';
  end if;
  insert into public.miga_documents(user_id, kind, data, revision)
    values(auth.uid(), p_kind, p_data, 1)
  on conflict (user_id, kind) do update
    set data = excluded.data, revision = miga_documents.revision + 1, updated_at = now()
    where miga_documents.revision = p_revision
  returning revision into result;
  if result is null or (p_revision <> 0 and result = 1) then
    raise exception 'Document changed on another device' using errcode = '40001';
  end if;
  return result;
end $$;
revoke all on function public.miga_put_document(text, jsonb, bigint) from public, anon;
grant execute on function public.miga_put_document(text, jsonb, bigint) to authenticated;

create table public.miga_shared_lists (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid not null references auth.users(id) on delete cascade,
  data jsonb not null default '[]'::jsonb check (jsonb_typeof(data) = 'array'),
  revision bigint not null default 1,
  invitation_hash text not null unique,
  created_at timestamptz not null default now()
);
create table public.miga_list_members (
  list_id uuid not null references public.miga_shared_lists(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  primary key (list_id, user_id)
);
create index list_members_user on public.miga_list_members(user_id);
alter table public.miga_shared_lists enable row level security;
alter table public.miga_list_members enable row level security;
create policy list_member_self_read on public.miga_list_members for select to authenticated using (user_id = (select auth.uid()));
create policy list_member_read on public.miga_shared_lists for select to authenticated using (
  owner_id = (select auth.uid()) or exists (
    select 1 from public.miga_list_members where list_id = miga_shared_lists.id and user_id = (select auth.uid())
  )
);
grant select on public.miga_shared_lists to authenticated;
grant select on public.miga_list_members to authenticated;
revoke insert, update, delete on public.miga_shared_lists, public.miga_list_members from anon, authenticated;

create or replace function public.miga_create_list(p_data jsonb) returns jsonb
language plpgsql security definer set search_path = '' as $$
declare token text; list uuid;
begin
  if auth.uid() is null then raise insufficient_privilege; end if;
  if jsonb_typeof(p_data) <> 'array' or octet_length(p_data::text) > 2000000 then raise exception 'Invalid list'; end if;
  if not public.miga_can_share(auth.uid()) then raise insufficient_privilege; end if;
  token := encode(extensions.gen_random_bytes(32), 'hex');
  insert into public.miga_shared_lists(owner_id, data, invitation_hash)
    values(auth.uid(), p_data, encode(extensions.digest(token, 'sha256'), 'hex')) returning id into list;
  insert into public.miga_list_members values(list, auth.uid());
  return jsonb_build_object('id', list, 'invitation', token);
end $$;

create or replace function public.miga_join_list(p_code text) returns uuid
language plpgsql security definer set search_path = '' as $$
declare list uuid;
begin
  if auth.uid() is null then raise insufficient_privilege; end if;
  if p_code !~ '^[0-9a-f]{64}$' then raise exception 'Invalid invitation'; end if;
  select id into list from public.miga_shared_lists where invitation_hash = encode(extensions.digest(p_code, 'sha256'), 'hex');
  if list is null then raise exception 'Invalid invitation'; end if;
  if not public.miga_can_share((select owner_id from public.miga_shared_lists where id = list)) then raise insufficient_privilege; end if;
  insert into public.miga_list_members values(list, auth.uid()) on conflict do nothing;
  return list;
end $$;

create or replace function public.miga_update_list(p_id uuid, p_revision bigint, p_data jsonb) returns bigint
language plpgsql security definer set search_path = '' as $$
declare result bigint;
begin
  if auth.uid() is null or not exists(select 1 from public.miga_list_members where list_id = p_id and user_id = auth.uid()) then
    raise insufficient_privilege;
  end if;
  if not public.miga_can_share((select owner_id from public.miga_shared_lists where id = p_id)) then raise insufficient_privilege; end if;
  if jsonb_typeof(p_data) <> 'array' or octet_length(p_data::text) > 2000000 then raise exception 'Invalid list'; end if;
  update public.miga_shared_lists set data = p_data, revision = revision + 1
    where id = p_id and revision = p_revision returning revision into result;
  if result is null then raise exception 'Shared list changed' using errcode = '40001'; end if;
  return result;
end $$;

create or replace function public.miga_leave_list(p_id uuid) returns void
language plpgsql security definer set search_path = '' as $$
begin
  if auth.uid() is null then raise insufficient_privilege; end if;
  if exists(select 1 from public.miga_shared_lists where id = p_id and owner_id = auth.uid()) then
    delete from public.miga_shared_lists where id = p_id;
  else
    delete from public.miga_list_members where list_id = p_id and user_id = auth.uid();
  end if;
end $$;
revoke all on function public.miga_create_list(jsonb), public.miga_join_list(text), public.miga_update_list(uuid, bigint, jsonb), public.miga_leave_list(uuid) from public, anon;
grant execute on function public.miga_create_list(jsonb), public.miga_join_list(text), public.miga_update_list(uuid, bigint, jsonb), public.miga_leave_list(uuid) to authenticated;

-- Only the server-side store verification function can grant subscriptions.
create table public.miga_entitlements (
  user_id uuid primary key references auth.users(id) on delete cascade,
  store text not null check (store in ('apple', 'google')),
  product_id text not null,
  transaction_id text not null unique,
  expires_at timestamptz not null,
  checked_at timestamptz not null default now()
);
alter table public.miga_entitlements enable row level security;
create policy entitlement_owner_read on public.miga_entitlements for select to authenticated using (user_id = (select auth.uid()));
grant select on public.miga_entitlements to authenticated;
revoke insert, update, delete on public.miga_entitlements from anon, authenticated;

create table public.miga_configuration (
  id boolean primary key default true check (id),
  pro_required boolean not null default false
);
insert into public.miga_configuration(id, pro_required) values (true, false);
alter table public.miga_configuration enable row level security;
revoke all on public.miga_configuration from public, anon, authenticated;

create or replace function public.miga_can_share(p_user uuid) returns boolean
language sql stable security definer set search_path = '' as $$
  select not (select pro_required from public.miga_configuration where id)
    or exists(select 1 from public.miga_entitlements where user_id = p_user and expires_at > now());
$$;
revoke all on function public.miga_can_share(uuid) from public, anon, authenticated;

alter publication supabase_realtime add table public.miga_shared_lists;

create table public.miga_purchase_sources (
  user_id uuid primary key references auth.users(id) on delete cascade,
  store text not null check (store in ('apple', 'google')),
  source_token text not null,
  checked_at timestamptz not null default now()
);
alter table public.miga_purchase_sources enable row level security;
revoke all on public.miga_purchase_sources from public, anon, authenticated;

create or replace function public.miga_record_subscription(
  p_user_id uuid, p_store text, p_product text, p_transaction text, p_source_token text, p_expires timestamptz
) returns void language plpgsql security definer set search_path = '' as $$
begin
  insert into public.miga_entitlements(user_id, store, product_id, transaction_id, expires_at)
    values(p_user_id, p_store, p_product, p_transaction, p_expires)
    on conflict (user_id) do update set store = excluded.store, product_id = excluded.product_id,
      transaction_id = excluded.transaction_id, expires_at = excluded.expires_at, checked_at = now();
  insert into public.miga_purchase_sources(user_id, store, source_token)
    values(p_user_id, p_store, p_source_token)
    on conflict (user_id) do update set store = excluded.store, source_token = excluded.source_token, checked_at = now();
end $$;
revoke all on function public.miga_record_subscription(uuid,text,text,text,text,timestamptz) from public, anon, authenticated;
grant execute on function public.miga_record_subscription(uuid,text,text,text,text,timestamptz) to service_role;
grant all on public.miga_documents, public.miga_shared_lists, public.miga_list_members,
  public.miga_entitlements, public.miga_purchase_sources, public.miga_configuration to service_role;

commit;
