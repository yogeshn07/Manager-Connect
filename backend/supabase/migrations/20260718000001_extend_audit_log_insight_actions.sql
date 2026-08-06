-- Migration 20260718000001: Extend admin_audit_log for Catalyst Insights review actions
-- Feature: Catalyst Insights — Admin Review Workflow (S3-BE-005)
-- Depends on: 20260620000069_create_admin_audit_log_table
--
-- Extends the CHECK constraints on admin_audit_log to accommodate Catalyst Insights
-- review actions written by the review-insight Edge Function (S3-BE-005):
--   action_type IN ('insight_approved', 'insight_rejected')
--   target_type = 'insight'
--
-- DDL strategy: DROP + ADD CONSTRAINT is the only way to modify a PostgreSQL CHECK.
-- Acquires ACCESS EXCLUSIVE briefly; all original values are preserved in the new constraint.
-- Auto-generated constraint names follow PostgreSQL convention: {table}_{column}_check.

-- ─── action_type: add insight_approved, insight_rejected ──────────────────────

ALTER TABLE public.admin_audit_log
  DROP CONSTRAINT admin_audit_log_action_type_check;

ALTER TABLE public.admin_audit_log
  ADD CONSTRAINT admin_audit_log_action_type_check
  CHECK (action_type IN (
    'user_invited',
    'user_deactivated',
    'user_reactivated',
    'user_removed',
    'invitation_revoked',
    'post_deleted',
    'comment_deleted',
    'flag_resolved_deleted',
    'flag_resolved_dismissed',
    'content_pinned',
    'content_unpinned',
    'attendance_recorded',
    'poll_closed',
    -- Catalyst Insights review actions (S3-BE-005)
    'insight_approved',
    'insight_rejected'
  ));

-- ─── target_type: add insight ─────────────────────────────────────────────────

ALTER TABLE public.admin_audit_log
  DROP CONSTRAINT admin_audit_log_target_type_check;

ALTER TABLE public.admin_audit_log
  ADD CONSTRAINT admin_audit_log_target_type_check
  CHECK (target_type IN (
    'user',
    'post',
    'comment',
    'flag',
    'announcement',
    'attendance',
    'poll',
    'invitation',
    -- Catalyst Insights (S3-BE-005)
    'insight'
  ) OR target_type IS NULL);
