-- Migration 080: Notification dispatch triggers
-- Adds poll_created type + SECURITY DEFINER triggers for:
--   activity_created, challenge_created, poll_created, comment_on_post
-- Triggers run as postgres (superuser) via SECURITY DEFINER → bypass INSERT RLS

-- ── 1. Add poll_created to the type CHECK constraint ────────────────────────
ALTER TABLE public.notification_inbox
  DROP CONSTRAINT notification_inbox_type_check;

ALTER TABLE public.notification_inbox
  ADD CONSTRAINT notification_inbox_type_check CHECK (type IN (
    'activity_created', 'activity_reminder_24h', 'activity_reminder_1h',
    'activity_cancelled', 'activity_updated',
    'poll_reminder', 'poll_created',
    'recognition_received',
    'challenge_created', 'challenge_ending', 'challenge_ended',
    'mention', 'comment_on_post',
    'connect_buddy_update', 'admin_flag', 'admin_member_registered'
  ));

-- ── 2. New event created → notify all active members ────────────────────────
CREATE OR REPLACE FUNCTION public.notify_on_activity_created()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  INSERT INTO notification_inbox (
    recipient_id, actor_id, type, title, body, reference_type, reference_id
  )
  SELECT
    p.id,
    NEW.created_by,
    'activity_created',
    'New Event: ' || NEW.title,
    'A new event has been added to the calendar. Tap to view & RSVP!',
    'activity',
    NEW.id
  FROM profiles p
  WHERE p.is_active = TRUE
    AND p.onboarding_completed = TRUE
    AND p.is_system_account = FALSE
    AND p.id != NEW.created_by
    AND COALESCE((p.notification_preferences->>'new_activities')::boolean, TRUE) = TRUE;

  RETURN NEW;
EXCEPTION WHEN OTHERS THEN
  RETURN NEW;
END;
$$;

CREATE TRIGGER trg_notify_activity_created
  AFTER INSERT ON public.activities
  FOR EACH ROW
  EXECUTE FUNCTION public.notify_on_activity_created();

-- ── 3. New challenge created → notify all active members ────────────────────
CREATE OR REPLACE FUNCTION public.notify_on_challenge_created()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  INSERT INTO notification_inbox (
    recipient_id, actor_id, type, title, body, reference_type, reference_id
  )
  SELECT
    p.id,
    NEW.created_by,
    'challenge_created',
    'New Challenge: ' || NEW.title,
    'A new ' || NEW.challenge_type || ' challenge has started. Join now!',
    'challenge',
    NEW.id
  FROM profiles p
  WHERE p.is_active = TRUE
    AND p.onboarding_completed = TRUE
    AND p.is_system_account = FALSE
    AND p.id != NEW.created_by
    AND COALESCE((p.notification_preferences->>'new_challenges')::boolean, TRUE) = TRUE;

  RETURN NEW;
EXCEPTION WHEN OTHERS THEN
  RETURN NEW;
END;
$$;

CREATE TRIGGER trg_notify_challenge_created
  AFTER INSERT ON public.challenges
  FOR EACH ROW
  EXECUTE FUNCTION public.notify_on_challenge_created();

-- ── 4. New poll post created → notify all active members ────────────────────
CREATE OR REPLACE FUNCTION public.notify_on_poll_post_created()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  INSERT INTO notification_inbox (
    recipient_id, actor_id, type, title, body, reference_type, reference_id
  )
  SELECT
    p.id,
    NEW.author_id,
    'poll_created',
    'New Poll — Cast Your Vote!',
    '📊 ' || LEFT(NEW.content, 100),
    'post',
    NEW.id
  FROM profiles p
  WHERE p.is_active = TRUE
    AND p.onboarding_completed = TRUE
    AND p.is_system_account = FALSE
    AND p.id != NEW.author_id
    AND COALESCE((p.notification_preferences->>'poll_reminders')::boolean, TRUE) = TRUE;

  RETURN NEW;
EXCEPTION WHEN OTHERS THEN
  RETURN NEW;
END;
$$;

-- WHEN clause ensures function only fires for poll posts
CREATE TRIGGER trg_notify_poll_post_created
  AFTER INSERT ON public.posts
  FOR EACH ROW
  WHEN (NEW.post_type = 'poll' AND NEW.is_deleted = FALSE)
  EXECUTE FUNCTION public.notify_on_poll_post_created();

-- ── 5. New comment → notify post author ─────────────────────────────────────
CREATE OR REPLACE FUNCTION public.notify_on_comment_created()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_post_author_id uuid;
  v_commenter_name text;
BEGIN
  -- Skip soft-deleted inserts
  IF NEW.is_deleted THEN
    RETURN NEW;
  END IF;

  -- Resolve post author (skip if post is deleted)
  SELECT author_id INTO v_post_author_id
  FROM posts
  WHERE id = NEW.post_id AND is_deleted = FALSE;

  -- Skip if post not found or commenter is the post author
  IF v_post_author_id IS NULL OR v_post_author_id = NEW.author_id THEN
    RETURN NEW;
  END IF;

  -- Resolve commenter display name
  SELECT full_name INTO v_commenter_name
  FROM profiles WHERE id = NEW.author_id;

  -- Notify post author if they want comment notifications and are still active
  INSERT INTO notification_inbox (
    recipient_id, actor_id, type, title, body, reference_type, reference_id
  )
  SELECT
    v_post_author_id,
    NEW.author_id,
    'comment_on_post',
    COALESCE(v_commenter_name, 'Someone') || ' commented on your post',
    '💬 ' || LEFT(NEW.content, 100),
    'post',
    NEW.post_id
  FROM profiles p
  WHERE p.id = v_post_author_id
    AND p.is_active = TRUE
    AND COALESCE((p.notification_preferences->>'comments_on_my_posts')::boolean, TRUE) = TRUE;

  RETURN NEW;
EXCEPTION WHEN OTHERS THEN
  RETURN NEW;
END;
$$;

CREATE TRIGGER trg_notify_comment_created
  AFTER INSERT ON public.comments
  FOR EACH ROW
  EXECUTE FUNCTION public.notify_on_comment_created();
