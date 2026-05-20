-- Fix super_admin detection: Supabase stores phone as 918855025560 (not 8855025560)
-- Idempotent — run in SQL Editor after 20250520_otp_phone_signup_production.sql

-- -----------------------------------------------------------------------------
-- normalize_mobile: strip India country code 91 → 10-digit national number
-- -----------------------------------------------------------------------------
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

-- -----------------------------------------------------------------------------
-- Fix existing super-admin auth user + profile (from your screenshots)
-- -----------------------------------------------------------------------------
update public.users
set
  role = 'super_admin',
  mobile_number = '8855025560',
  email = coalesce(
    nullif(trim(email), ''),
    '8855025560@phone.naganoor.local'
  ),
  is_approved = true,
  is_active = true,
  updated_at = timezone('utc', now())
where id in (
  select au.id
  from auth.users au
  where public.normalize_mobile(coalesce(au.phone, '')) = '8855025560'
);

-- Re-run invite / super-admin logic on login sync
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
      email = coalesce(
        nullif(trim(email), ''),
        v_mobile || '@phone.naganoor.local'
      ),
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

-- -----------------------------------------------------------------------------
-- Verify
-- -----------------------------------------------------------------------------
-- select public.normalize_mobile('918855025560') as m;  -- expect 8855025560
-- select public.is_super_admin_mobile('918855025560'); -- expect true
-- select id, email, mobile_number, role from public.users
--   where role = 'super_admin';
