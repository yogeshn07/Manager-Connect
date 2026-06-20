-- Migration 004: Create profiles table
-- Domain: Identity
-- 15 columns, 1 FK (auth.users), 1 CHECK, 3 indexes
-- RLS enabled immediately on creation

CREATE TABLE public.profiles (
  id              uuid        NOT NULL PRIMARY KEY REFERENCES auth.users(id),
  full_name       text        NOT NULL,
  avatar_url      text,
  title           text,
  bio             text,
  interest_tags   text[]      NOT NULL DEFAULT '{}',
  app_role        text        NOT NULL DEFAULT 'member'
                              CHECK (app_role IN ('member', 'admin', 'system')),
  push_token      text,
  notification_preferences jsonb NOT NULL DEFAULT '{
    "activity_reminders": true,
    "new_activities": true,
    "recognitions_received": true,
    "new_challenges": true,
    "challenge_reminders": true,
    "mentions": true,
    "comments_on_my_posts": true,
    "poll_reminders": true,
    "connect_buddy_updates": true
  }'::jsonb,
  is_active           boolean     NOT NULL DEFAULT true,
  is_system_account   boolean     NOT NULL DEFAULT false,
  onboarding_completed boolean    NOT NULL DEFAULT false,
  last_active_at      timestamptz,
  created_at          timestamptz NOT NULL DEFAULT now(),
  updated_at          timestamptz NOT NULL DEFAULT now()
);

-- Indexes
CREATE INDEX idx_profiles_active ON public.profiles (is_active) WHERE is_active = true;
CREATE INDEX idx_profiles_role ON public.profiles (app_role);
CREATE INDEX idx_profiles_system ON public.profiles (is_system_account) WHERE is_system_account = true;

-- Enable RLS immediately
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

-- Grant access to Supabase roles (RLS policies control actual row visibility)
GRANT SELECT, INSERT, UPDATE, DELETE ON public.profiles TO authenticated;
GRANT SELECT ON public.profiles TO anon;
