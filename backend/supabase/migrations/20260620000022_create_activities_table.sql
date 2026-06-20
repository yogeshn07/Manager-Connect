-- Migration 022: Create activities table
-- Domain: Events
-- 13 columns, 1 FK (profiles), 3 CHECKs, 3 indexes

CREATE TABLE public.activities (
  id             uuid        NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  created_by     uuid        NOT NULL REFERENCES public.profiles(id),
  title          text        NOT NULL,
  description    text,
  event_category text        NOT NULL DEFAULT 'outings'
                             CHECK (event_category IN ('games', 'outings', 'social_connect')),
  event_type     text        CHECK (event_type IN ('cricket', 'badminton', 'pickleball', 'table_tennis',
                                                    'coffee_connect', 'lunch_meetup', 'dinner_meetup', 'other')
                                    OR event_type IS NULL),
  location       text,
  event_date     timestamptz NOT NULL,
  cost_note      text,
  status         text        NOT NULL DEFAULT 'active'
                             CHECK (status IN ('active', 'cancelled')),
  cancelled_at   timestamptz,
  created_at     timestamptz NOT NULL DEFAULT now(),
  updated_at     timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX idx_activities_date ON public.activities (event_date ASC) WHERE status = 'active';
CREATE INDEX idx_activities_creator ON public.activities (created_by);
CREATE INDEX idx_activities_category ON public.activities (event_category);

ALTER TABLE public.activities ENABLE ROW LEVEL SECURITY;

GRANT SELECT, INSERT, UPDATE, DELETE ON public.activities TO authenticated;
GRANT SELECT ON public.activities TO anon;
