-- Manager Connect: All Migrations Combined
-- Run this entire script in Supabase Dashboard > SQL Editor > New Query
-- Project: xispkgjjhqaiddbcaudt



-- ========== 20260620000001_enable_extensions.sql ==========

-- Migration 001: Enable required PostgreSQL extensions
-- Extensions: uuid-ossp (UUID generation), pgcrypto (cryptographic functions)
-- Both are used across all 26 tables for gen_random_uuid() default PKs
-- and for SHA-256 token hashing in the invitation flow.

CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";


-- ========== 20260620000002_create_update_timestamp_trigger.sql ==========

-- Migration 002: Create shared updated_at trigger function
-- This function is attached to 16 of the 26 tables via subsequent migrations.
-- It sets updated_at = now() BEFORE each UPDATE operation.
-- Tables without this trigger are append-only or immutable (see schema design).

CREATE OR REPLACE FUNCTION public.update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;


-- ========== 20260620000003_create_is_admin_helper.sql ==========

-- Migration 003: Create helper functions for RLS policies
-- Both use SECURITY DEFINER to bypass RLS when checking the caller's profile.
-- Without SECURITY DEFINER, querying profiles from within an RLS policy on
-- profiles (or any other table) would trigger recursive RLS evaluation.

-- is_active_user(): Returns true if the caller has an active profile.
-- Used as the base guard in every RLS policy on every table.
CREATE OR REPLACE FUNCTION public.is_active_user()
RETURNS boolean AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1
    FROM public.profiles
    WHERE id = auth.uid()
      AND is_active = true
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER STABLE;

-- is_admin(): Returns true if the caller is an active admin.
-- Used in admin-elevated RLS policies.
CREATE OR REPLACE FUNCTION public.is_admin()
RETURNS boolean AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1
    FROM public.profiles
    WHERE id = auth.uid()
      AND app_role = 'admin'
      AND is_active = true
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER STABLE;


-- ========== 20260620000004_create_profiles_table.sql ==========

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


-- ========== 20260620000005_create_profiles_rls_policies.sql ==========

-- Migration 005: RLS policies for profiles
-- 5 policies: SELECT(1), UPDATE(2), INSERT(1 blocked), DELETE(1 blocked)
-- Uses is_active_user() SECURITY DEFINER function to avoid infinite recursion
-- when checking the caller's is_active status on the profiles table itself.

-- SELECT: all active authenticated users can read all profiles
CREATE POLICY profiles_select_authenticated ON public.profiles
  FOR SELECT
  USING (
    auth.uid() IS NOT NULL
    AND is_active_user()
  );

-- UPDATE: member can edit only their own profile
CREATE POLICY profiles_update_own ON public.profiles
  FOR UPDATE
  USING (
    auth.uid() IS NOT NULL
    AND is_active_user()
    AND id = auth.uid()
  )
  WITH CHECK (
    id = auth.uid()
  );

-- UPDATE: admin can edit any profile (deactivation, role changes)
CREATE POLICY profiles_update_admin ON public.profiles
  FOR UPDATE
  USING (
    auth.uid() IS NOT NULL
    AND is_admin()
  );

-- INSERT: blocked for all clients (Edge Function via service_role creates profiles)
CREATE POLICY profiles_insert_blocked ON public.profiles
  FOR INSERT
  WITH CHECK (false);

-- DELETE: blocked for all clients (profiles are never hard-deleted)
CREATE POLICY profiles_delete_blocked ON public.profiles
  FOR DELETE
  USING (false);


-- ========== 20260620000006_create_profiles_updated_at_trigger.sql ==========

-- Migration 006: Attach updated_at trigger to profiles
-- Uses the shared update_updated_at_column() function from migration 002

CREATE TRIGGER set_profiles_updated_at
  BEFORE UPDATE ON public.profiles
  FOR EACH ROW
  EXECUTE FUNCTION public.update_updated_at_column();


-- ========== 20260620000007_create_invitations_table.sql ==========

-- Migration 007: Create invitations table
-- Domain: Identity
-- 11 columns, 2 FKs (profiles), 1 CHECK, 1 UNIQUE, 2 indexes
-- RLS enabled immediately on creation

CREATE TABLE public.invitations (
  id              uuid        NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  invitee_name    text        NOT NULL,
  invitee_email   text,
  invitee_phone   text,
  token_hash      text        NOT NULL UNIQUE,
  status          text        NOT NULL DEFAULT 'pending'
                              CHECK (status IN ('pending', 'accepted', 'expired', 'revoked')),
  invited_by      uuid        NOT NULL REFERENCES public.profiles(id),
  accepted_by     uuid        REFERENCES public.profiles(id),
  expires_at      timestamptz NOT NULL,
  created_at      timestamptz NOT NULL DEFAULT now(),
  updated_at      timestamptz NOT NULL DEFAULT now()
);

-- Indexes
CREATE INDEX idx_invitations_token ON public.invitations (token_hash);
CREATE INDEX idx_invitations_status ON public.invitations (status) WHERE status = 'pending';

-- Enable RLS immediately
ALTER TABLE public.invitations ENABLE ROW LEVEL SECURITY;

-- Grant access to Supabase roles (RLS policies control actual row visibility)
GRANT SELECT, INSERT, UPDATE, DELETE ON public.invitations TO authenticated;
GRANT SELECT ON public.invitations TO anon;


-- ========== 20260620000008_create_invitations_rls_policies.sql ==========

-- Migration 008: RLS policies for invitations
-- 5 policies: SELECT(2), INSERT(1), UPDATE(1), DELETE(1 blocked)
-- Uses is_active_user() and is_admin() SECURITY DEFINER helpers

-- SELECT: admin sees all invitations
CREATE POLICY invitations_select_admin ON public.invitations
  FOR SELECT
  USING (
    auth.uid() IS NOT NULL
    AND is_admin()
  );

-- SELECT: member sees only the invitation they accepted
CREATE POLICY invitations_select_own ON public.invitations
  FOR SELECT
  USING (
    auth.uid() IS NOT NULL
    AND is_active_user()
    AND accepted_by = auth.uid()
  );

-- INSERT: only admins can create invitations
CREATE POLICY invitations_insert_admin ON public.invitations
  FOR INSERT
  WITH CHECK (
    auth.uid() IS NOT NULL
    AND is_admin()
  );

-- UPDATE: only admins can update invitations (mark accepted, revoke)
CREATE POLICY invitations_update_admin ON public.invitations
  FOR UPDATE
  USING (
    auth.uid() IS NOT NULL
    AND is_admin()
  );

-- DELETE: blocked for all clients
CREATE POLICY invitations_delete_blocked ON public.invitations
  FOR DELETE
  USING (false);


-- ========== 20260620000009_create_invitations_updated_at_trigger.sql ==========

-- Migration 009: Attach updated_at trigger to invitations
-- Uses the shared update_updated_at_column() function from migration 002

CREATE TRIGGER set_invitations_updated_at
  BEFORE UPDATE ON public.invitations
  FOR EACH ROW
  EXECUTE FUNCTION public.update_updated_at_column();


-- ========== 20260620000010_create_posts_table.sql ==========

-- Migration 010: Create posts table
-- Domain: Feed
-- 8 columns, 2 FKs (profiles), soft-delete trio, 2 indexes

CREATE TABLE public.posts (
  id          uuid        NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  author_id   uuid        NOT NULL REFERENCES public.profiles(id),
  content     text        NOT NULL,
  is_deleted  boolean     NOT NULL DEFAULT false,
  deleted_by  uuid        REFERENCES public.profiles(id),
  deleted_at  timestamptz,
  created_at  timestamptz NOT NULL DEFAULT now(),
  updated_at  timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX idx_posts_feed ON public.posts (created_at DESC) WHERE is_deleted = false;
CREATE INDEX idx_posts_author ON public.posts (author_id);

ALTER TABLE public.posts ENABLE ROW LEVEL SECURITY;

GRANT SELECT, INSERT, UPDATE, DELETE ON public.posts TO authenticated;
GRANT SELECT ON public.posts TO anon;


-- ========== 20260620000011_create_posts_rls_policies.sql ==========

-- Migration 011: RLS policies for posts (6 policies)

CREATE POLICY posts_select_member ON public.posts
  FOR SELECT USING (
    auth.uid() IS NOT NULL AND is_active_user()
    AND is_deleted = false
  );

CREATE POLICY posts_select_admin ON public.posts
  FOR SELECT USING (
    auth.uid() IS NOT NULL AND is_admin()
  );

CREATE POLICY posts_insert_own ON public.posts
  FOR INSERT WITH CHECK (
    auth.uid() IS NOT NULL AND is_active_user()
    AND author_id = auth.uid()
  );

CREATE POLICY posts_update_own ON public.posts
  FOR UPDATE USING (
    auth.uid() IS NOT NULL AND is_active_user()
    AND author_id = auth.uid() AND is_deleted = false
  );

CREATE POLICY posts_update_admin ON public.posts
  FOR UPDATE USING (
    auth.uid() IS NOT NULL AND is_admin()
  );

CREATE POLICY posts_delete_blocked ON public.posts
  FOR DELETE USING (false);


-- ========== 20260620000012_create_posts_updated_at_trigger.sql ==========

-- Migration 012: Attach updated_at trigger to posts

CREATE TRIGGER set_posts_updated_at
  BEFORE UPDATE ON public.posts
  FOR EACH ROW
  EXECUTE FUNCTION public.update_updated_at_column();


-- ========== 20260620000013_create_post_images_table.sql ==========

-- Migration 013: Create post_images table
-- Domain: Feed â€” append-only, no updated_at, no trigger
-- 5 columns, 1 FK (posts CASCADE), 1 CHECK, 1 index

CREATE TABLE public.post_images (
  id            uuid        NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  post_id       uuid        NOT NULL REFERENCES public.posts(id) ON DELETE CASCADE,
  storage_path  text        NOT NULL,
  display_order smallint    NOT NULL DEFAULT 0
                            CHECK (display_order >= 0 AND display_order <= 3),
  created_at    timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX idx_post_images_post ON public.post_images (post_id, display_order ASC);

ALTER TABLE public.post_images ENABLE ROW LEVEL SECURITY;

GRANT SELECT, INSERT, UPDATE, DELETE ON public.post_images TO authenticated;
GRANT SELECT ON public.post_images TO anon;


-- ========== 20260620000014_create_post_images_rls_policies.sql ==========

-- Migration 014: RLS policies for post_images (5 policies)

CREATE POLICY post_images_select_member ON public.post_images
  FOR SELECT USING (
    auth.uid() IS NOT NULL AND is_active_user()
    AND post_id IN (SELECT id FROM public.posts WHERE is_deleted = false)
  );

CREATE POLICY post_images_select_admin ON public.post_images
  FOR SELECT USING (
    auth.uid() IS NOT NULL AND is_admin()
  );

CREATE POLICY post_images_insert_own ON public.post_images
  FOR INSERT WITH CHECK (
    auth.uid() IS NOT NULL AND is_active_user()
    AND post_id IN (SELECT id FROM public.posts WHERE author_id = auth.uid())
  );

CREATE POLICY post_images_update_blocked ON public.post_images
  FOR UPDATE USING (false);

CREATE POLICY post_images_delete_blocked ON public.post_images
  FOR DELETE USING (false);


-- ========== 20260620000015_create_post_reactions_table.sql ==========

-- Migration 015: Create post_reactions table
-- Domain: Feed â€” mutable (emoji changes), has updated_at + trigger
-- 6 columns, 2 FKs, 1 UNIQUE, 1 index

CREATE TABLE public.post_reactions (
  id          uuid        NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  post_id     uuid        NOT NULL REFERENCES public.posts(id) ON DELETE CASCADE,
  user_id     uuid        NOT NULL REFERENCES public.profiles(id),
  emoji       text        NOT NULL,
  created_at  timestamptz NOT NULL DEFAULT now(),
  updated_at  timestamptz NOT NULL DEFAULT now(),
  UNIQUE (post_id, user_id)
);

CREATE INDEX idx_reactions_post ON public.post_reactions (post_id);

ALTER TABLE public.post_reactions ENABLE ROW LEVEL SECURITY;

GRANT SELECT, INSERT, UPDATE, DELETE ON public.post_reactions TO authenticated;
GRANT SELECT ON public.post_reactions TO anon;


-- ========== 20260620000016_create_post_reactions_rls_policies.sql ==========

-- Migration 016: RLS policies for post_reactions (4 policies)

CREATE POLICY post_reactions_select_authenticated ON public.post_reactions
  FOR SELECT USING (
    auth.uid() IS NOT NULL AND is_active_user()
  );

CREATE POLICY post_reactions_insert_own ON public.post_reactions
  FOR INSERT WITH CHECK (
    auth.uid() IS NOT NULL AND is_active_user()
    AND user_id = auth.uid()
  );

CREATE POLICY post_reactions_update_own ON public.post_reactions
  FOR UPDATE USING (
    auth.uid() IS NOT NULL AND is_active_user()
    AND user_id = auth.uid()
  );

CREATE POLICY post_reactions_delete_own ON public.post_reactions
  FOR DELETE USING (
    auth.uid() IS NOT NULL AND is_active_user()
    AND user_id = auth.uid()
  );


-- ========== 20260620000016100_create_post_reactions_updated_at_trigger.sql ==========

-- Migration 016b: Attach updated_at trigger to post_reactions

CREATE TRIGGER set_post_reactions_updated_at
  BEFORE UPDATE ON public.post_reactions
  FOR EACH ROW
  EXECUTE FUNCTION public.update_updated_at_column();


-- ========== 20260620000017_create_comments_table.sql ==========

-- Migration 017: Create comments table
-- Domain: Feed â€” mutable, soft-delete, has updated_at + trigger
-- 9 columns, 3 FKs, 1 index

CREATE TABLE public.comments (
  id          uuid        NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  post_id     uuid        NOT NULL REFERENCES public.posts(id) ON DELETE CASCADE,
  author_id   uuid        NOT NULL REFERENCES public.profiles(id),
  content     text        NOT NULL,
  is_deleted  boolean     NOT NULL DEFAULT false,
  deleted_by  uuid        REFERENCES public.profiles(id),
  deleted_at  timestamptz,
  created_at  timestamptz NOT NULL DEFAULT now(),
  updated_at  timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX idx_comments_post ON public.comments (post_id, created_at ASC);

ALTER TABLE public.comments ENABLE ROW LEVEL SECURITY;

GRANT SELECT, INSERT, UPDATE, DELETE ON public.comments TO authenticated;
GRANT SELECT ON public.comments TO anon;


-- ========== 20260620000018_create_comments_rls_policies.sql ==========

-- Migration 018: RLS policies for comments (6 policies)

CREATE POLICY comments_select_member ON public.comments
  FOR SELECT USING (
    auth.uid() IS NOT NULL AND is_active_user()
    AND is_deleted = false
    AND post_id IN (SELECT id FROM public.posts WHERE is_deleted = false)
  );

CREATE POLICY comments_select_admin ON public.comments
  FOR SELECT USING (
    auth.uid() IS NOT NULL AND is_admin()
  );

CREATE POLICY comments_insert_own ON public.comments
  FOR INSERT WITH CHECK (
    auth.uid() IS NOT NULL AND is_active_user()
    AND author_id = auth.uid()
  );

CREATE POLICY comments_update_own ON public.comments
  FOR UPDATE USING (
    auth.uid() IS NOT NULL AND is_active_user()
    AND author_id = auth.uid() AND is_deleted = false
  );

CREATE POLICY comments_update_admin ON public.comments
  FOR UPDATE USING (
    auth.uid() IS NOT NULL AND is_admin()
  );

CREATE POLICY comments_delete_blocked ON public.comments
  FOR DELETE USING (false);


-- ========== 20260620000019_create_comments_updated_at_trigger.sql ==========

-- Migration 019: Attach updated_at trigger to comments

CREATE TRIGGER set_comments_updated_at
  BEFORE UPDATE ON public.comments
  FOR EACH ROW
  EXECUTE FUNCTION public.update_updated_at_column();


-- ========== 20260620000020_create_post_mentions_table.sql ==========

-- Migration 020: Create post_mentions table
-- Domain: Feed â€” append-only, no updated_at, no trigger
-- 4 columns, 2 FKs, 1 UNIQUE, 1 index

CREATE TABLE public.post_mentions (
  id                uuid        NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  post_id           uuid        NOT NULL REFERENCES public.posts(id) ON DELETE CASCADE,
  mentioned_user_id uuid        NOT NULL REFERENCES public.profiles(id),
  created_at        timestamptz NOT NULL DEFAULT now(),
  UNIQUE (post_id, mentioned_user_id)
);

CREATE INDEX idx_mentions_user ON public.post_mentions (mentioned_user_id);

ALTER TABLE public.post_mentions ENABLE ROW LEVEL SECURITY;

GRANT SELECT, INSERT, UPDATE, DELETE ON public.post_mentions TO authenticated;
GRANT SELECT ON public.post_mentions TO anon;


-- ========== 20260620000021_create_post_mentions_rls_policies.sql ==========

-- Migration 021: RLS policies for post_mentions (4 policies)
-- Service_role only for INSERT â€” Edge Function writes mentions on post creation

CREATE POLICY post_mentions_select_authenticated ON public.post_mentions
  FOR SELECT USING (
    auth.uid() IS NOT NULL AND is_active_user()
  );

CREATE POLICY post_mentions_insert_blocked ON public.post_mentions
  FOR INSERT WITH CHECK (false);

CREATE POLICY post_mentions_update_blocked ON public.post_mentions
  FOR UPDATE USING (false);

CREATE POLICY post_mentions_delete_blocked ON public.post_mentions
  FOR DELETE USING (false);


-- ========== 20260620000022_create_activities_table.sql ==========

-- Migration 022: Create activities table
-- Domain: Events
-- 13 columns, 1 FK (profiles), 3 CHECKs, 3 indexes

CREATE TABLE public.activities (
  id             uuid        NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  created_by     uuid        NOT NULL REFERENCES public.profiles(id),
  title          text        NOT NULL,
  description    text,
  event_category text        NOT NULL DEFAULT 'outings'
                             CHECK (event_category IN ('games', 'outings', 'social_connect')),
  event_type     text        CHECK (event_type IN ('cricket', 'badminton', 'pickleball', 'table_tennis',
                                                    'coffee_connect', 'lunch_meetup', 'dinner_meetup', 'other')
                                    OR event_type IS NULL),
  location       text,
  event_date     timestamptz NOT NULL,
  cost_note      text,
  status         text        NOT NULL DEFAULT 'active'
                             CHECK (status IN ('active', 'cancelled')),
  cancelled_at   timestamptz,
  created_at     timestamptz NOT NULL DEFAULT now(),
  updated_at     timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX idx_activities_date ON public.activities (event_date ASC) WHERE status = 'active';
CREATE INDEX idx_activities_creator ON public.activities (created_by);
CREATE INDEX idx_activities_category ON public.activities (event_category);

ALTER TABLE public.activities ENABLE ROW LEVEL SECURITY;

GRANT SELECT, INSERT, UPDATE, DELETE ON public.activities TO authenticated;
GRANT SELECT ON public.activities TO anon;


-- ========== 20260620000023_create_activities_rls_policies.sql ==========

-- Migration 023: RLS policies for activities (4 policies)

CREATE POLICY activities_select_authenticated ON public.activities
  FOR SELECT USING (
    auth.uid() IS NOT NULL AND is_active_user()
  );

CREATE POLICY activities_insert_authenticated ON public.activities
  FOR INSERT WITH CHECK (
    auth.uid() IS NOT NULL AND is_active_user()
    AND created_by = auth.uid()
  );

CREATE POLICY activities_update_admin ON public.activities
  FOR UPDATE USING (
    auth.uid() IS NOT NULL AND is_admin()
  );

CREATE POLICY activities_delete_blocked ON public.activities
  FOR DELETE USING (false);


-- ========== 20260620000024_create_activities_updated_at_trigger.sql ==========

-- Migration 024: Attach updated_at trigger to activities

CREATE TRIGGER set_activities_updated_at
  BEFORE UPDATE ON public.activities
  FOR EACH ROW
  EXECUTE FUNCTION public.update_updated_at_column();


-- ========== 20260620000025_create_activity_rsvps_table.sql ==========

-- Migration 025: Create activity_rsvps table
-- Domain: Events
-- 6 columns, 2 FKs, 1 CHECK, 1 UNIQUE, 2 indexes

CREATE TABLE public.activity_rsvps (
  id          uuid        NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  activity_id uuid        NOT NULL REFERENCES public.activities(id) ON DELETE CASCADE,
  user_id     uuid        NOT NULL REFERENCES public.profiles(id),
  status      text        NOT NULL CHECK (status IN ('going', 'not_going', 'maybe')),
  created_at  timestamptz NOT NULL DEFAULT now(),
  updated_at  timestamptz NOT NULL DEFAULT now(),
  UNIQUE (activity_id, user_id)
);

CREATE INDEX idx_rsvps_activity ON public.activity_rsvps (activity_id);
CREATE INDEX idx_rsvps_user ON public.activity_rsvps (user_id);

ALTER TABLE public.activity_rsvps ENABLE ROW LEVEL SECURITY;

GRANT SELECT, INSERT, UPDATE, DELETE ON public.activity_rsvps TO authenticated;
GRANT SELECT ON public.activity_rsvps TO anon;


-- ========== 20260620000026_create_activity_rsvps_rls_policies.sql ==========

-- Migration 026: RLS policies for activity_rsvps (4 policies)

CREATE POLICY activity_rsvps_select_authenticated ON public.activity_rsvps
  FOR SELECT USING (
    auth.uid() IS NOT NULL AND is_active_user()
  );

CREATE POLICY activity_rsvps_insert_own ON public.activity_rsvps
  FOR INSERT WITH CHECK (
    auth.uid() IS NOT NULL AND is_active_user()
    AND user_id = auth.uid()
  );

CREATE POLICY activity_rsvps_update_own ON public.activity_rsvps
  FOR UPDATE USING (
    auth.uid() IS NOT NULL AND is_active_user()
    AND user_id = auth.uid()
  );

CREATE POLICY activity_rsvps_delete_own ON public.activity_rsvps
  FOR DELETE USING (
    auth.uid() IS NOT NULL AND is_active_user()
    AND user_id = auth.uid()
  );


-- ========== 20260620000027_create_activity_rsvps_updated_at_trigger.sql ==========

-- Migration 027: Attach updated_at trigger to activity_rsvps

CREATE TRIGGER set_activity_rsvps_updated_at
  BEFORE UPDATE ON public.activity_rsvps
  FOR EACH ROW
  EXECUTE FUNCTION public.update_updated_at_column();


-- ========== 20260620000028_create_activity_updates_table.sql ==========

-- Migration 028: Create activity_updates table
-- Domain: Events â€” append-only, no updated_at, no trigger
-- 5 columns, 2 FKs, 1 index

CREATE TABLE public.activity_updates (
  id          uuid        NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  activity_id uuid        NOT NULL REFERENCES public.activities(id) ON DELETE CASCADE,
  author_id   uuid        NOT NULL REFERENCES public.profiles(id),
  content     text        NOT NULL,
  created_at  timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX idx_activity_updates_activity ON public.activity_updates (activity_id, created_at ASC);

ALTER TABLE public.activity_updates ENABLE ROW LEVEL SECURITY;

GRANT SELECT, INSERT, UPDATE, DELETE ON public.activity_updates TO authenticated;
GRANT SELECT ON public.activity_updates TO anon;


-- ========== 20260620000029_create_activity_updates_rls_policies.sql ==========

-- Migration 029: RLS policies for activity_updates (4 policies)
-- Insert/update restricted to admin (Edge Function handles creator check)

CREATE POLICY activity_updates_select_authenticated ON public.activity_updates
  FOR SELECT USING (
    auth.uid() IS NOT NULL AND is_active_user()
  );

CREATE POLICY activity_updates_insert_admin ON public.activity_updates
  FOR INSERT WITH CHECK (
    auth.uid() IS NOT NULL AND is_admin()
  );

CREATE POLICY activity_updates_update_admin ON public.activity_updates
  FOR UPDATE USING (
    auth.uid() IS NOT NULL AND is_admin()
  );

CREATE POLICY activity_updates_delete_blocked ON public.activity_updates
  FOR DELETE USING (false);


-- ========== 20260620000030_create_polls_table.sql ==========

-- Migration 030: Create polls table
-- Domain: Events
-- 9 columns, 2 FKs, 2 indexes, has updated_at trigger

CREATE TABLE public.polls (
  id          uuid        NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  activity_id uuid        REFERENCES public.activities(id) ON DELETE SET NULL,
  created_by  uuid        NOT NULL REFERENCES public.profiles(id),
  question    text        NOT NULL,
  closes_at   timestamptz NOT NULL,
  is_closed   boolean     NOT NULL DEFAULT false,
  closed_at   timestamptz,
  created_at  timestamptz NOT NULL DEFAULT now(),
  updated_at  timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX idx_polls_activity ON public.polls (activity_id);
CREATE INDEX idx_polls_open ON public.polls (closes_at ASC) WHERE is_closed = false;

ALTER TABLE public.polls ENABLE ROW LEVEL SECURITY;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.polls TO authenticated;
GRANT SELECT ON public.polls TO anon;


-- ========== 20260620000031_create_polls_rls_policies.sql ==========

-- Migration 031: RLS policies for polls (4 policies)

CREATE POLICY polls_select_authenticated ON public.polls
  FOR SELECT USING (auth.uid() IS NOT NULL AND is_active_user());

CREATE POLICY polls_insert_admin ON public.polls
  FOR INSERT WITH CHECK (auth.uid() IS NOT NULL AND is_admin());

CREATE POLICY polls_update_admin ON public.polls
  FOR UPDATE USING (auth.uid() IS NOT NULL AND is_admin());

CREATE POLICY polls_delete_blocked ON public.polls
  FOR DELETE USING (false);


-- ========== 20260620000032_create_polls_updated_at_trigger.sql ==========

-- Migration 032: Attach updated_at trigger to polls

CREATE TRIGGER set_polls_updated_at
  BEFORE UPDATE ON public.polls
  FOR EACH ROW
  EXECUTE FUNCTION public.update_updated_at_column();


-- ========== 20260620000033_create_poll_options_table.sql ==========

-- Migration 033: Create poll_options table
-- Domain: Events â€” append-only, no updated_at, no trigger
-- 5 columns, 1 FK (CASCADE), 1 CHECK, 1 index

CREATE TABLE public.poll_options (
  id            uuid        NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  poll_id       uuid        NOT NULL REFERENCES public.polls(id) ON DELETE CASCADE,
  option_text   text        NOT NULL,
  display_order smallint    NOT NULL DEFAULT 0 CHECK (display_order >= 0),
  created_at    timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX idx_poll_options_poll ON public.poll_options (poll_id, display_order ASC);

ALTER TABLE public.poll_options ENABLE ROW LEVEL SECURITY;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.poll_options TO authenticated;
GRANT SELECT ON public.poll_options TO anon;


-- ========== 20260620000034_create_poll_options_rls_policies.sql ==========

-- Migration 034: RLS policies for poll_options (4 policies)

CREATE POLICY poll_options_select_authenticated ON public.poll_options
  FOR SELECT USING (auth.uid() IS NOT NULL AND is_active_user());

CREATE POLICY poll_options_insert_admin ON public.poll_options
  FOR INSERT WITH CHECK (auth.uid() IS NOT NULL AND is_admin());

CREATE POLICY poll_options_update_blocked ON public.poll_options
  FOR UPDATE USING (false);

CREATE POLICY poll_options_delete_blocked ON public.poll_options
  FOR DELETE USING (false);


-- ========== 20260620000035_create_poll_votes_table.sql ==========

-- Migration 035: Create poll_votes table
-- Domain: Events â€” append-only, no updated_at, no trigger
-- 5 columns, 3 FKs (CASCADE), 1 UNIQUE, 3 indexes

CREATE TABLE public.poll_votes (
  id             uuid        NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  poll_id        uuid        NOT NULL REFERENCES public.polls(id) ON DELETE CASCADE,
  poll_option_id uuid        NOT NULL REFERENCES public.poll_options(id) ON DELETE CASCADE,
  user_id        uuid        NOT NULL REFERENCES public.profiles(id),
  created_at     timestamptz NOT NULL DEFAULT now(),
  UNIQUE (poll_id, user_id)
);

CREATE INDEX idx_poll_votes_poll ON public.poll_votes (poll_id);
CREATE INDEX idx_poll_votes_option ON public.poll_votes (poll_option_id);
CREATE INDEX idx_poll_votes_user ON public.poll_votes (user_id);

ALTER TABLE public.poll_votes ENABLE ROW LEVEL SECURITY;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.poll_votes TO authenticated;
GRANT SELECT ON public.poll_votes TO anon;


-- ========== 20260620000036_create_poll_votes_rls_policies.sql ==========

-- Migration 036: RLS policies for poll_votes (4 policies)

CREATE POLICY poll_votes_select_authenticated ON public.poll_votes
  FOR SELECT USING (auth.uid() IS NOT NULL AND is_active_user());

CREATE POLICY poll_votes_insert_own ON public.poll_votes
  FOR INSERT WITH CHECK (
    auth.uid() IS NOT NULL AND is_active_user()
    AND user_id = auth.uid()
  );

CREATE POLICY poll_votes_update_blocked ON public.poll_votes
  FOR UPDATE USING (false);

CREATE POLICY poll_votes_delete_blocked ON public.poll_votes
  FOR DELETE USING (false);


-- ========== 20260620000037_create_event_attendance_table.sql ==========

-- Migration 037: Create event_attendance table
-- Domain: Events â€” mutable (admin corrections), has updated_at trigger
-- 8 columns, 3 FKs, 1 CHECK, 1 UNIQUE, 2 indexes

CREATE TABLE public.event_attendance (
  id          uuid        NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  activity_id uuid        NOT NULL REFERENCES public.activities(id) ON DELETE CASCADE,
  user_id     uuid        NOT NULL REFERENCES public.profiles(id),
  status      text        NOT NULL CHECK (status IN ('attended', 'absent')),
  recorded_by uuid        NOT NULL REFERENCES public.profiles(id),
  recorded_at timestamptz NOT NULL DEFAULT now(),
  created_at  timestamptz NOT NULL DEFAULT now(),
  updated_at  timestamptz NOT NULL DEFAULT now(),
  UNIQUE (activity_id, user_id)
);

CREATE INDEX idx_attendance_activity ON public.event_attendance (activity_id);
CREATE INDEX idx_attendance_user ON public.event_attendance (user_id);

ALTER TABLE public.event_attendance ENABLE ROW LEVEL SECURITY;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.event_attendance TO authenticated;
GRANT SELECT ON public.event_attendance TO anon;


-- ========== 20260620000038_create_event_attendance_rls_policies.sql ==========

-- Migration 038: RLS policies for event_attendance (4 policies)

CREATE POLICY event_attendance_select_authenticated ON public.event_attendance
  FOR SELECT USING (auth.uid() IS NOT NULL AND is_active_user());

CREATE POLICY event_attendance_insert_admin ON public.event_attendance
  FOR INSERT WITH CHECK (auth.uid() IS NOT NULL AND is_admin());

CREATE POLICY event_attendance_update_admin ON public.event_attendance
  FOR UPDATE USING (auth.uid() IS NOT NULL AND is_admin());

CREATE POLICY event_attendance_delete_blocked ON public.event_attendance
  FOR DELETE USING (false);


-- ========== 20260620000039_create_event_attendance_updated_at_trigger.sql ==========

-- Migration 039: Attach updated_at trigger to event_attendance

CREATE TRIGGER set_event_attendance_updated_at
  BEFORE UPDATE ON public.event_attendance
  FOR EACH ROW
  EXECUTE FUNCTION public.update_updated_at_column();


-- ========== 20260620000040_create_challenges_table.sql ==========

-- Migration 040: Create challenges table
-- Domain: Growth
-- 13 columns, 1 FK, 4 CHECKs, 1 index, has updated_at trigger

CREATE TABLE public.challenges (
  id               uuid        NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  created_by       uuid        NOT NULL REFERENCES public.profiles(id),
  title            text        NOT NULL,
  description      text,
  challenge_type   text        NOT NULL CHECK (challenge_type IN ('fitness', 'wellness')),
  goal_type        text        NOT NULL CHECK (goal_type IN ('steps', 'distance', 'duration', 'custom')),
  goal_description text,
  start_date       date        NOT NULL,
  end_date         date        NOT NULL,
  status           text        NOT NULL DEFAULT 'active' CHECK (status IN ('active', 'ended')),
  ended_at         timestamptz,
  created_at       timestamptz NOT NULL DEFAULT now(),
  updated_at       timestamptz NOT NULL DEFAULT now(),
  CHECK (end_date > start_date)
);

CREATE INDEX idx_challenges_status ON public.challenges (status, end_date ASC);

ALTER TABLE public.challenges ENABLE ROW LEVEL SECURITY;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.challenges TO authenticated;
GRANT SELECT ON public.challenges TO anon;


-- ========== 20260620000041_create_challenges_rls_policies.sql ==========

-- Migration 041: RLS policies for challenges (4 policies)
-- INSERT: any active member per FR-05.1/FR-05.2

CREATE POLICY challenges_select_authenticated ON public.challenges
  FOR SELECT USING (auth.uid() IS NOT NULL AND is_active_user());

CREATE POLICY challenges_insert_authenticated ON public.challenges
  FOR INSERT WITH CHECK (
    auth.uid() IS NOT NULL AND is_active_user()
    AND created_by = auth.uid()
  );

CREATE POLICY challenges_update_admin ON public.challenges
  FOR UPDATE USING (auth.uid() IS NOT NULL AND is_admin());

CREATE POLICY challenges_delete_blocked ON public.challenges
  FOR DELETE USING (false);


-- ========== 20260620000042_create_challenges_updated_at_trigger.sql ==========

-- Migration 042: Attach updated_at trigger to challenges

CREATE TRIGGER set_challenges_updated_at
  BEFORE UPDATE ON public.challenges
  FOR EACH ROW
  EXECUTE FUNCTION public.update_updated_at_column();


-- ========== 20260620000043_create_challenge_participants_table.sql ==========

-- Migration 043: Create challenge_participants table
-- Domain: Growth â€” append-only, no updated_at, no trigger
-- 4 columns, 2 FKs, 1 UNIQUE, 2 indexes

CREATE TABLE public.challenge_participants (
  id           uuid        NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  challenge_id uuid        NOT NULL REFERENCES public.challenges(id) ON DELETE CASCADE,
  user_id      uuid        NOT NULL REFERENCES public.profiles(id),
  joined_at    timestamptz NOT NULL DEFAULT now(),
  UNIQUE (challenge_id, user_id)
);

CREATE INDEX idx_participants_challenge ON public.challenge_participants (challenge_id);
CREATE INDEX idx_participants_user ON public.challenge_participants (user_id);

ALTER TABLE public.challenge_participants ENABLE ROW LEVEL SECURITY;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.challenge_participants TO authenticated;
GRANT SELECT ON public.challenge_participants TO anon;


-- ========== 20260620000044_create_challenge_participants_rls_policies.sql ==========

-- Migration 044: RLS policies for challenge_participants (4 policies)

CREATE POLICY challenge_participants_select_authenticated ON public.challenge_participants
  FOR SELECT USING (auth.uid() IS NOT NULL AND is_active_user());

CREATE POLICY challenge_participants_insert_own ON public.challenge_participants
  FOR INSERT WITH CHECK (
    auth.uid() IS NOT NULL AND is_active_user()
    AND user_id = auth.uid()
  );

CREATE POLICY challenge_participants_update_blocked ON public.challenge_participants
  FOR UPDATE USING (false);

CREATE POLICY challenge_participants_delete_own ON public.challenge_participants
  FOR DELETE USING (
    auth.uid() IS NOT NULL AND is_active_user()
    AND user_id = auth.uid()
  );


-- ========== 20260620000045_create_progress_logs_table.sql ==========

-- Migration 045: Create progress_logs table
-- Domain: Growth â€” mutable (upsert on same day), has updated_at trigger
-- 9 columns, 3 FKs, 1 CHECK, 1 UNIQUE, 1 index

CREATE TABLE public.progress_logs (
  id                       uuid          NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  challenge_id             uuid          NOT NULL REFERENCES public.challenges(id) ON DELETE CASCADE,
  user_id                  uuid          NOT NULL REFERENCES public.profiles(id),
  challenge_participant_id uuid          NOT NULL REFERENCES public.challenge_participants(id) ON DELETE CASCADE,
  log_date                 date          NOT NULL,
  value                    numeric(12,2) NOT NULL CHECK (value >= 0),
  note                     text,
  created_at               timestamptz   NOT NULL DEFAULT now(),
  updated_at               timestamptz   NOT NULL DEFAULT now(),
  UNIQUE (challenge_id, user_id, log_date)
);

CREATE INDEX idx_progress_leaderboard ON public.progress_logs (challenge_id, user_id);

ALTER TABLE public.progress_logs ENABLE ROW LEVEL SECURITY;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.progress_logs TO authenticated;
GRANT SELECT ON public.progress_logs TO anon;


-- ========== 20260620000046_create_progress_logs_rls_policies.sql ==========

-- Migration 046: RLS policies for progress_logs (5 policies)
-- SELECT: all authenticated (leaderboard requires all-member access)

CREATE POLICY progress_logs_select_authenticated ON public.progress_logs
  FOR SELECT USING (auth.uid() IS NOT NULL AND is_active_user());

CREATE POLICY progress_logs_select_admin ON public.progress_logs
  FOR SELECT USING (auth.uid() IS NOT NULL AND is_admin());

CREATE POLICY progress_logs_insert_own ON public.progress_logs
  FOR INSERT WITH CHECK (
    auth.uid() IS NOT NULL AND is_active_user()
    AND user_id = auth.uid()
  );

CREATE POLICY progress_logs_update_own ON public.progress_logs
  FOR UPDATE USING (
    auth.uid() IS NOT NULL AND is_active_user()
    AND user_id = auth.uid()
  );

CREATE POLICY progress_logs_delete_blocked ON public.progress_logs
  FOR DELETE USING (false);


-- ========== 20260620000047_create_progress_logs_updated_at_trigger.sql ==========

-- Migration 047: Attach updated_at trigger to progress_logs

CREATE TRIGGER set_progress_logs_updated_at
  BEFORE UPDATE ON public.progress_logs
  FOR EACH ROW
  EXECUTE FUNCTION public.update_updated_at_column();


-- ========== 20260620000048_create_recognitions_table.sql ==========

-- Migration 048: Create recognitions table
-- Domain: Recognition
-- 9 columns, 2 FKs, 1 CHECK, soft-delete, 2 indexes, has updated_at trigger

CREATE TABLE public.recognitions (
  id           uuid        NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  giver_id     uuid        NOT NULL REFERENCES public.profiles(id),
  category_tag text        NOT NULL CHECK (category_tag IN (
    'community_contributor', 'fitness_champion', 'wellness_champion',
    'event_champion', 'most_supportive_manager'
  )),
  message      text        NOT NULL,
  is_deleted   boolean     NOT NULL DEFAULT false,
  deleted_by   uuid        REFERENCES public.profiles(id),
  deleted_at   timestamptz,
  created_at   timestamptz NOT NULL DEFAULT now(),
  updated_at   timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX idx_recognitions_feed ON public.recognitions (created_at DESC) WHERE is_deleted = false;
CREATE INDEX idx_recognitions_giver ON public.recognitions (giver_id);

ALTER TABLE public.recognitions ENABLE ROW LEVEL SECURITY;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.recognitions TO authenticated;
GRANT SELECT ON public.recognitions TO anon;


-- ========== 20260620000049_create_recognitions_rls_policies.sql ==========

-- Migration 049: RLS policies for recognitions (6 policies)

CREATE POLICY recognitions_select_member ON public.recognitions
  FOR SELECT USING (
    auth.uid() IS NOT NULL AND is_active_user()
    AND is_deleted = false
  );

CREATE POLICY recognitions_select_admin ON public.recognitions
  FOR SELECT USING (auth.uid() IS NOT NULL AND is_admin());

CREATE POLICY recognitions_insert_own ON public.recognitions
  FOR INSERT WITH CHECK (
    auth.uid() IS NOT NULL AND is_active_user()
    AND giver_id = auth.uid()
  );

CREATE POLICY recognitions_update_blocked ON public.recognitions
  FOR UPDATE USING (false);

CREATE POLICY recognitions_update_admin ON public.recognitions
  FOR UPDATE USING (auth.uid() IS NOT NULL AND is_admin());

CREATE POLICY recognitions_delete_blocked ON public.recognitions
  FOR DELETE USING (false);


-- ========== 20260620000050_create_recognitions_updated_at_trigger.sql ==========

-- Migration 050: Attach updated_at trigger to recognitions

CREATE TRIGGER set_recognitions_updated_at
  BEFORE UPDATE ON public.recognitions
  FOR EACH ROW
  EXECUTE FUNCTION public.update_updated_at_column();


-- ========== 20260620000051_create_recognition_recipients_table.sql ==========

-- Migration 051: Create recognition_recipients table
-- Domain: Recognition â€” append-only, no updated_at, no trigger
-- 4 columns, 2 FKs, 1 UNIQUE, 2 indexes

CREATE TABLE public.recognition_recipients (
  id             uuid        NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  recognition_id uuid        NOT NULL REFERENCES public.recognitions(id) ON DELETE CASCADE,
  recipient_id   uuid        NOT NULL REFERENCES public.profiles(id),
  created_at     timestamptz NOT NULL DEFAULT now(),
  UNIQUE (recognition_id, recipient_id)
);

CREATE INDEX idx_recipients_recognition ON public.recognition_recipients (recognition_id);
CREATE INDEX idx_recipients_user ON public.recognition_recipients (recipient_id);

ALTER TABLE public.recognition_recipients ENABLE ROW LEVEL SECURITY;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.recognition_recipients TO authenticated;
GRANT SELECT ON public.recognition_recipients TO anon;


-- ========== 20260620000052_create_recognition_recipients_rls_policies.sql ==========

-- Migration 052: RLS policies for recognition_recipients (4 policies)
-- INSERT uses subquery to verify caller is the recognition giver

CREATE POLICY recognition_recipients_select_authenticated ON public.recognition_recipients
  FOR SELECT USING (auth.uid() IS NOT NULL AND is_active_user());

CREATE POLICY recognition_recipients_insert_own ON public.recognition_recipients
  FOR INSERT WITH CHECK (
    auth.uid() IS NOT NULL AND is_active_user()
    AND recognition_id IN (
      SELECT id FROM public.recognitions WHERE giver_id = auth.uid()
    )
  );

CREATE POLICY recognition_recipients_update_blocked ON public.recognition_recipients
  FOR UPDATE USING (false);

CREATE POLICY recognition_recipients_delete_blocked ON public.recognition_recipients
  FOR DELETE USING (false);


-- ========== 20260620000053_create_recognition_reactions_table.sql ==========

-- Migration 053: Create recognition_reactions table
-- Domain: Recognition â€” mutable (emoji changes), has updated_at trigger
-- 6 columns, 2 FKs, 1 UNIQUE, 1 index

CREATE TABLE public.recognition_reactions (
  id             uuid        NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  recognition_id uuid        NOT NULL REFERENCES public.recognitions(id) ON DELETE CASCADE,
  user_id        uuid        NOT NULL REFERENCES public.profiles(id),
  emoji          text        NOT NULL,
  created_at     timestamptz NOT NULL DEFAULT now(),
  updated_at     timestamptz NOT NULL DEFAULT now(),
  UNIQUE (recognition_id, user_id)
);

CREATE INDEX idx_recog_reactions_recognition ON public.recognition_reactions (recognition_id);

ALTER TABLE public.recognition_reactions ENABLE ROW LEVEL SECURITY;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.recognition_reactions TO authenticated;
GRANT SELECT ON public.recognition_reactions TO anon;


-- ========== 20260620000054_create_recognition_reactions_rls_policies.sql ==========

-- Migration 054: RLS policies for recognition_reactions (4 policies)

CREATE POLICY recognition_reactions_select_authenticated ON public.recognition_reactions
  FOR SELECT USING (auth.uid() IS NOT NULL AND is_active_user());

CREATE POLICY recognition_reactions_insert_own ON public.recognition_reactions
  FOR INSERT WITH CHECK (
    auth.uid() IS NOT NULL AND is_active_user()
    AND user_id = auth.uid()
  );

CREATE POLICY recognition_reactions_update_own ON public.recognition_reactions
  FOR UPDATE USING (
    auth.uid() IS NOT NULL AND is_active_user()
    AND user_id = auth.uid()
  );

CREATE POLICY recognition_reactions_delete_own ON public.recognition_reactions
  FOR DELETE USING (
    auth.uid() IS NOT NULL AND is_active_user()
    AND user_id = auth.uid()
  );


-- ========== 20260620000055_create_recognition_reactions_updated_at_trigger.sql ==========

-- Migration 055: Attach updated_at trigger to recognition_reactions

CREATE TRIGGER set_recognition_reactions_updated_at
  BEFORE UPDATE ON public.recognition_reactions
  FOR EACH ROW
  EXECUTE FUNCTION public.update_updated_at_column();


-- ========== 20260620000056_create_member_monthly_stats_table.sql ==========

-- Migration 056: Create member_monthly_stats table
-- Domain: Analytics â€” service_role write only, has updated_at trigger
-- 14 columns, 1 FK, 8 CHECKs, 1 UNIQUE, 2 indexes

CREATE TABLE public.member_monthly_stats (
  id                   uuid          NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id              uuid          NOT NULL REFERENCES public.profiles(id),
  stat_month           date          NOT NULL,
  events_attended      integer       NOT NULL DEFAULT 0 CHECK (events_attended >= 0),
  attendance_rate      numeric(5,2)  NOT NULL DEFAULT 0.00 CHECK (attendance_rate >= 0 AND attendance_rate <= 100),
  challenges_joined    integer       NOT NULL DEFAULT 0 CHECK (challenges_joined >= 0),
  progress_logs_count  integer       NOT NULL DEFAULT 0 CHECK (progress_logs_count >= 0),
  recognitions_received integer      NOT NULL DEFAULT 0 CHECK (recognitions_received >= 0),
  recognitions_given   integer       NOT NULL DEFAULT 0 CHECK (recognitions_given >= 0),
  posts_count          integer       NOT NULL DEFAULT 0 CHECK (posts_count >= 0),
  composite_score      numeric(6,2)  NOT NULL DEFAULT 0.00 CHECK (composite_score >= 0),
  computed_at          timestamptz   NOT NULL DEFAULT now(),
  created_at           timestamptz   NOT NULL DEFAULT now(),
  updated_at           timestamptz   NOT NULL DEFAULT now(),
  UNIQUE (user_id, stat_month)
);

CREATE INDEX idx_monthly_stats_user ON public.member_monthly_stats (user_id, stat_month DESC);
CREATE INDEX idx_monthly_stats_month ON public.member_monthly_stats (stat_month, composite_score DESC);

ALTER TABLE public.member_monthly_stats ENABLE ROW LEVEL SECURITY;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.member_monthly_stats TO authenticated;
GRANT SELECT ON public.member_monthly_stats TO anon;


-- ========== 20260620000057_create_member_monthly_stats_rls_policies.sql ==========

-- Migration 057: RLS policies for member_monthly_stats (4 policies)
-- All writes blocked for clients â€” service_role only (compute-monthly-stats EF)

CREATE POLICY member_monthly_stats_select_authenticated ON public.member_monthly_stats
  FOR SELECT USING (auth.uid() IS NOT NULL AND is_active_user());

CREATE POLICY member_monthly_stats_insert_blocked ON public.member_monthly_stats
  FOR INSERT WITH CHECK (false);

CREATE POLICY member_monthly_stats_update_blocked ON public.member_monthly_stats
  FOR UPDATE USING (false);

CREATE POLICY member_monthly_stats_delete_blocked ON public.member_monthly_stats
  FOR DELETE USING (false);


-- ========== 20260620000058_create_member_monthly_stats_updated_at_trigger.sql ==========

-- Migration 058: Attach updated_at trigger to member_monthly_stats

CREATE TRIGGER set_member_monthly_stats_updated_at
  BEFORE UPDATE ON public.member_monthly_stats
  FOR EACH ROW
  EXECUTE FUNCTION public.update_updated_at_column();


-- ========== 20260620000059_create_community_health_scores_table.sql ==========

-- Migration 059: Create community_health_scores table
-- Domain: Analytics â€” service_role write only, NO updated_at (upserted, not updated)
-- 10 columns, no FKs, 6 CHECKs, 1 UNIQUE (score_month)

CREATE TABLE public.community_health_scores (
  id                       uuid          NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  score_month              date          NOT NULL UNIQUE,
  score                    numeric(5,2)  NOT NULL CHECK (score >= 0 AND score <= 100),
  active_member_count      integer       NOT NULL DEFAULT 0 CHECK (active_member_count >= 0),
  avg_attendance_rate      numeric(5,2)  NOT NULL DEFAULT 0.00 CHECK (avg_attendance_rate >= 0 AND avg_attendance_rate <= 100),
  challenge_engagement_rate numeric(5,2) NOT NULL DEFAULT 0.00 CHECK (challenge_engagement_rate >= 0 AND challenge_engagement_rate <= 100),
  recognition_activity_rate numeric(5,2) NOT NULL DEFAULT 0.00 CHECK (recognition_activity_rate >= 0 AND recognition_activity_rate <= 100),
  participation_rate       numeric(5,2)  NOT NULL DEFAULT 0.00 CHECK (participation_rate >= 0 AND participation_rate <= 100),
  computed_at              timestamptz   NOT NULL DEFAULT now(),
  created_at               timestamptz   NOT NULL DEFAULT now()
);

-- No additional indexes needed â€” UNIQUE(score_month) covers the primary query pattern

ALTER TABLE public.community_health_scores ENABLE ROW LEVEL SECURITY;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.community_health_scores TO authenticated;
GRANT SELECT ON public.community_health_scores TO anon;


-- ========== 20260620000060_create_community_health_scores_rls_policies.sql ==========

-- Migration 060: RLS policies for community_health_scores (4 policies)

CREATE POLICY community_health_scores_select_authenticated ON public.community_health_scores
  FOR SELECT USING (auth.uid() IS NOT NULL AND is_active_user());

CREATE POLICY community_health_scores_insert_blocked ON public.community_health_scores
  FOR INSERT WITH CHECK (false);

CREATE POLICY community_health_scores_update_blocked ON public.community_health_scores
  FOR UPDATE USING (false);

CREATE POLICY community_health_scores_delete_blocked ON public.community_health_scores
  FOR DELETE USING (false);


-- ========== 20260620000061_create_notification_inbox_table.sql ==========

-- Migration 061: Create notification_inbox table
-- Domain: Notifications â€” append-only for content, no updated_at trigger
-- is_read/read_at are the only mutable fields (UPDATE policy scoped to these)
-- 11 columns, 2 FKs, 2 CHECKs, 2 indexes

CREATE TABLE public.notification_inbox (
  id             uuid        NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  recipient_id   uuid        NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  actor_id       uuid        REFERENCES public.profiles(id) ON DELETE SET NULL,
  type           text        NOT NULL CHECK (type IN (
    'activity_created', 'activity_reminder_24h', 'activity_reminder_1h',
    'activity_cancelled', 'activity_updated', 'poll_reminder',
    'recognition_received', 'challenge_created', 'challenge_ending',
    'challenge_ended', 'mention', 'comment_on_post',
    'connect_buddy_update', 'admin_flag', 'admin_member_registered'
  )),
  title          text        NOT NULL,
  body           text        NOT NULL,
  reference_type text        CHECK (reference_type IN (
    'activity', 'challenge', 'recognition', 'poll', 'post', 'user'
  ) OR reference_type IS NULL),
  reference_id   uuid,
  is_read        boolean     NOT NULL DEFAULT false,
  read_at        timestamptz,
  created_at     timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX idx_notifications_recipient ON public.notification_inbox (recipient_id, created_at DESC);
CREATE INDEX idx_notifications_unread ON public.notification_inbox (recipient_id) WHERE is_read = false;

ALTER TABLE public.notification_inbox ENABLE ROW LEVEL SECURITY;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.notification_inbox TO authenticated;
GRANT SELECT ON public.notification_inbox TO anon;


-- ========== 20260620000062_create_notification_inbox_rls_policies.sql ==========

-- Migration 062: RLS policies for notification_inbox (4 policies)

CREATE POLICY notification_inbox_select_own ON public.notification_inbox
  FOR SELECT USING (
    auth.uid() IS NOT NULL AND is_active_user()
    AND recipient_id = auth.uid()
  );

CREATE POLICY notification_inbox_insert_blocked ON public.notification_inbox
  FOR INSERT WITH CHECK (false);

CREATE POLICY notification_inbox_update_own ON public.notification_inbox
  FOR UPDATE USING (
    auth.uid() IS NOT NULL AND is_active_user()
    AND recipient_id = auth.uid()
  );

CREATE POLICY notification_inbox_delete_blocked ON public.notification_inbox
  FOR DELETE USING (false);


-- ========== 20260620000063_create_flagged_content_table.sql ==========

-- Migration 063: Create flagged_content table
-- Domain: Admin
-- 10 columns, 2 FKs, 2 CHECKs, 1 index (partial), has updated_at trigger

CREATE TABLE public.flagged_content (
  id           uuid        NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  reporter_id  uuid        NOT NULL REFERENCES public.profiles(id),
  content_type text        NOT NULL CHECK (content_type IN ('post', 'comment')),
  content_id   uuid        NOT NULL,
  reason       text,
  status       text        NOT NULL DEFAULT 'pending'
                           CHECK (status IN ('pending', 'resolved_deleted', 'resolved_dismissed')),
  resolved_by  uuid        REFERENCES public.profiles(id),
  resolved_at  timestamptz,
  created_at   timestamptz NOT NULL DEFAULT now(),
  updated_at   timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX idx_flags_status ON public.flagged_content (status) WHERE status = 'pending';

ALTER TABLE public.flagged_content ENABLE ROW LEVEL SECURITY;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.flagged_content TO authenticated;
GRANT SELECT ON public.flagged_content TO anon;


-- ========== 20260620000064_create_flagged_content_rls_policies.sql ==========

-- Migration 064: RLS policies for flagged_content (4 policies)

CREATE POLICY flagged_content_select_admin ON public.flagged_content
  FOR SELECT USING (auth.uid() IS NOT NULL AND is_admin());

CREATE POLICY flagged_content_insert_own ON public.flagged_content
  FOR INSERT WITH CHECK (
    auth.uid() IS NOT NULL AND is_active_user()
    AND reporter_id = auth.uid()
  );

CREATE POLICY flagged_content_update_admin ON public.flagged_content
  FOR UPDATE USING (auth.uid() IS NOT NULL AND is_admin());

CREATE POLICY flagged_content_delete_blocked ON public.flagged_content
  FOR DELETE USING (false);


-- ========== 20260620000065_create_flagged_content_updated_at_trigger.sql ==========

-- Migration 065: Attach updated_at trigger to flagged_content

CREATE TRIGGER set_flagged_content_updated_at
  BEFORE UPDATE ON public.flagged_content
  FOR EACH ROW
  EXECUTE FUNCTION public.update_updated_at_column();


-- ========== 20260620000066_create_pinned_announcements_table.sql ==========

-- Migration 066: Create pinned_announcements table
-- Domain: Admin
-- 6 columns, 2 FKs, 1 index (partial), has updated_at trigger

CREATE TABLE public.pinned_announcements (
  id         uuid        NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  post_id    uuid        NOT NULL REFERENCES public.posts(id) ON DELETE CASCADE,
  pinned_by  uuid        NOT NULL REFERENCES public.profiles(id),
  is_active  boolean     NOT NULL DEFAULT true,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX idx_pinned_active ON public.pinned_announcements (is_active) WHERE is_active = true;

ALTER TABLE public.pinned_announcements ENABLE ROW LEVEL SECURITY;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.pinned_announcements TO authenticated;
GRANT SELECT ON public.pinned_announcements TO anon;


-- ========== 20260620000067_create_pinned_announcements_rls_policies.sql ==========

-- Migration 067: RLS policies for pinned_announcements (4 policies)

CREATE POLICY pinned_announcements_select_authenticated ON public.pinned_announcements
  FOR SELECT USING (auth.uid() IS NOT NULL AND is_active_user());

CREATE POLICY pinned_announcements_insert_admin ON public.pinned_announcements
  FOR INSERT WITH CHECK (auth.uid() IS NOT NULL AND is_admin());

CREATE POLICY pinned_announcements_update_admin ON public.pinned_announcements
  FOR UPDATE USING (auth.uid() IS NOT NULL AND is_admin());

CREATE POLICY pinned_announcements_delete_blocked ON public.pinned_announcements
  FOR DELETE USING (false);


-- ========== 20260620000068_create_pinned_announcements_updated_at_trigger.sql ==========

-- Migration 068: Attach updated_at trigger to pinned_announcements

CREATE TRIGGER set_pinned_announcements_updated_at
  BEFORE UPDATE ON public.pinned_announcements
  FOR EACH ROW
  EXECUTE FUNCTION public.update_updated_at_column();


-- ========== 20260620000069_create_admin_audit_log_table.sql ==========

-- Migration 069: Create admin_audit_log table
-- Domain: Admin â€” IMMUTABLE: no updated_at, no created_at, no trigger
-- performed_at is the sole timestamp
-- 7 columns, 1 FK, 2 CHECKs, 2 indexes

CREATE TABLE public.admin_audit_log (
  id           uuid        NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  admin_id     uuid        NOT NULL REFERENCES public.profiles(id),
  action_type  text        NOT NULL CHECK (action_type IN (
    'user_invited', 'user_deactivated', 'user_reactivated', 'user_removed',
    'invitation_revoked', 'post_deleted', 'comment_deleted',
    'flag_resolved_deleted', 'flag_resolved_dismissed',
    'content_pinned', 'content_unpinned', 'attendance_recorded', 'poll_closed'
  )),
  target_type  text        CHECK (target_type IN (
    'user', 'post', 'comment', 'flag', 'announcement', 'attendance', 'poll', 'invitation'
  ) OR target_type IS NULL),
  target_id    uuid,
  metadata     jsonb,
  performed_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX idx_audit_admin ON public.admin_audit_log (admin_id, performed_at DESC);
CREATE INDEX idx_audit_performed ON public.admin_audit_log (performed_at DESC);

ALTER TABLE public.admin_audit_log ENABLE ROW LEVEL SECURITY;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.admin_audit_log TO authenticated;
GRANT SELECT ON public.admin_audit_log TO anon;


-- ========== 20260620000070_create_admin_audit_log_rls_policies.sql ==========

-- Migration 070: RLS policies for admin_audit_log (4 policies)
-- Fully immutable â€” no client can INSERT, UPDATE, or DELETE

CREATE POLICY admin_audit_log_select_admin ON public.admin_audit_log
  FOR SELECT USING (auth.uid() IS NOT NULL AND is_admin());

CREATE POLICY admin_audit_log_insert_blocked ON public.admin_audit_log
  FOR INSERT WITH CHECK (false);

CREATE POLICY admin_audit_log_update_blocked ON public.admin_audit_log
  FOR UPDATE USING (false);

CREATE POLICY admin_audit_log_delete_blocked ON public.admin_audit_log
  FOR DELETE USING (false);


-- ========== 20260621000001_grant_service_role_access.sql ==========

-- Migration: Grant service_role access to all public tables
-- The service_role user bypasses RLS but still needs table-level GRANTs.
-- Supabase's default roles.sql grants to existing tables at init time,
-- but tables created by subsequent migrations don't inherit those grants.
-- This migration ensures service_role (used by Edge Functions via
-- createAdminClient) can access all current and future public tables.

GRANT ALL ON ALL TABLES IN SCHEMA public TO service_role;
GRANT ALL ON ALL SEQUENCES IN SCHEMA public TO service_role;

-- Ensure future tables also get the grant automatically
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON TABLES TO service_role;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON SEQUENCES TO service_role;


-- ========== 20260624000001_configure_storage_buckets.sql ==========

-- REM-01: Storage Bucket RLS Configuration
-- Creates avatars (public) and post-images (private) buckets with secure policies.

-- Step 1: Create buckets
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES ('avatars', 'avatars', true, 2097152, ARRAY['image/jpeg','image/png','image/webp'])
ON CONFLICT (id) DO NOTHING;

INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES ('post-images', 'post-images', false, 5242880, ARRAY['image/jpeg','image/png','image/webp','image/gif'])
ON CONFLICT (id) DO NOTHING;

-- Step 2: Avatars policies (public bucket)

-- Anyone can view avatars (public read)
CREATE POLICY "avatars_public_read"
ON storage.objects FOR SELECT
USING (bucket_id = 'avatars');

-- Authenticated users can upload to their own folder only
CREATE POLICY "avatars_auth_insert"
ON storage.objects FOR INSERT
WITH CHECK (
  bucket_id = 'avatars'
  AND auth.role() = 'authenticated'
  AND auth.uid()::text = (storage.foldername(name))[1]
);

-- Owner can update their own avatar
CREATE POLICY "avatars_auth_update"
ON storage.objects FOR UPDATE
USING (
  bucket_id = 'avatars'
  AND auth.uid()::text = (storage.foldername(name))[1]
);

-- Owner can delete their own avatar
CREATE POLICY "avatars_auth_delete"
ON storage.objects FOR DELETE
USING (
  bucket_id = 'avatars'
  AND auth.uid()::text = (storage.foldername(name))[1]
);

-- Step 3: Post-images policies (private bucket)

-- Authenticated members can view post images
CREATE POLICY "postimages_auth_read"
ON storage.objects FOR SELECT
USING (
  bucket_id = 'post-images'
  AND auth.role() = 'authenticated'
);

-- Authenticated users can upload to their own folder only
CREATE POLICY "postimages_auth_insert"
ON storage.objects FOR INSERT
WITH CHECK (
  bucket_id = 'post-images'
  AND auth.role() = 'authenticated'
  AND auth.uid()::text = (storage.foldername(name))[1]
);

-- Owner can update their own images
CREATE POLICY "postimages_auth_update"
ON storage.objects FOR UPDATE
USING (
  bucket_id = 'post-images'
  AND auth.uid()::text = (storage.foldername(name))[1]
);

-- Owner can delete their own images
CREATE POLICY "postimages_auth_delete"
ON storage.objects FOR DELETE
USING (
  bucket_id = 'post-images'
  AND auth.uid()::text = (storage.foldername(name))[1]
);


-- ========== 20260624000002_enable_realtime_replication.sql ==========

-- REM-06: Enable Realtime Replication on 8 Tables
-- Supabase Realtime requires explicit publication membership.

ALTER PUBLICATION supabase_realtime ADD TABLE posts;
ALTER PUBLICATION supabase_realtime ADD TABLE notification_inbox;
ALTER PUBLICATION supabase_realtime ADD TABLE post_reactions;
ALTER PUBLICATION supabase_realtime ADD TABLE comments;
ALTER PUBLICATION supabase_realtime ADD TABLE activity_rsvps;
ALTER PUBLICATION supabase_realtime ADD TABLE poll_votes;
ALTER PUBLICATION supabase_realtime ADD TABLE progress_logs;
ALTER PUBLICATION supabase_realtime ADD TABLE recognitions;


-- ========== 20260620000071_create_member_rankings_view.sql ==========

-- Migration 071: Create member_rankings view
-- Used by rankings_screen.dart for leaderboard display

CREATE OR REPLACE VIEW public.member_rankings AS
SELECT
  ROW_NUMBER() OVER (ORDER BY s.composite_score DESC) AS rank,
  s.user_id,
  p.full_name,
  p.title,
  s.composite_score,
  s.stat_month
FROM (
  SELECT DISTINCT ON (user_id)
    user_id,
    composite_score,
    stat_month
  FROM public.member_monthly_stats
  ORDER BY user_id, stat_month DESC
) s
JOIN public.profiles p ON p.id = s.user_id
WHERE p.is_active = true AND p.is_system_account = false;

GRANT SELECT ON public.member_rankings TO authenticated;
GRANT SELECT ON public.member_rankings TO anon;


-- ========== seed.sql (Connect Buddy system account) ==========

-- Connect Buddy system account
-- UUID: 00000000-0000-4000-8000-000000000001
-- Matches: _shared/constants.ts CONNECT_BUDDY_PROFILE_ID
-- Matches: app_constants.dart connectBuddySystemAccountId

-- Step 1: Create auth.users entry (required FK for profiles.id â†’ auth.users.id)
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

