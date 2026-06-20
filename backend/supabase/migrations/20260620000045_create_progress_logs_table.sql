-- Migration 045: Create progress_logs table
-- Domain: Growth — mutable (upsert on same day), has updated_at trigger
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
