-- Migration 063: Create flagged_content table
-- Domain: Admin
-- 10 columns, 2 FKs, 2 CHECKs, 1 index (partial), has updated_at trigger

CREATE TABLE public.flagged_content (
  id           uuid        NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  reporter_id  uuid        NOT NULL REFERENCES public.profiles(id),
  content_type text        NOT NULL CHECK (content_type IN ('post', 'comment')),
  content_id   uuid        NOT NULL,
  reason       text,
  status       text        NOT NULL DEFAULT 'pending'
                           CHECK (status IN ('pending', 'resolved_deleted', 'resolved_dismissed')),
  resolved_by  uuid        REFERENCES public.profiles(id),
  resolved_at  timestamptz,
  created_at   timestamptz NOT NULL DEFAULT now(),
  updated_at   timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX idx_flags_status ON public.flagged_content (status) WHERE status = 'pending';

ALTER TABLE public.flagged_content ENABLE ROW LEVEL SECURITY;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.flagged_content TO authenticated;
GRANT SELECT ON public.flagged_content TO anon;
