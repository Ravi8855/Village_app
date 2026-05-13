-- Ensure authenticated users can read their own public.users row (required for admin role detection).
-- Run in Supabase SQL Editor if the Flutter app cannot load role after sign-in.

alter table public.users enable row level security;

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
