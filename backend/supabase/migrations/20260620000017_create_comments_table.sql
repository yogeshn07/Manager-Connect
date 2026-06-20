-- Migration 017: Create comments table
-- Domain: Feed — mutable, soft-delete, has updated_at + trigger
-- 9 columns, 3 FKs, 1 index

CREATE TABLE public.comments (
  id          uuid        NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  post_id     uuid        NOT NULL REFERENCES public.posts(id) ON DELETE CASCADE,
  author_id   uuid        NOT NULL REFERENCES public.profiles(id),
  content     text        NOT NULL,
  is_deleted  boolean     NOT NULL DEFAULT false,
  deleted_by  uuid        REFERENCES public.profiles(id),
  deleted_at  timestamptz,
  created_at  timestamptz NOT NULL DEFAULT now(),
  updated_at  timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX idx_comments_post ON public.comments (post_id, created_at ASC);

ALTER TABLE public.comments ENABLE ROW LEVEL SECURITY;

GRANT SELECT, INSERT, UPDATE, DELETE ON public.comments TO authenticated;
GRANT SELECT ON public.comments TO anon;
