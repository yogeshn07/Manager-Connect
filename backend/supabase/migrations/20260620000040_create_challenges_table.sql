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
