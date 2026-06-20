-- Migration 020: Create post_mentions table
-- Domain: Feed — append-only, no updated_at, no trigger
-- 4 columns, 2 FKs, 1 UNIQUE, 1 index

CREATE TABLE public.post_mentions (
  id                uuid        NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  post_id           uuid        NOT NULL REFERENCES public.posts(id) ON DELETE CASCADE,
  mentioned_user_id uuid        NOT NULL REFERENCES public.profiles(id),
  created_at        timestamptz NOT NULL DEFAULT now(),
  UNIQUE (post_id, mentioned_user_id)
);

CREATE INDEX idx_mentions_user ON public.post_mentions (mentioned_user_id);

ALTER TABLE public.post_mentions ENABLE ROW LEVEL SECURITY;

GRANT SELECT, INSERT, UPDATE, DELETE ON public.post_mentions TO authenticated;
GRANT SELECT ON public.post_mentions TO anon;
