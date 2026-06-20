-- Migration 066: Create pinned_announcements table
-- Domain: Admin
-- 6 columns, 2 FKs, 1 index (partial), has updated_at trigger

CREATE TABLE public.pinned_announcements (
  id         uuid        NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  post_id    uuid        NOT NULL REFERENCES public.posts(id) ON DELETE CASCADE,
  pinned_by  uuid        NOT NULL REFERENCES public.profiles(id),
  is_active  boolean     NOT NULL DEFAULT true,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX idx_pinned_active ON public.pinned_announcements (is_active) WHERE is_active = true;

ALTER TABLE public.pinned_announcements ENABLE ROW LEVEL SECURITY;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.pinned_announcements TO authenticated;
GRANT SELECT ON public.pinned_announcements TO anon;
