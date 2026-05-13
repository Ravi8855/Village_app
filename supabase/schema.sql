-- Naganoor Village App — Supabase schema, RLS, and seed data
-- Run in Supabase SQL Editor (Dashboard → SQL → New query)

-- ---------------------------------------------------------------------------
-- Extensions
-- ---------------------------------------------------------------------------
create extension if not exists "pgcrypto";

-- ---------------------------------------------------------------------------
-- Helper: updated_at trigger
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
-- Helper: admin role check (used by RLS)
-- ---------------------------------------------------------------------------
create or replace function public.is_admin()
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1
    from public.users u
    where u.id = auth.uid()
      and u.role = 'admin'
  );
$$;

-- ---------------------------------------------------------------------------
-- users (profile extension of auth.users)
-- ---------------------------------------------------------------------------
create table if not exists public.users (
  id uuid primary key references auth.users (id) on delete cascade,
  email text not null,
  full_name text,
  role text not null default 'user' check (role in ('admin', 'user')),
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now())
);

create trigger users_set_updated_at
before update on public.users
for each row execute function public.set_updated_at();

-- Auto-create profile on sign-up
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.users (id, email, full_name, role)
  values (
    new.id,
    new.email,
    coalesce(new.raw_user_meta_data ->> 'full_name', ''),
    coalesce(new.raw_user_meta_data ->> 'role', 'user')
  );
  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
after insert on auth.users
for each row execute function public.handle_new_user();

alter table public.users enable row level security;

create policy "Users can read own profile"
on public.users for select
to authenticated
using (auth.uid() = id);

create policy "Admins can read all profiles"
on public.users for select
to authenticated
using (public.is_admin());

create policy "Users can update own profile (not role)"
on public.users for update
to authenticated
using (auth.uid() = id)
with check (auth.uid() = id and role = (select role from public.users where id = auth.uid()));

create policy "Admins can update any profile"
on public.users for update
to authenticated
using (public.is_admin());

create policy "Users can insert own profile"
on public.users for insert
to authenticated
with check (auth.uid() = id);

-- Backfill profiles for auth users created before handle_new_user trigger
insert into public.users (id, email, full_name, role)
select
  au.id,
  coalesce(au.email, ''),
  coalesce(au.raw_user_meta_data ->> 'full_name', ''),
  'user'
from auth.users au
where not exists (
  select 1 from public.users pu where pu.id = au.id
);

-- ---------------------------------------------------------------------------
-- categories
-- ---------------------------------------------------------------------------
create table if not exists public.categories (
  id uuid primary key default gen_random_uuid(),
  name text not null unique,
  slug text not null unique,
  created_at timestamptz not null default timezone('utc', now())
);

alter table public.categories enable row level security;

create policy "Anyone can read categories"
on public.categories for select
to anon, authenticated
using (true);

create policy "Admins manage categories"
on public.categories for all
to authenticated
using (public.is_admin())
with check (public.is_admin());

insert into public.categories (name, slug) values
  ('Panchayat', 'panchayat'),
  ('Hospital', 'hospital'),
  ('Water Supply', 'waterSupply'),
  ('Farming', 'farming'),
  ('Electricity', 'electricity'),
  ('Education', 'education'),
  ('Emergency', 'emergency'),
  ('Temples', 'temples')
on conflict (slug) do nothing;

-- ---------------------------------------------------------------------------
-- announcements
-- ---------------------------------------------------------------------------
create table if not exists public.announcements (
  id uuid primary key default gen_random_uuid(),
  title text not null,
  description text not null,
  category text not null,
  image_url text,
  created_by uuid references public.users (id) on delete set null,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now()),
  is_active boolean not null default true
);

create index if not exists announcements_category_idx on public.announcements (category);
create index if not exists announcements_active_idx on public.announcements (is_active);
create index if not exists announcements_created_at_idx on public.announcements (created_at desc);

create trigger announcements_set_updated_at
before update on public.announcements
for each row execute function public.set_updated_at();

alter table public.announcements enable row level security;

create policy "Public read active announcements"
on public.announcements for select
to anon, authenticated
using (is_active = true);

create policy "Admins read all announcements"
on public.announcements for select
to authenticated
using (public.is_admin());

create policy "Admins insert announcements"
on public.announcements for insert
to authenticated
with check (public.is_admin());

create policy "Admins update announcements"
on public.announcements for update
to authenticated
using (public.is_admin())
with check (public.is_admin());

create policy "Admins delete announcements"
on public.announcements for delete
to authenticated
using (public.is_admin());

-- ---------------------------------------------------------------------------
-- panchayat_services (water, electricity, knowledge board)
-- ---------------------------------------------------------------------------
create table if not exists public.panchayat_services (
  id uuid primary key default gen_random_uuid(),
  section_type text not null check (
    section_type in ('water_supply', 'electricity', 'knowledge_board')
  ),
  title text not null,
  description text not null,
  image_url text,
  event_date date,
  status text not null default 'active' check (
    status in ('active', 'scheduled', 'completed', 'cancelled')
  ),
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now())
);

create trigger panchayat_services_set_updated_at
before update on public.panchayat_services
for each row execute function public.set_updated_at();

alter table public.panchayat_services enable row level security;

create policy "Public read panchayat services"
on public.panchayat_services for select
to anon, authenticated
using (true);

create policy "Admins manage panchayat services"
on public.panchayat_services for all
to authenticated
using (public.is_admin())
with check (public.is_admin());

-- ---------------------------------------------------------------------------
-- yojanas (Panchayat schemes)
-- ---------------------------------------------------------------------------
create table if not exists public.yojanas (
  id uuid primary key default gen_random_uuid(),
  title text not null,
  description text not null,
  image_url text,
  event_date date,
  status text not null default 'active' check (
    status in ('active', 'upcoming', 'completed', 'closed')
  ),
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now())
);

create trigger yojanas_set_updated_at
before update on public.yojanas
for each row execute function public.set_updated_at();

alter table public.yojanas enable row level security;

create policy "Public read yojanas"
on public.yojanas for select
to anon, authenticated
using (true);

create policy "Admins manage yojanas"
on public.yojanas for all
to authenticated
using (public.is_admin())
with check (public.is_admin());

-- ---------------------------------------------------------------------------
-- temples
-- ---------------------------------------------------------------------------
create table if not exists public.temples (
  id uuid primary key default gen_random_uuid(),
  temple_name text not null,
  description text not null,
  image_url text,
  location text not null,
  timings text,
  festivals text,
  latitude double precision not null,
  longitude double precision not null,
  created_at timestamptz not null default timezone('utc', now())
);

alter table public.temples enable row level security;

create policy "Public read temples"
on public.temples for select
to anon, authenticated
using (true);

create policy "Admins manage temples"
on public.temples for all
to authenticated
using (public.is_admin())
with check (public.is_admin());

-- ---------------------------------------------------------------------------
-- Seed: panchayat services
-- ---------------------------------------------------------------------------
insert into public.panchayat_services (section_type, title, description, status, event_date)
values
  (
    'water_supply',
    'Weekly tank cleaning',
    'Overhead tank cleaning every Tuesday 9am–1pm. Ward 2 may see low pressure.',
    'scheduled',
    current_date + 2
  ),
  (
    'electricity',
    'Feeder maintenance notice',
    '11kV feeder maintenance Thursday 10am–2pm. Charge inverters in advance.',
    'scheduled',
    current_date + 4
  ),
  (
    'knowledge_board',
    'Gram Sabha minutes',
    'Annual budget Gram Sabha minutes and action items are published here.',
    'active',
    current_date - 7
  )
on conflict do nothing;

-- ---------------------------------------------------------------------------
-- Seed: yojanas
-- ---------------------------------------------------------------------------
insert into public.yojanas (title, description, status, event_date)
values
  (
    'Haritha Haram tree plantation',
    'Village-wide sapling drive along tank bund and school grounds.',
    'active',
    current_date + 14
  ),
  (
    'PM-KISAN awareness camp',
    'Enrollment help desk at Panchayat office for eligible farmers.',
    'upcoming',
    current_date + 10
  )
on conflict do nothing;

-- ---------------------------------------------------------------------------
-- Seed: temples
-- ---------------------------------------------------------------------------
insert into public.temples (
  temple_name, description, location, timings, festivals, latitude, longitude
) values
  (
    'Sharanabasveswara Temple',
    'Historic Shiva temple at the heart of Naganoor village.',
    'Main temple street, Naganoor',
    '6:00 AM – 8:00 PM',
    'Maha Shivaratri, Karthika Masam',
    17.3850, 78.4867
  ),
  (
    'Shoguruveswara Temple',
    'Community temple known for morning abhishekam and local gatherings.',
    'Shoguruveswara Gudi, Naganoor',
    '5:30 AM – 7:30 PM',
    'Ugadi, Sankranti',
    17.3862, 78.4875
  ),
  (
    'Karappa Mutta Temple',
    'Sacred mutta with annual jatara and village processions.',
    'Karappa Mutta, Naganoor outskirts',
    '6:00 AM – 7:00 PM',
    'Karappa Jatara',
    17.3840, 78.4890
  ),
  (
    'Kenchamma Devi Temple',
    'Grama devata shrine visited during harvest season.',
    'Kenchamma Gudi, Ward 3',
    '6:00 AM – 8:30 PM',
    'Bonalu, Ashada Masam',
    17.3875, 78.4855
  ),
  (
    'Dyvamma Devi Temple',
    'Village deity temple with evening aarti and festival lamps.',
    'Dyvamma Gudi, Naganoor',
    '6:00 AM – 8:00 PM',
    'Dussehra, Deepavali',
    17.3835, 78.4848
  ),
  (
    'Marayamma Devi Temple',
    'Protector goddess temple near the village tank bund.',
    'Marayamma Gudi, tank bund road',
    '5:45 AM – 7:45 PM',
    'Bonalu, village fair',
    17.3880, 78.4882
  )
on conflict do nothing;

-- ---------------------------------------------------------------------------
-- Promote first admin (run after creating auth user in Dashboard)
-- ---------------------------------------------------------------------------
-- update public.users set role = 'admin' where email = 'admin@naganoor.village';
