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
