-- Migration 043: Create challenge_participants table
-- Domain: Growth — append-only, no updated_at, no trigger
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
