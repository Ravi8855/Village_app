-- OTP fix: "Database error saving new user" (Supabase Auth + handle_new_user)
-- Run entire script in SQL Editor. Idempotent.

-- =============================================================================
-- A) Ensure public.users has every column the trigger needs
-- =============================================================================
create table if not exists public.users (
  id uuid primary key references auth.users (id) on delete cascade,
  email text,
  full_name text,
  role text not null default 'user',
  mobile_number text,
  department text,
  is_approved boolean default true,
  is_active boolean default true,
  created_at timestamptz default timezone('utc', now()),
  updated_at timestamptz default timezone('utc', now())
);

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
update public.users set is_approved = coalesce(is_approved, true);
update public.users set is_active = coalesce(is_active, true);

-- Force TEXT role (enum without super_admin breaks OTP insert)
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

-- Drop ALL check constraints on role (old admin/user-only)
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

alter table public.users alter column email drop not null;

-- =============================================================================
-- B) Grants for Supabase Auth trigger role (critical on hosted Supabase)
-- =============================================================================
grant usage on schema public to postgres, anon, authenticated, service_role, supabase_auth_admin;
grant all on table public.users to postgres, service_role, supabase_auth_admin;
grant select, insert, update on table public.users to authenticated;

-- =============================================================================
-- C) Minimal, resilient handle_new_user (no updated_at in ON CONFLICT)
-- =============================================================================
create or replace function public.normalize_mobile(p text)
returns text language sql immutable as $$
  select nullif(regexp_replace(coalesce(p, ''), '[^0-9]', '', 'g'), '');
$$;

create or replace function public.is_super_admin_mobile(p text)
returns boolean language sql immutable as $$
  select public.normalize_mobile(p) = '8855025560';
$$;

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
  v_invite_found boolean := false;
begin
  v_mobile := public.normalize_mobile(coalesce(NEW.phone, NEW.raw_user_meta_data ->> 'phone', ''));
  v_full_name := coalesce(nullif(trim(NEW.raw_user_meta_data ->> 'full_name'), ''), '');

  v_email := nullif(trim(coalesce(NEW.email, '')), '');
  if v_email is null then
    if v_mobile is not null then
      v_email := v_mobile || '@phone.naganoor.local';
    else
      v_email := NEW.id::text || '@auth.naganoor.local';
    end if;
  end if;

  if public.is_super_admin_mobile(v_mobile) then
    v_role := 'super_admin';
    v_approved := true;
    v_active := true;
  elsif exists (
    select 1 from information_schema.tables
    where table_schema = 'public' and table_name = 'admin_invites'
  ) then
    select ai.role, ai.department, ai.full_name, ai.is_approved, ai.is_active
    into v_role, v_department, v_full_name, v_approved, v_active
    from public.admin_invites ai
    where public.normalize_mobile(ai.mobile_number) = v_mobile
      and ai.is_active = true
    limit 1;

    v_invite_found := found;
    if not v_invite_found then
      v_role := 'user';
      v_approved := false;
    end if;
  end if;

  insert into public.users (
    id, email, full_name, role, mobile_number, department, is_approved, is_active
  )
  values (
    NEW.id, v_email, nullif(v_full_name, ''), v_role, v_mobile, v_department, v_approved, v_active
  )
  on conflict (id) do update set
    email = excluded.email,
    full_name = coalesce(nullif(excluded.full_name, ''), public.users.full_name),
    role = excluded.role,
    mobile_number = excluded.mobile_number,
    department = excluded.department,
    is_approved = excluded.is_approved,
    is_active = excluded.is_active;

  return NEW;
exception
  when others then
    raise exception 'handle_new_user failed [%]: %', SQLSTATE, SQLERRM;
end;
$$;

do $$
begin
  alter function public.handle_new_user() owner to supabase_auth_admin;
exception
  when others then
    alter function public.handle_new_user() owner to postgres;
end $$;

grant execute on function public.handle_new_user() to service_role, postgres;
do $$
begin
  grant execute on function public.handle_new_user() to supabase_auth_admin;
exception when others then null;
end $$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row
  execute function public.handle_new_user();

-- RLS: allow auth system to insert profile rows
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

drop policy if exists "Users can read own profile" on public.users;
create policy "Users can read own profile"
  on public.users for select
  to authenticated
  using (auth.uid() = id);

-- =============================================================================
-- D) Diagnostic: run manually after OTP attempt
-- =============================================================================
-- select proname, proowner::regrole from pg_proc where proname = 'handle_new_user';
-- select * from public.users where mobile_number = '8855025560' or role = 'super_admin';
