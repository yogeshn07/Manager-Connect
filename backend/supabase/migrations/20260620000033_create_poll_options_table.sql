-- Migration 033: Create poll_options table
-- Domain: Events — append-only, no updated_at, no trigger
-- 5 columns, 1 FK (CASCADE), 1 CHECK, 1 index

CREATE TABLE public.poll_options (
  id            uuid        NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  poll_id       uuid        NOT NULL REFERENCES public.polls(id) ON DELETE CASCADE,
  option_text   text        NOT NULL,
  display_order smallint    NOT NULL DEFAULT 0 CHECK (display_order >= 0),
  created_at    timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX idx_poll_options_poll ON public.poll_options (poll_id, display_order ASC);

ALTER TABLE public.poll_options ENABLE ROW LEVEL SECURITY;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.poll_options TO authenticated;
GRANT SELECT ON public.poll_options TO anon;
