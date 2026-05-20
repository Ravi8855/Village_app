-- Village app users (email OTP auth — not tied to auth.users)
-- Global user store for multi-browser / multi-session testing.

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

-- Email OTP app uses anon key without Supabase Auth session.
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

-- Realtime: super admin dashboard auto-refresh
do $$
begin
  if exists (
    select 1 from pg_publication_tables
    where pubname = 'supabase_realtime'
      and schemaname = 'public'
      and tablename = 'village_app_users'
  ) then
    null;
  elsif exists (select 1 from pg_publication where pubname = 'supabase_realtime') then
    alter publication supabase_realtime add table public.village_app_users;
  end if;
exception
  when others then
    raise notice 'Could not add village_app_users to supabase_realtime: %', sqlerrm;
end;
$$;

notify pgrst, 'reload schema';
