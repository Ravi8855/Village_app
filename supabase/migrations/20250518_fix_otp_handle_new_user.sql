-- Fix OTP signup: "Database error saving new user"
-- Run in Supabase SQL Editor after 20250517_village_management_rbac.sql
-- Idempotent — safe to re-run

-- ---------------------------------------------------------------------------
-- 1) Extensions & helpers
-- ---------------------------------------------------------------------------
create extension if not exists "pgcrypto";

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
  select nullif(regexp_replace(coalesce(p, ''), '[^0-9]', '', 'g'), '');
$$;

create or replace function public.is_super_admin_mobile(p text)
returns boolean
language sql
immutable
as $$
  select public.normalize_mobile(p) = '8855025560';
$$;

create or replace function public.department_admin_roles()
returns text[]
language sql
immutable
as $$
  select array[
    'water_admin',
    'hospital_admin',
    'panchayat_admin',
    'temple_admin',
    'annabhagya_admin',
    'bank_admin',
    'postoffice_admin',
    'electricity_admin'
  ]::text[];
$$;

-- ---------------------------------------------------------------------------
-- 2) Optional app_role enum (create + extend only if you use ENUM)
-- ---------------------------------------------------------------------------
do $$
begin
  if not exists (
    select 1 from pg_type t
    join pg_namespace n on n.oid = t.typnamespace
    where n.nspname = 'public' and t.typname = 'app_role'
  ) then
    create type public.app_role as enum (
      'user',
      'admin',
      'super_admin',
      'water_admin',
      'hospital_admin',
      'panchayat_admin',
      'temple_admin',
      'annabhagya_admin',
      'bank_admin',
      'postoffice_admin',
      'electricity_admin'
    );
  end if;
end $$;

do $$
declare
  v text;
  vals text[] := array[
    'super_admin', 'water_admin', 'hospital_admin', 'panchayat_admin',
    'temple_admin', 'annabhagya_admin', 'bank_admin', 'postoffice_admin',
    'electricity_admin'
  ];
begin
  if exists (
    select 1 from pg_type t
    join pg_namespace n on n.oid = t.typnamespace
    where n.nspname = 'public' and t.typname = 'app_role'
  ) then
    foreach v in array vals
    loop
      begin
        execute format(
          'alter type public.app_role add value if not exists %L',
          v
        );
      exception
        when others then
          raise notice 'app_role value %: %', v, sqlerrm;
      end;
    end loop;
  end if;
end $$;

-- ---------------------------------------------------------------------------
-- 2b) admin_invites (if missing)
-- ---------------------------------------------------------------------------
create table if not exists public.admin_invites (
  id uuid primary key default gen_random_uuid(),
  mobile_number text not null,
  full_name text not null,
  role text not null check (
    role in (
      'water_admin', 'hospital_admin', 'panchayat_admin', 'temple_admin',
      'annabhagya_admin', 'bank_admin', 'postoffice_admin', 'electricity_admin'
    )
  ),
  department text not null,
  is_approved boolean not null default false,
  is_active boolean not null default true,
  created_by uuid references public.users (id) on delete set null,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now())
);

-- ---------------------------------------------------------------------------
-- 3) public.users: ensure table + ALL columns used by OTP trigger/backfill
-- ---------------------------------------------------------------------------
create table if not exists public.users (
  id uuid primary key references auth.users (id) on delete cascade,
  email text,
  full_name text,
  role text not null default 'user',
  mobile_number text,
  department text,
  is_approved boolean not null default true,
  is_active boolean not null default true,
  created_by uuid,
  last_login timestamptz,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now())
);

-- Legacy projects may use "name" instead of "full_name"
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
alter table public.users add column if not exists created_by uuid;
alter table public.users add column if not exists last_login timestamptz;
alter table public.users add column if not exists created_at timestamptz;
alter table public.users add column if not exists updated_at timestamptz;

-- Defaults for rows/columns added without NOT NULL
update public.users set is_approved = true where is_approved is null;
update public.users set is_active = true where is_active is null;
update public.users set role = 'user' where role is null;
update public.users set created_at = timezone('utc', now()) where created_at is null;
update public.users set updated_at = timezone('utc', now()) where updated_at is null;

alter table public.users alter column is_approved set default true;
alter table public.users alter column is_active set default true;
alter table public.users alter column role set default 'user';
alter table public.users alter column created_at set default timezone('utc', now());
alter table public.users alter column updated_at set default timezone('utc', now());

do $$
begin
  if exists (
    select 1 from information_schema.columns
    where table_schema = 'public' and table_name = 'users' and column_name = 'email'
  ) then
    alter table public.users alter column email drop not null;
    alter table public.users alter column email set default '';
  end if;
exception
  when others then
    raise notice 'email column normalize skipped: %', sqlerrm;
end $$;

drop trigger if exists users_set_updated_at on public.users;
create trigger users_set_updated_at
before update on public.users
for each row execute function public.set_updated_at();

-- Normalize role column to TEXT (works with existing enum data)
do $$
begin
  if exists (
    select 1
    from information_schema.columns
    where table_schema = 'public'
      and table_name = 'users'
      and column_name = 'role'
      and udt_name = 'app_role'
  ) then
    alter table public.users
      alter column role type text using role::text;
  end if;
exception
  when others then
    raise notice 'role column already text or conversion skipped: %', sqlerrm;
end $$;

alter table public.users alter column role set default 'user';

-- Drop every CHECK constraint on role (old admin/user-only checks block super_admin)
do $$
declare
  r record;
begin
  for r in
    select c.conname
    from pg_constraint c
    where c.conrelid = 'public.users'::regclass
      and c.contype = 'c'
      and pg_get_constraintdef(c.oid) ilike '%role%'
  loop
    execute format('alter table public.users drop constraint if exists %I', r.conname);
  end loop;
end $$;

alter table public.users drop constraint if exists users_role_check;
alter table public.users add constraint users_role_check check (
  role in (
    'user',
    'admin',
    'super_admin',
    'water_admin',
    'hospital_admin',
    'panchayat_admin',
    'temple_admin',
    'annabhagya_admin',
    'bank_admin',
    'postoffice_admin',
    'electricity_admin'
  )
);

-- Unique empty emails break multiple phone signups — use partial unique or drop bad unique
do $$
declare
  r record;
begin
  for r in
    select c.conname
    from pg_constraint c
    where c.conrelid = 'public.users'::regclass
      and c.contype = 'u'
      and pg_get_constraintdef(c.oid) ilike '%email%'
  loop
    execute format('alter table public.users drop constraint if exists %I', r.conname);
  end loop;
end $$;

create unique index if not exists users_mobile_number_unique_idx
  on public.users (mobile_number)
  where mobile_number is not null;

-- ---------------------------------------------------------------------------
-- 4) Cast helper: TEXT role column (no unsafe LIKE on enum)
-- ---------------------------------------------------------------------------
create or replace function public.cast_user_role(p_role text)
returns text
language plpgsql
immutable
as $$
declare
  v_role text := coalesce(nullif(trim(p_role), ''), 'user');
begin
  if v_role not in (
    'user', 'admin', 'super_admin',
    'water_admin', 'hospital_admin', 'panchayat_admin', 'temple_admin',
    'annabhagya_admin', 'bank_admin', 'postoffice_admin', 'electricity_admin'
  ) then
    v_role := 'user';
  end if;
  return v_role;
end;
$$;

-- Synthetic email for phone-only auth.users (NOT NULL-safe, unique per auth id)
create or replace function public.auth_user_email(p_auth_user auth.users)
returns text
language plpgsql
stable
as $$
declare
  v_email text := nullif(trim(coalesce(p_auth_user.email, '')), '');
  v_mobile text;
begin
  if v_email is not null then
    return v_email;
  end if;

  v_mobile := public.normalize_mobile(
    coalesce(p_auth_user.phone, p_auth_user.raw_user_meta_data ->> 'phone', '')
  );

  if v_mobile is not null then
    return v_mobile || '@phone.naganoor.local';
  end if;

  return p_auth_user.id::text || '@auth.naganoor.local';
end;
$$;

-- ---------------------------------------------------------------------------
-- 5) handle_new_user — OTP-safe, no uninitialized v_invite, exception logged
-- ---------------------------------------------------------------------------
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  v_mobile text;
  v_role text := 'user';
  v_department text;
  v_full_name text;
  v_email text;
  v_is_approved boolean := false;
  v_is_active boolean := true;
  v_invite_role text;
  v_invite_department text;
  v_invite_full_name text;
  v_invite_approved boolean;
  v_invite_active boolean;
  v_found_invite boolean := false;
begin
  v_mobile := public.normalize_mobile(
    coalesce(NEW.phone, NEW.raw_user_meta_data ->> 'phone', '')
  );
  v_full_name := coalesce(nullif(trim(NEW.raw_user_meta_data ->> 'full_name'), ''), '');
  v_email := public.auth_user_email(NEW);

  if public.is_super_admin_mobile(v_mobile) then
    v_role := 'super_admin';
    v_department := null;
    v_is_approved := true;
    v_is_active := true;
  else
    select
      ai.role,
      ai.department,
      ai.full_name,
      ai.is_approved,
      ai.is_active
    into
      v_invite_role,
      v_invite_department,
      v_invite_full_name,
      v_invite_approved,
      v_invite_active
    from public.admin_invites ai
    where public.normalize_mobile(ai.mobile_number) = v_mobile
      and ai.is_active = true
    limit 1;

    v_found_invite := found;

    if v_found_invite then
      v_role := v_invite_role;
      v_department := v_invite_department;
      v_full_name := coalesce(nullif(v_full_name, ''), v_invite_full_name);
      v_is_approved := coalesce(v_invite_approved, false);
      v_is_active := coalesce(v_invite_active, true);
    else
      -- OTP user without invite: profile row allowed; staff app blocks later
      v_role := 'user';
      v_is_approved := false;
      v_is_active := true;
    end if;
  end if;

  v_role := public.cast_user_role(v_role);

  insert into public.users (
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
    v_is_approved,
    v_is_active
  )
  on conflict (id) do update set
    email = excluded.email,
    mobile_number = excluded.mobile_number,
    role = excluded.role,
    department = excluded.department,
    full_name = coalesce(nullif(excluded.full_name, ''), public.users.full_name),
    is_approved = excluded.is_approved,
    is_active = excluded.is_active;

  return NEW;
exception
  when others then
    raise exception 'handle_new_user failed [%]: %', SQLSTATE, sqlerrm;
end;
$$;

-- Ensure definer can write despite RLS
alter function public.handle_new_user() owner to postgres;
grant execute on function public.handle_new_user() to postgres, service_role;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
after insert on auth.users
for each row
execute function public.handle_new_user();

-- ---------------------------------------------------------------------------
-- 6) sync_user_on_login — TEXT role, super admin mobile
-- ---------------------------------------------------------------------------
create or replace function public.sync_user_on_login()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  v_mobile text;
begin
  v_mobile := public.normalize_mobile(
    coalesce(NEW.phone, NEW.raw_user_meta_data ->> 'phone', '')
  );

  if public.is_super_admin_mobile(v_mobile) then
    update public.users
    set
      role = 'super_admin',
      mobile_number = v_mobile,
      is_approved = true,
      is_active = true,
      last_login = timezone('utc', now()),
      updated_at = timezone('utc', now())
    where id = NEW.id;
  else
    update public.users
    set
      mobile_number = coalesce(v_mobile, mobile_number),
      last_login = timezone('utc', now()),
      updated_at = timezone('utc', now())
    where id = NEW.id;
  end if;

  return NEW;
exception
  when others then
    raise log 'sync_user_on_login failed for %: %', NEW.id, sqlerrm;
    return NEW;
end;
$$;

alter function public.sync_user_on_login() owner to postgres;

drop trigger if exists on_auth_user_login_sync on auth.users;
create trigger on_auth_user_login_sync
after update of last_sign_in_at on auth.users
for each row
when (old.last_sign_in_at is distinct from new.last_sign_in_at)
execute function public.sync_user_on_login();

-- ---------------------------------------------------------------------------
-- 7) RLS: allow security-definer trigger insert (belt-and-suspenders)
-- ---------------------------------------------------------------------------
drop policy if exists "Trigger service insert users" on public.users;
create policy "Trigger service insert users"
on public.users
for insert
to service_role
with check (true);

-- ---------------------------------------------------------------------------
-- 8) Role helpers (TEXT role, explicit comparisons — no LIKE on enum)
-- ---------------------------------------------------------------------------
create or replace function public.is_super_admin()
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1 from public.users u
    where u.id = auth.uid()
      and u.role = 'super_admin'
      and u.is_active = true
      and u.is_approved = true
  );
$$;

create or replace function public.is_legacy_admin()
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1 from public.users u
    where u.id = auth.uid() and u.role = 'admin'
  );
$$;

create or replace function public.is_admin()
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select public.is_super_admin() or public.is_legacy_admin();
$$;

create or replace function public.is_department_admin()
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1 from public.users u
    where u.id = auth.uid()
      and u.role = any (public.department_admin_roles())
      and u.is_active = true
      and u.is_approved = true
  );
$$;

-- ---------------------------------------------------------------------------
-- 9) Backfill existing auth.users missing public.users rows
-- ---------------------------------------------------------------------------
insert into public.users (
  id, email, full_name, role, mobile_number, is_approved, is_active
)
select
  au.id,
  public.auth_user_email(au),
  coalesce(nullif(trim(au.raw_user_meta_data ->> 'full_name'), ''), ''),
  case
    when public.is_super_admin_mobile(
      coalesce(au.phone, au.raw_user_meta_data ->> 'phone', '')
    ) then 'super_admin'
    else 'user'
  end,
  public.normalize_mobile(coalesce(au.phone, au.raw_user_meta_data ->> 'phone', '')),
  case
    when public.is_super_admin_mobile(
      coalesce(au.phone, au.raw_user_meta_data ->> 'phone', '')
    ) then true
    else false
  end,
  true
from auth.users au
where not exists (
  select 1 from public.users pu where pu.id = au.id
)
on conflict (id) do nothing;
