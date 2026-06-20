-- Migration 028: Create activity_updates table
-- Domain: Events — append-only, no updated_at, no trigger
-- 5 columns, 2 FKs, 1 index

CREATE TABLE public.activity_updates (
  id          uuid        NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  activity_id uuid        NOT NULL REFERENCES public.activities(id) ON DELETE CASCADE,
  author_id   uuid        NOT NULL REFERENCES public.profiles(id),
  content     text        NOT NULL,
  created_at  timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX idx_activity_updates_activity ON public.activity_updates (activity_id, created_at ASC);

ALTER TABLE public.activity_updates ENABLE ROW LEVEL SECURITY;

GRANT SELECT, INSERT, UPDATE, DELETE ON public.activity_updates TO authenticated;
GRANT SELECT ON public.activity_updates TO anon;
