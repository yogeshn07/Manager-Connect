-- Connect Buddy system account
-- UUID: 00000000-0000-4000-8000-000000000001
-- Matches: _shared/constants.ts CONNECT_BUDDY_PROFILE_ID
-- Matches: app_constants.dart connectBuddySystemAccountId

-- Step 1: Create auth.users entry (required FK for profiles.id → auth.users.id)
INSERT INTO auth.users (
  id,
  instance_id,
  aud,
  role,
  email,
  encrypted_password,
  email_confirmed_at,
  raw_app_meta_data,
  raw_user_meta_data,
  is_sso_user,
  is_anonymous,
  created_at,
  updated_at
) VALUES (
  '00000000-0000-4000-8000-000000000001',
  '00000000-0000-0000-0000-000000000000',
  'authenticated',
  'authenticated',
  'connectbuddy@system.internal',
  crypt('SYSTEM_ACCOUNT_NO_LOGIN_' || gen_random_uuid()::text, gen_salt('bf')),
  now(),
  '{"provider": "email", "providers": ["email"], "is_system": true}'::jsonb,
  '{"is_system": true}'::jsonb,
  false,
  false,
  now(),
  now()
) ON CONFLICT (id) DO NOTHING;

-- Step 2: Create profiles entry
INSERT INTO public.profiles (
  id,
  full_name,
  app_role,
  is_active,
  is_system_account,
  onboarding_completed
) VALUES (
  '00000000-0000-4000-8000-000000000001',
  'Connect Buddy',
  'system',
  true,
  true,
  true
) ON CONFLICT (id) DO NOTHING;
