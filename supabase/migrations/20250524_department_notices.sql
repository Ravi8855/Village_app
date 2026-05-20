-- Department notices (water supply, etc.) — works with email OTP app (anon key)

create table if not exists public.department_notices (
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
  created_by text,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now())
);

create index if not exists department_notices_department_idx
  on public.department_notices (department, created_at desc);

drop trigger if exists department_notices_set_updated_at on public.department_notices;
create trigger department_notices_set_updated_at
before update on public.department_notices
for each row execute function public.set_updated_at();

alter table public.department_notices enable row level security;

drop policy if exists "Department notices read" on public.department_notices;
create policy "Department notices read"
on public.department_notices for select
to anon, authenticated
using (true);

drop policy if exists "Department notices insert" on public.department_notices;
create policy "Department notices insert"
on public.department_notices for insert
to anon, authenticated
with check (true);

drop policy if exists "Department notices update" on public.department_notices;
create policy "Department notices update"
on public.department_notices for update
to anon, authenticated
using (true)
with check (true);

drop policy if exists "Department notices delete" on public.department_notices;
create policy "Department notices delete"
on public.department_notices for delete
to anon, authenticated
using (true);

do $$
begin
  if exists (select 1 from pg_publication where pubname = 'supabase_realtime') then
    begin
      alter publication supabase_realtime add table public.department_notices;
    exception
      when duplicate_object then null;
    end;
  end if;
end;
$$;

-- Fix legacy department_updates RLS for anon admin app
drop policy if exists "Anon manage department updates" on public.department_updates;
create policy "Anon manage department updates"
on public.department_updates for insert
to anon, authenticated
with check (true);

drop policy if exists "Anon update department updates" on public.department_updates;
create policy "Anon update department updates"
on public.department_updates for update
to anon, authenticated
using (true)
with check (true);

drop policy if exists "Anon delete department updates" on public.department_updates;
create policy "Anon delete department updates"
on public.department_updates for delete
to anon, authenticated
using (true);

notify pgrst, 'reload schema';
