-- Migration 074: Saved posts — one row per user+post
CREATE TABLE IF NOT EXISTS public.saved_posts (
  id       uuid        NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id  uuid        NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  post_id  uuid        NOT NULL REFERENCES public.posts(id) ON DELETE CASCADE,
  saved_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE(user_id, post_id)
);

CREATE INDEX IF NOT EXISTS idx_saved_posts_user ON public.saved_posts (user_id, saved_at DESC);

ALTER TABLE public.saved_posts ENABLE ROW LEVEL SECURITY;

CREATE POLICY "saved_posts_own" ON public.saved_posts
  FOR ALL TO authenticated
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

GRANT SELECT, INSERT, DELETE ON public.saved_posts TO authenticated;
