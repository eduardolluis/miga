-- Miga: three free "Surprise me" uses per authenticated account.
-- The client cannot reset or modify the counter directly.
create table if not exists public.miga_surprise_uses (
  user_id uuid primary key references auth.users(id) on delete cascade,
  used integer not null default 0 check (used between 0 and 3),
  updated_at timestamptz not null default now()
);
alter table public.miga_surprise_uses enable row level security;
revoke all on public.miga_surprise_uses from public, anon, authenticated;
grant all on public.miga_surprise_uses to service_role;

create or replace function public.miga_surprise_remaining()
returns jsonb
language plpgsql security definer set search_path = '' as $$
declare
  v_user uuid := auth.uid();
  v_used integer;
  v_pro boolean;
begin
  if v_user is null then raise insufficient_privilege; end if;
  select exists (
    select 1 from public.miga_entitlements
    where user_id = v_user and expires_at > now()
  ) into v_pro;
  if v_pro then
    return jsonb_build_object('allowed', true, 'pro', true, 'remaining', 3);
  end if;
  select used into v_used from public.miga_surprise_uses where user_id = v_user;
  return jsonb_build_object('allowed', coalesce(v_used, 0) < 3,
    'pro', false, 'remaining', greatest(0, 3 - coalesce(v_used, 0)));
end;
$$;

create or replace function public.miga_consume_surprise()
returns jsonb
language plpgsql security definer set search_path = '' as $$
declare
  v_user uuid := auth.uid();
  v_used integer;
  v_pro boolean;
begin
  if v_user is null then raise insufficient_privilege; end if;
  select exists (
    select 1 from public.miga_entitlements
    where user_id = v_user and expires_at > now()
  ) into v_pro;
  if v_pro then
    return jsonb_build_object('allowed', true, 'pro', true, 'remaining', 3);
  end if;
  -- The ON CONFLICT clause locks the per-account row so concurrent taps
  -- cannot use the same free credit twice.
  insert into public.miga_surprise_uses(user_id, used)
    values (v_user, 1)
  on conflict (user_id) do update
    set used = public.miga_surprise_uses.used + 1, updated_at = now()
    where public.miga_surprise_uses.used < 3
  returning used into v_used;
  if v_used is null then
    return jsonb_build_object('allowed', false, 'pro', false, 'remaining', 0);
  end if;
  return jsonb_build_object('allowed', true, 'pro', false, 'remaining', 3 - v_used);
end;
$$;

revoke all on function public.miga_surprise_remaining(), public.miga_consume_surprise()
  from public, anon;
grant execute on function public.miga_surprise_remaining(), public.miga_consume_surprise()
  to authenticated;
