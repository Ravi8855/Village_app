-- Run once in Supabase SQL Editor if admin login says "not an admin"
-- Replace the email below with your admin account.

-- 1) Ensure every auth user has a public.users profile
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

-- 2) Allow authenticated users to create their own profile row (Flutter upsert)
drop policy if exists "Users can insert own profile" on public.users;
create policy "Users can insert own profile"
on public.users for insert
to authenticated
with check (auth.uid() = id);

-- 3) Promote admin by email (case-insensitive)
update public.users
set role = 'admin', updated_at = timezone('utc', now())
where lower(trim(email)) = lower(trim('ravivtu12345@gmail.com'));

-- 4) Verify
select id, email, role from public.users
where lower(trim(email)) = lower(trim('ravivtu12345@gmail.com'));


