-- Migration 025: Create activity_rsvps table
-- Domain: Events
-- 6 columns, 2 FKs, 1 CHECK, 1 UNIQUE, 2 indexes

CREATE TABLE public.activity_rsvps (
  id          uuid        NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  activity_id uuid        NOT NULL REFERENCES public.activities(id) ON DELETE CASCADE,
  user_id     uuid        NOT NULL REFERENCES public.profiles(id),
  status      text        NOT NULL CHECK (status IN ('going', 'not_going', 'maybe')),
  created_at  timestamptz NOT NULL DEFAULT now(),
  updated_at  timestamptz NOT NULL DEFAULT now(),
  UNIQUE (activity_id, user_id)
);

CREATE INDEX idx_rsvps_activity ON public.activity_rsvps (activity_id);
CREATE INDEX idx_rsvps_user ON public.activity_rsvps (user_id);

ALTER TABLE public.activity_rsvps ENABLE ROW LEVEL SECURITY;

GRANT SELECT, INSERT, UPDATE, DELETE ON public.activity_rsvps TO authenticated;
GRANT SELECT ON public.activity_rsvps TO anon;
