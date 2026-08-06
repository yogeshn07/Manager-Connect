-- Migration 073: Add post_type to posts for feed filter support
ALTER TABLE public.posts
  ADD COLUMN IF NOT EXISTS post_type text NOT NULL DEFAULT 'post';

CREATE INDEX IF NOT EXISTS idx_posts_type ON public.posts (post_type)
  WHERE is_deleted = false;
