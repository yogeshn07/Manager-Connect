-- Migration 010: Create posts table
-- Domain: Feed
-- 8 columns, 2 FKs (profiles), soft-delete trio, 2 indexes

CREATE TABLE public.posts (
  id          uuid        NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  author_id   uuid        NOT NULL REFERENCES public.profiles(id),
  content     text        NOT NULL,
  is_deleted  boolean     NOT NULL DEFAULT false,
  deleted_by  uuid        REFERENCES public.profiles(id),
  deleted_at  timestamptz,
  created_at  timestamptz NOT NULL DEFAULT now(),
  updated_at  timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX idx_posts_feed ON public.posts (created_at DESC) WHERE is_deleted = false;
CREATE INDEX idx_posts_author ON public.posts (author_id);

ALTER TABLE public.posts ENABLE ROW LEVEL SECURITY;

GRANT SELECT, INSERT, UPDATE, DELETE ON public.posts TO authenticated;
GRANT SELECT ON public.posts TO anon;
