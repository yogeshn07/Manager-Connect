-- Migration 035: Create poll_votes table
-- Domain: Events — append-only, no updated_at, no trigger
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
