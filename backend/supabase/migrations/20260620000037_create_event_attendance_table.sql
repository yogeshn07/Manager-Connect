-- Migration 037: Create event_attendance table
-- Domain: Events — mutable (admin corrections), has updated_at trigger
-- 8 columns, 3 FKs, 1 CHECK, 1 UNIQUE, 2 indexes

CREATE TABLE public.event_attendance (
  id          uuid        NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  activity_id uuid        NOT NULL REFERENCES public.activities(id) ON DELETE CASCADE,
  user_id     uuid        NOT NULL REFERENCES public.profiles(id),
  status      text        NOT NULL CHECK (status IN ('attended', 'absent')),
  recorded_by uuid        NOT NULL REFERENCES public.profiles(id),
  recorded_at timestamptz NOT NULL DEFAULT now(),
  created_at  timestamptz NOT NULL DEFAULT now(),
  updated_at  timestamptz NOT NULL DEFAULT now(),
  UNIQUE (activity_id, user_id)
);

CREATE INDEX idx_attendance_activity ON public.event_attendance (activity_id);
CREATE INDEX idx_attendance_user ON public.event_attendance (user_id);

ALTER TABLE public.event_attendance ENABLE ROW LEVEL SECURITY;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.event_attendance TO authenticated;
GRANT SELECT ON public.event_attendance TO anon;
