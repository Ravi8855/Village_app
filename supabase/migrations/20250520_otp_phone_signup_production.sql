-- =============================================================================
-- OTP phone signup: fix "Database error saving new user"
-- Run ONCE in Supabase SQL Editor (entire script). Idempotent.
--
-- Fixes:
--   • email NOT NULL / duplicate '' email for phone-only users
--   • role ENUM without super_admin / old CHECK constraints
--   • handle_new_user() email-auth assumptions (uses NEW.phone + synthetic email)
--   • RLS blocking supabase_auth_admin INSERT on public.users
--   • admin_invites RLS blocking invite lookup during signup
--   • Missing columns (full_name, mobile_number, etc.)
-- =============================================================================

create extension if not exists "pgcrypto";

-- -----------------------------------------------------------------------------
-- 1) Helpers
-- -----------------------------------------------------------------------------
create or replace function public.set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = timezone('utc', now());
  return new;
end;
$$;

create or replace function public.normalize_mobile(p text)
returns text
language sql
immutable
as $$
  with digits as (
    select regexp_replace(coalesce(p, ''), '[^0-9]', '', 'g') as d
  )
  select nullif(
    case
      when length(d) = 12 and left(d, 2) = '91' then substring(d from 3)
      when length(d) = 11 and left(d, 1) = '0' then substring(d from 2)
      else d
    end,
    ''
  )
  from digits;
$$;

create or replace function public.is_super_admin_mobile(p text)
returns boolean
language sql
immutable
as $$
  select public.normalize_mobile(p) = '8855025560';
$$;

create or replace function public.cast_user_role(p_role text)
returns text
language plpgsql
immutable
as $$
declare
  v text := coalesce(nullif(trim(p_role), ''), 'user');
begin
  if v not in (
    'user', 'admin', 'super_admin',
    'water_admin', 'hospital_admin', 'panchayat_admin', 'temple_admin',
    'annabhagya_admin', 'bank_admin', 'postoffice_admin', 'electricity_admin'
  ) then
    v := 'user';
  end if;
  return v;
end;
$$;

-- -----------------------------------------------------------------------------
-- 2) admin_invites (optional; trigger skips safely if missing)
-- -----------------------------------------------------------------------------
create table if not exists public.admin_invites (
  id uuid primary key default gen_random_uuid(),
  mobile_number text not null,
  full_name text not null,
  role text not null,
  department text not null,
  is_approved boolean not null default false,
  is_active boolean not null default true,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now())
);

-- -----------------------------------------------------------------------------
-- 3) public.users — phone-first schema (no email NOT NULL)
-- -----------------------------------------------------------------------------
create table if not exists public.users (
  id uuid primary key references auth.users (id) on delete cascade,
  email text,
  full_name text,
  role text not null default 'user',
  mobile_number text,
  department text,
  is_approved boolean not null default false,
  is_active boolean not null default true,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now())
);

do $$
begin
  if exists (
    select 1 from information_schema.columns
    where table_schema = 'public' and table_name = 'users' and column_name = 'name'
  ) and not exists (
    select 1 from information_schema.columns
    where table_schema = 'public' and table_name = 'users' and column_name = 'full_name'
  ) then
    alter table public.users rename column name to full_name;
  end if;
end $$;

alter table public.users add column if not exists email text;
alter table public.users add column if not exists full_name text;
alter table public.users add column if not exists role text;
alter table public.users add column if not exists mobile_number text;
alter table public.users add column if not exists department text;
alter table public.users add column if not exists is_approved boolean;
alter table public.users add column if not exists is_active boolean;
alter table public.users add column if not exists created_at timestamptz;
alter table public.users add column if not exists updated_at timestamptz;

update public.users set role = 'user' where role is null;
update public.users set is_approved = coalesce(is_approved, false);
update public.users set is_active = coalesce(is_active, true);
update public.users set created_at = coalesce(created_at, timezone('utc', now()));
update public.users set updated_at = coalesce(updated_at, timezone('utc', now()));

-- ENUM → TEXT (enum without super_admin breaks insert)
do $$
begin
  if exists (
    select 1 from information_schema.columns c
    where c.table_schema = 'public' and c.table_name = 'users'
      and c.column_name = 'role' and c.udt_name = 'app_role'
  ) then
    alter table public.users alter column role type text using role::text;
  end if;
end $$;

alter table public.users alter column role set default 'user';

-- email: nullable; synthetic per-user in trigger (never rely on NEW.email for phone OTP)
alter table public.users alter column email drop not null;

-- Drop role CHECK constraints that only allow admin/user
do $$
declare r record;
begin
  for r in
    select c.conname from pg_constraint c
    where c.conrelid = 'public.users'::regclass and c.contype = 'c'
      and pg_get_constraintdef(c.oid) ilike '%role%'
  loop
    execute format('alter table public.users drop constraint if exists %I', r.conname);
  end loop;
end $$;

alter table public.users drop constraint if exists users_role_check;
alter table public.users add constraint users_role_check check (
  role in (
    'user', 'admin', 'super_admin',
    'water_admin', 'hospital_admin', 'panchayat_admin', 'temple_admin',
    'annabhagya_admin', 'bank_admin', 'postoffice_admin', 'electricity_admin'
  )
);

-- Multiple phone users cannot share empty-string email
do $$
declare r record;
begin
  for r in
    select c.conname from pg_constraint c
    where c.conrelid = 'public.users'::regclass and c.contype = 'u'
      and pg_get_constraintdef(c.oid) ilike '%email%'
  loop
    execute format('alter table public.users drop constraint if exists %I', r.conname);
  end loop;
end $$;

drop index if exists public.users_email_key;
drop index if exists public.users_email_unique;

create unique index if not exists users_mobile_number_unique_idx
  on public.users (mobile_number)
  where mobile_number is not null;

drop trigger if exists users_set_updated_at on public.users;
create trigger users_set_updated_at
before update on public.users
for each row execute function public.set_updated_at();

-- -----------------------------------------------------------------------------
-- 4) handle_new_user — phone OTP only (NEW.phone), no auth.users type deps
-- -----------------------------------------------------------------------------
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  v_mobile text;
  v_role text := 'user';
  v_email text;
  v_full_name text := '';
  v_department text;
  v_approved boolean := false;
  v_active boolean := true;
begin
  -- Phone from auth.users (E.164 or metadata); never assume NEW.email is set
  v_mobile := public.normalize_mobile(
    coalesce(NEW.phone, NEW.raw_user_meta_data ->> 'phone', '')
  );

  v_full_name := coalesce(
    nullif(trim(NEW.raw_user_meta_data ->> 'full_name'), ''),
    ''
  );

  v_email := nullif(trim(coalesce(NEW.email, '')), '');
  if v_email is null then
    if v_mobile is not null and length(v_mobile) > 0 then
      v_email := v_mobile || '@phone.naganoor.local';
    else
      v_email := NEW.id::text || '@auth.naganoor.local';
    end if;
  end if;

  if public.is_super_admin_mobile(v_mobile) then
    v_role := 'super_admin';
    v_approved := true;
    v_active := true;
    v_department := null;
  else
    begin
      select
        ai.role,
        ai.department,
        coalesce(nullif(v_full_name, ''), ai.full_name),
        ai.is_approved,
        ai.is_active
      into
        v_role,
        v_department,
        v_full_name,
        v_approved,
        v_active
      from public.admin_invites ai
      where public.normalize_mobile(ai.mobile_number) = v_mobile
        and ai.is_active = true
      limit 1;

      if not found then
        v_role := 'user';
        v_approved := false;
        v_active := true;
      end if;
    exception
      when undefined_table then
        v_role := 'user';
        v_approved := false;
      when others then
        raise log 'handle_new_user invite lookup: %', sqlerrm;
        v_role := 'user';
        v_approved := false;
    end;
  end if;

  v_role := public.cast_user_role(v_role);

  insert into public.users as u (
    id,
    email,
    full_name,
    role,
    mobile_number,
    department,
    is_approved,
    is_active
  )
  values (
    NEW.id,
    v_email,
    nullif(v_full_name, ''),
    v_role,
    v_mobile,
    v_department,
    v_approved,
    v_active
  )
  on conflict (id) do update set
    email = excluded.email,
    full_name = coalesce(nullif(excluded.full_name, ''), u.full_name),
    role = excluded.role,
    mobile_number = excluded.mobile_number,
    department = excluded.department,
    is_approved = excluded.is_approved,
    is_active = excluded.is_active,
    updated_at = timezone('utc', now());

  return NEW;
exception
  when others then
    raise log 'handle_new_user FAILED uid=% phone=% email=%: %',
      NEW.id, NEW.phone, NEW.email, sqlerrm;
    raise exception 'handle_new_user failed [%]: %', SQLSTATE, SQLERRM;
end;
$$;

-- Owner must bypass RLS on hosted Supabase (supabase_auth_admin preferred)
do $$
begin
  alter function public.handle_new_user() owner to supabase_auth_admin;
exception
  when undefined_object then
    alter function public.handle_new_user() owner to postgres;
  when others then
    raise notice 'handle_new_user owner: %', sqlerrm;
end $$;

grant execute on function public.handle_new_user() to postgres, service_role;
do $$
begin
  grant execute on function public.handle_new_user() to supabase_auth_admin;
exception when others then null;
end $$;

-- Single trigger on auth.users (remove duplicates)
drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row
  execute function public.handle_new_user();

-- -----------------------------------------------------------------------------
-- 5) Grants + RLS (auth trigger must INSERT into public.users)
-- -----------------------------------------------------------------------------
grant usage on schema public to postgres, anon, authenticated, service_role;
do $$
begin
  grant usage on schema public to supabase_auth_admin;
exception when others then null;
end $$;

grant select, insert, update, delete on table public.users to postgres, service_role;
do $$
begin
  grant all on table public.users to supabase_auth_admin;
exception when others then null;
end $$;

grant select, insert, update on table public.users to authenticated;

alter table public.users enable row level security;

drop policy if exists "Auth admin insert users" on public.users;
create policy "Auth admin insert users"
  on public.users for insert
  to supabase_auth_admin
  with check (true);

drop policy if exists "Service role insert users" on public.users;
create policy "Service role insert users"
  on public.users for insert
  to service_role
  with check (true);

drop policy if exists "Postgres insert users" on public.users;
create policy "Postgres insert users"
  on public.users for insert
  to postgres
  with check (true);

drop policy if exists "Users can read own profile" on public.users;
create policy "Users can read own profile"
  on public.users for select
  to authenticated
  using (auth.uid() = id);

drop policy if exists "Users can insert own profile" on public.users;
create policy "Users can insert own profile"
  on public.users for insert
  to authenticated
  with check (auth.uid() = id);

-- Invite lookup during signup (before auth.uid() is meaningful for staff)
alter table public.admin_invites enable row level security;
drop policy if exists "Auth trigger read invites" on public.admin_invites;
create policy "Auth trigger read invites"
  on public.admin_invites for select
  to supabase_auth_admin
  using (true);

drop policy if exists "Service role read invites" on public.admin_invites;
create policy "Service role read invites"
  on public.admin_invites for select
  to service_role
  using (true);

-- -----------------------------------------------------------------------------
-- 6) Backfill (optional; safe)
-- -----------------------------------------------------------------------------
insert into public.users (
  id, email, full_name, role, mobile_number, is_approved, is_active
)
select
  au.id,
  coalesce(
    nullif(trim(au.email), ''),
    public.normalize_mobile(coalesce(au.phone, au.raw_user_meta_data ->> 'phone', ''))
      || '@phone.naganoor.local',
    au.id::text || '@auth.naganoor.local'
  ),
  coalesce(nullif(trim(au.raw_user_meta_data ->> 'full_name'), ''), ''),
  case
    when public.is_super_admin_mobile(
      coalesce(au.phone, au.raw_user_meta_data ->> 'phone', '')
    ) then 'super_admin'
    else 'user'
  end,
  public.normalize_mobile(coalesce(au.phone, au.raw_user_meta_data ->> 'phone', '')),
  public.is_super_admin_mobile(coalesce(au.phone, au.raw_user_meta_data ->> 'phone', '')),
  true
from auth.users au
where not exists (select 1 from public.users pu where pu.id = au.id)
on conflict (id) do nothing;

-- -----------------------------------------------------------------------------
-- 7) Verify (run manually after OTP test)
-- -----------------------------------------------------------------------------
-- select proname, proowner::regrole from pg_proc where proname = 'handle_new_user';
-- select column_name, is_nullable, data_type, udt_name
--   from information_schema.columns where table_schema = 'public' and table_name = 'users';
-- select id, email, mobile_number, role, is_approved from public.users
--   where mobile_number = '8855025560' order by created_at desc limit 3;
