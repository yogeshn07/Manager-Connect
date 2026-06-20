-- Migration 013: Create post_images table
-- Domain: Feed — append-only, no updated_at, no trigger
-- 5 columns, 1 FK (posts CASCADE), 1 CHECK, 1 index

CREATE TABLE public.post_images (
  id            uuid        NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  post_id       uuid        NOT NULL REFERENCES public.posts(id) ON DELETE CASCADE,
  storage_path  text        NOT NULL,
  display_order smallint    NOT NULL DEFAULT 0
                            CHECK (display_order >= 0 AND display_order <= 3),
  created_at    timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX idx_post_images_post ON public.post_images (post_id, display_order ASC);

ALTER TABLE public.post_images ENABLE ROW LEVEL SECURITY;

GRANT SELECT, INSERT, UPDATE, DELETE ON public.post_images TO authenticated;
GRANT SELECT ON public.post_images TO anon;
