-- Hybrid auth: password admins + OTP village users

alter table public.village_app_users
  add column if not exists password_hash text,
  add column if not exists is_otp_verified boolean not null default false,
  add column if not exists temp_password_changed boolean not null default false,
  add column if not exists auth_type text not null default 'otp_user' check (
    auth_type in ('otp_user', 'dept_admin_password', 'super_admin_password')
  );

-- Existing village users: OTP verified, no password
update public.village_app_users
set
  is_otp_verified = true,
  auth_type = 'otp_user'
where role = 'user'
  and (auth_type is null or auth_type = 'otp_user');

-- Existing super admins
update public.village_app_users
set
  auth_type = 'super_admin_password',
  is_otp_verified = true,
  signup_completed = true
where role = 'super_admin';

-- Existing dept admins: keep state; activation via admin login + OTP
update public.village_app_users
set auth_type = 'dept_admin_password'
where role = 'dept_admin'
  and (auth_type is null or auth_type = 'otp_user');

notify pgrst, 'reload schema';
