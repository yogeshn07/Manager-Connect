-- Migration 015: Create post_reactions table
-- Domain: Feed — mutable (emoji changes), has updated_at + trigger
-- 6 columns, 2 FKs, 1 UNIQUE, 1 index

CREATE TABLE public.post_reactions (
  id          uuid        NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  post_id     uuid        NOT NULL REFERENCES public.posts(id) ON DELETE CASCADE,
  user_id     uuid        NOT NULL REFERENCES public.profiles(id),
  emoji       text        NOT NULL,
  created_at  timestamptz NOT NULL DEFAULT now(),
  updated_at  timestamptz NOT NULL DEFAULT now(),
  UNIQUE (post_id, user_id)
);

CREATE INDEX idx_reactions_post ON public.post_reactions (post_id);

ALTER TABLE public.post_reactions ENABLE ROW LEVEL SECURITY;

GRANT SELECT, INSERT, UPDATE, DELETE ON public.post_reactions TO authenticated;
GRANT SELECT ON public.post_reactions TO anon;
