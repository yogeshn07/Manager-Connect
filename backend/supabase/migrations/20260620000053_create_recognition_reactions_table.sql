-- Migration 053: Create recognition_reactions table
-- Domain: Recognition — mutable (emoji changes), has updated_at trigger
-- 6 columns, 2 FKs, 1 UNIQUE, 1 index

CREATE TABLE public.recognition_reactions (
  id             uuid        NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  recognition_id uuid        NOT NULL REFERENCES public.recognitions(id) ON DELETE CASCADE,
  user_id        uuid        NOT NULL REFERENCES public.profiles(id),
  emoji          text        NOT NULL,
  created_at     timestamptz NOT NULL DEFAULT now(),
  updated_at     timestamptz NOT NULL DEFAULT now(),
  UNIQUE (recognition_id, user_id)
);

CREATE INDEX idx_recog_reactions_recognition ON public.recognition_reactions (recognition_id);

ALTER TABLE public.recognition_reactions ENABLE ROW LEVEL SECURITY;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.recognition_reactions TO authenticated;
GRANT SELECT ON public.recognition_reactions TO anon;
