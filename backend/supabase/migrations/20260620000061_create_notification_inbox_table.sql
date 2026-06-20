-- Migration 061: Create notification_inbox table
-- Domain: Notifications — append-only for content, no updated_at trigger
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
