-- Challenge subtasks: allow Strava-style goal types + per-subtask progress tracking

-- 1. Drop the old goal_type CHECK constraint so new activity-style values are accepted
ALTER TABLE challenges DROP CONSTRAINT IF EXISTS challenges_goal_type_check;

-- 2. Add selected_tasks JSONB column to store the multiple sub-task selections made at
--    challenge creation time.
--    Each element: {"id":"w_10k","label":"10k Steps","target":10000.0,"unit":"steps"}
ALTER TABLE challenges
  ADD COLUMN IF NOT EXISTS selected_tasks JSONB NOT NULL DEFAULT '[]'::jsonb;

-- 3. Add subtask_id to progress_logs so each log entry is scoped to a specific sub-task.
--    Empty string '' is the default for legacy rows that predate this migration.
ALTER TABLE progress_logs
  ADD COLUMN IF NOT EXISTS subtask_id TEXT NOT NULL DEFAULT '';

-- 4. Replace the old per-day unique constraint with a new one that includes subtask_id,
--    allowing one entry per user per day per sub-task (not just per day per challenge).
ALTER TABLE progress_logs
  DROP CONSTRAINT IF EXISTS progress_logs_challenge_id_user_id_log_date_key;

ALTER TABLE progress_logs
  ADD CONSTRAINT progress_logs_challenge_user_date_subtask_key
  UNIQUE (challenge_id, user_id, log_date, subtask_id);
