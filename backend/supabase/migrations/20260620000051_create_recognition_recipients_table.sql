-- Migration 051: Create recognition_recipients table
-- Domain: Recognition — append-only, no updated_at, no trigger
-- 4 columns, 2 FKs, 1 UNIQUE, 2 indexes

CREATE TABLE public.recognition_recipients (
  id             uuid        NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  recognition_id uuid        NOT NULL REFERENCES public.recognitions(id) ON DELETE CASCADE,
  recipient_id   uuid        NOT NULL REFERENCES public.profiles(id),
  created_at     timestamptz NOT NULL DEFAULT now(),
  UNIQUE (recognition_id, recipient_id)
);

CREATE INDEX idx_recipients_recognition ON public.recognition_recipients (recognition_id);
CREATE INDEX idx_recipients_user ON public.recognition_recipients (recipient_id);

ALTER TABLE public.recognition_recipients ENABLE ROW LEVEL SECURITY;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.recognition_recipients TO authenticated;
GRANT SELECT ON public.recognition_recipients TO anon;
