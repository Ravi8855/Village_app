-- Village management RBAC: OTP staff roles, department updates, login activity
-- Safe to run on existing Naganoor schema (extends public.users, keeps legacy admin/user)
-- Compatible with public.users.role as TEXT (schema.sql) or ENUM (uses ::text casts)

-- ---------------------------------------------------------------------------
-- Extensions
-- ---------------------------------------------------------------------------
create extension if not exists "pgcrypto";

-- ---------------------------------------------------------------------------
-- Helper: updated_at trigger (idempotent)
-- ---------------------------------------------------------------------------
create or replace function public.set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = timezone('utc', now());
  return new;
end;
$$;

-- ---------------------------------------------------------------------------
-- Phone normalization
-- ---------------------------------------------------------------------------
create or replace function public.normalize_mobile(p text)
returns text
language sql
immutable
as $$
  select regexp_replace(coalesce(p, ''), '[^0-9]', '', 'g');
$$;

-- Super admin (India 10-digit, no country code in storage)
create or replace function public.is_super_admin_mobile(p text)
returns boolean
language sql
immutable
as $$
  select public.normalize_mobile(p) = '8855025560';
$$;

-- Department admin roles (explicit list — avoids ENUM + LIKE issues)
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
-- Extend users table (legacy email admin unchanged)
-- ---------------------------------------------------------------------------
alter table public.users
  add column if not exists mobile_number text,
  add column if not exists department text,
  add column if not exists is_approved boolean not null default true,
  add column if not exists is_active boolean not null default true,
  add column if not exists created_by uuid references public.users (id) on delete set null,
  add column if not exists last_login timestamptz;

create unique index if not exists users_mobile_number_unique_idx
  on public.users (mobile_number)
  where mobile_number is not null;

-- Role validation: TEXT CHECK works for text columns; safe if column is already enum
alter table public.users drop constraint if exists users_role_check;
alter table public.users add constraint users_role_check check (
  role::text in (
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

-- ---------------------------------------------------------------------------
-- Pending department admins (provisioned before first OTP login)
-- ---------------------------------------------------------------------------
create table if not exists public.admin_invites (
  id uuid primary key default gen_random_uuid(),
  mobile_number text not null,
  full_name text not null,
  role text not null check (
    role in (
      'water_admin',
      'hospital_admin',
      'panchayat_admin',
      'temple_admin',
      'annabhagya_admin',
      'bank_admin',
      'postoffice_admin',
      'electricity_admin'
    )
  ),
  department text not null,
  is_approved boolean not null default false,
  is_active boolean not null default true,
  created_by uuid references public.users (id) on delete set null,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now())
);

create unique index if not exists admin_invites_mobile_unique_idx
  on public.admin_invites (public.normalize_mobile(mobile_number));

drop trigger if exists admin_invites_set_updated_at on public.admin_invites;
create trigger admin_invites_set_updated_at
before update on public.admin_invites
for each row execute function public.set_updated_at();

create or replace function public.sync_invite_approval_to_users()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if new.is_approved is distinct from old.is_approved and new.is_approved = true then
    update public.users u
    set is_approved = true, updated_at = timezone('utc', now())
    where public.normalize_mobile(u.mobile_number) =
          public.normalize_mobile(new.mobile_number);
  end if;
  return new;
end;
$$;

drop trigger if exists admin_invites_sync_approval on public.admin_invites;
create trigger admin_invites_sync_approval
after update on public.admin_invites
for each row execute function public.sync_invite_approval_to_users();

-- ---------------------------------------------------------------------------
-- department_updates
-- ---------------------------------------------------------------------------
create table if not exists public.department_updates (
  id uuid primary key default gen_random_uuid(),
  department text not null check (
    department in (
      'water_supply',
      'hospital',
      'panchayat',
      'temples',
      'annabhagya',
      'bank',
      'post_office',
      'electricity'
    )
  ),
  title text not null,
  description text not null,
  image_url text,
  created_by uuid references public.users (id) on delete set null,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now())
);

create index if not exists department_updates_department_idx
  on public.department_updates (department, created_at desc);

drop trigger if exists department_updates_set_updated_at on public.department_updates;
create trigger department_updates_set_updated_at
before update on public.department_updates
for each row execute function public.set_updated_at();

-- ---------------------------------------------------------------------------
-- login_activity
-- ---------------------------------------------------------------------------
create table if not exists public.login_activity (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.users (id) on delete cascade,
  login_time timestamptz not null default timezone('utc', now()),
  device_info text
);

create index if not exists login_activity_user_idx
  on public.login_activity (user_id, login_time desc);

-- ---------------------------------------------------------------------------
-- Role helpers (security definer) — all ENUM-safe via ::text casts
-- ---------------------------------------------------------------------------
create or replace function public.current_user_role()
returns text
language sql
stable
security definer
set search_path = public
as $$
  select u.role::text from public.users u where u.id = auth.uid();
$$;

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
      and u.role::text = 'super_admin'
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
    where u.id = auth.uid() and u.role::text = 'admin'
  );
$$;

-- Extend legacy is_admin() for announcements / panchayat / temples
create or replace function public.is_admin()
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select public.is_super_admin()
      or public.is_legacy_admin();
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
      and u.role::text = any (public.department_admin_roles())
      and u.is_active = true
      and u.is_approved = true
  );
$$;

create or replace function public.user_department()
returns text
language sql
stable
security definer
set search_path = public
as $$
  select u.department from public.users u where u.id = auth.uid();
$$;

create or replace function public.role_department(p_role text)
returns text
language sql
immutable
as $$
  select case p_role
    when 'water_admin' then 'water_supply'
    when 'hospital_admin' then 'hospital'
    when 'panchayat_admin' then 'panchayat'
    when 'temple_admin' then 'temples'
    when 'annabhagya_admin' then 'annabhagya'
    when 'bank_admin' then 'bank'
    when 'postoffice_admin' then 'post_office'
    when 'electricity_admin' then 'electricity'
    else null
  end;
$$;

-- ---------------------------------------------------------------------------
-- Auth trigger: profile + super admin + invite merge
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
  v_invite public.admin_invites%rowtype;
begin
  v_mobile := public.normalize_mobile(
    coalesce(new.phone, new.raw_user_meta_data ->> 'phone', '')
  );
  v_full_name := coalesce(new.raw_user_meta_data ->> 'full_name', '');

  if public.is_super_admin_mobile(v_mobile) then
    v_role := 'super_admin';
    v_department := null;
  else
    select * into v_invite
    from public.admin_invites ai
    where public.normalize_mobile(ai.mobile_number) = v_mobile
      and ai.is_active = true
    limit 1;

    if found then
      v_role := v_invite.role;
      v_department := v_invite.department;
      v_full_name := coalesce(nullif(v_full_name, ''), v_invite.full_name);
    end if;
  end if;

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
    new.id,
    coalesce(new.email, ''),
    v_full_name,
    v_role,
    case when v_mobile = '' then null else v_mobile end,
    v_department,
    case
      when v_role = 'super_admin' then true
      when v_role = 'user' then false
      else coalesce(v_invite.is_approved, false)
    end,
    case
      when v_role = 'super_admin' then true
      when v_role = 'user' then true
      else coalesce(v_invite.is_active, true)
    end
  )
  on conflict (id) do update set
    mobile_number = excluded.mobile_number,
    role = excluded.role,
    department = excluded.department,
    full_name = coalesce(nullif(excluded.full_name, ''), public.users.full_name),
    is_approved = excluded.is_approved,
    is_active = excluded.is_active,
    updated_at = timezone('utc', now());

  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
after insert on auth.users
for each row execute function public.handle_new_user();

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
    coalesce(new.phone, new.raw_user_meta_data ->> 'phone', '')
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
    where id = new.id;
  else
    update public.users
    set
      mobile_number = coalesce(v_mobile, mobile_number),
      last_login = timezone('utc', now()),
      updated_at = timezone('utc', now())
    where id = new.id;
  end if;

  return new;
end;
$$;

drop trigger if exists on_auth_user_login_sync on auth.users;
create trigger on_auth_user_login_sync
after update of last_sign_in_at on auth.users
for each row
when (old.last_sign_in_at is distinct from new.last_sign_in_at)
execute function public.sync_user_on_login();

-- ---------------------------------------------------------------------------
-- RLS: admin_invites (super admin only)
-- ---------------------------------------------------------------------------
alter table public.admin_invites enable row level security;

drop policy if exists "Super admin manage invites" on public.admin_invites;
create policy "Super admin manage invites"
on public.admin_invites for all
to authenticated
using (public.is_super_admin())
with check (public.is_super_admin());

-- ---------------------------------------------------------------------------
-- RLS: department_updates
-- ---------------------------------------------------------------------------
alter table public.department_updates enable row level security;

drop policy if exists "Public read department updates" on public.department_updates;
create policy "Public read department updates"
on public.department_updates for select
to anon, authenticated
using (true);

drop policy if exists "Super admin manage department updates" on public.department_updates;
create policy "Super admin manage department updates"
on public.department_updates for all
to authenticated
using (public.is_super_admin())
with check (public.is_super_admin());

drop policy if exists "Dept admin manage own department updates" on public.department_updates;
create policy "Dept admin manage own department updates"
on public.department_updates for all
to authenticated
using (
  public.is_department_admin()
  and department = public.user_department()
)
with check (
  public.is_department_admin()
  and department = public.user_department()
);

-- ---------------------------------------------------------------------------
-- RLS: login_activity
-- ---------------------------------------------------------------------------
alter table public.login_activity enable row level security;

drop policy if exists "Users insert own login activity" on public.login_activity;
create policy "Users insert own login activity"
on public.login_activity for insert
to authenticated
with check (auth.uid() = user_id);

drop policy if exists "Users read own login activity" on public.login_activity;
create policy "Users read own login activity"
on public.login_activity for select
to authenticated
using (auth.uid() = user_id);

drop policy if exists "Super admin read all login activity" on public.login_activity;
create policy "Super admin read all login activity"
on public.login_activity for select
to authenticated
using (public.is_super_admin());

-- ---------------------------------------------------------------------------
-- RLS: users (extend super admin policies)
-- ---------------------------------------------------------------------------
alter table public.users enable row level security;

drop policy if exists "Super admin read all profiles" on public.users;
create policy "Super admin read all profiles"
on public.users for select
to authenticated
using (public.is_super_admin());

drop policy if exists "Super admin manage profiles" on public.users;
create policy "Super admin manage profiles"
on public.users for all
to authenticated
using (public.is_super_admin())
with check (public.is_super_admin());

drop policy if exists "Dept admins read own profile" on public.users;
-- (existing "Users can read own profile" covers this)

-- ---------------------------------------------------------------------------
-- Storage bucket for department media
-- ---------------------------------------------------------------------------
insert into storage.buckets (id, name, public)
values ('department-media', 'department-media', true)
on conflict (id) do nothing;

drop policy if exists "Public read department media" on storage.objects;
create policy "Public read department media"
on storage.objects for select
to anon, authenticated
using (bucket_id = 'department-media');

drop policy if exists "Staff upload department media" on storage.objects;
create policy "Staff upload department media"
on storage.objects for insert
to authenticated
with check (
  bucket_id = 'department-media'
  and (public.is_super_admin() or public.is_department_admin())
);

drop policy if exists "Staff update department media" on storage.objects;
create policy "Staff update department media"
on storage.objects for update
to authenticated
using (
  bucket_id = 'department-media'
  and (public.is_super_admin() or public.is_department_admin())
);

drop policy if exists "Staff delete department media" on storage.objects;
create policy "Staff delete department media"
on storage.objects for delete
to authenticated
using (
  bucket_id = 'department-media'
  and (public.is_super_admin() or public.is_department_admin())
);
