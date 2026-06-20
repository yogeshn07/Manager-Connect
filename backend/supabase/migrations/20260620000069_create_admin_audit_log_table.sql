-- Migration 069: Create admin_audit_log table
-- Domain: Admin — IMMUTABLE: no updated_at, no created_at, no trigger
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
