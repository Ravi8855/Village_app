-- Run this in Supabase Dashboard → SQL Editor → Run
-- Creates village_app_users for email OTP signup (standalone, safe to re-run)

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

create table if not exists public.village_app_users (
  uid uuid primary key default gen_random_uuid(),
  first_name text not null default '',
  last_name text not null default '',
  mobile_number text not null default '',
  email text not null,
  gender text not null default '',
  role text not null default 'user' check (
    role in ('super_admin', 'dept_admin', 'user')
  ),
  department text,
  is_blocked boolean not null default false,
  is_approved boolean not null default true,
  signup_completed boolean not null default true,
  password_hash text,
  is_otp_verified boolean not null default false,
  temp_password_changed boolean not null default false,
  auth_type text not null default 'otp_user' check (
    auth_type in ('otp_user', 'dept_admin_password', 'super_admin_password')
  ),
  created_at timestamptz not null default timezone('utc', now()),
  last_login_at timestamptz,
  updated_at timestamptz not null default timezone('utc', now())
);

create unique index if not exists village_app_users_email_unique_idx
  on public.village_app_users (lower(trim(email)));

create index if not exists village_app_users_role_idx
  on public.village_app_users (role);

create index if not exists village_app_users_created_at_idx
  on public.village_app_users (created_at desc);

drop trigger if exists village_app_users_set_updated_at on public.village_app_users;
create trigger village_app_users_set_updated_at
before update on public.village_app_users
for each row execute function public.set_updated_at();

alter table public.village_app_users enable row level security;

drop policy if exists "Village app users read" on public.village_app_users;
create policy "Village app users read"
on public.village_app_users for select
to anon, authenticated
using (true);

drop policy if exists "Village app users insert" on public.village_app_users;
create policy "Village app users insert"
on public.village_app_users for insert
to anon, authenticated
with check (true);

drop policy if exists "Village app users update" on public.village_app_users;
create policy "Village app users update"
on public.village_app_users for update
to anon, authenticated
using (true)
with check (true);

drop policy if exists "Village app users delete" on public.village_app_users;
create policy "Village app users delete"
on public.village_app_users for delete
to anon, authenticated
using (true);

do $$
begin
  if exists (select 1 from pg_publication where pubname = 'supabase_realtime') then
    begin
      alter publication supabase_realtime add table public.village_app_users;
    exception
      when duplicate_object then
        null;
    end;
  end if;
end;
$$;

-- Reload PostgREST schema cache so the app sees the new table immediately
notify pgrst, 'reload schema';
