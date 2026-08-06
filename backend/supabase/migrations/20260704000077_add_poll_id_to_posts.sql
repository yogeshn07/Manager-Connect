-- Migration 077: Add poll_id to posts for standalone feed polls
ALTER TABLE public.posts ADD COLUMN IF NOT EXISTS poll_id uuid REFERENCES public.polls(id) ON DELETE SET NULL;

CREATE INDEX IF NOT EXISTS idx_posts_poll_id ON public.posts (poll_id) WHERE poll_id IS NOT NULL;
