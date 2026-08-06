-- Migration 072: Add parent_comment_id for threaded replies
ALTER TABLE public.comments
  ADD COLUMN IF NOT EXISTS parent_comment_id uuid REFERENCES public.comments(id) ON DELETE CASCADE;

CREATE INDEX IF NOT EXISTS idx_comments_parent ON public.comments (parent_comment_id);
