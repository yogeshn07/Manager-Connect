-- Migration 048: Create recognitions table
-- Domain: Recognition
-- 9 columns, 2 FKs, 1 CHECK, soft-delete, 2 indexes, has updated_at trigger

CREATE TABLE public.recognitions (
  id           uuid        NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  giver_id     uuid        NOT NULL REFERENCES public.profiles(id),
  category_tag text        NOT NULL CHECK (category_tag IN (
    'community_contributor', 'fitness_champion', 'wellness_champion',
    'event_champion', 'most_supportive_manager'
  )),
  message      text        NOT NULL,
  is_deleted   boolean     NOT NULL DEFAULT false,
  deleted_by   uuid        REFERENCES public.profiles(id),
  deleted_at   timestamptz,
  created_at   timestamptz NOT NULL DEFAULT now(),
  updated_at   timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX idx_recognitions_feed ON public.recognitions (created_at DESC) WHERE is_deleted = false;
CREATE INDEX idx_recognitions_giver ON public.recognitions (giver_id);

ALTER TABLE public.recognitions ENABLE ROW LEVEL SECURITY;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.recognitions TO authenticated;
GRANT SELECT ON public.recognitions TO anon;
