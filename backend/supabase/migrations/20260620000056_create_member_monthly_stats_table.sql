-- Migration 056: Create member_monthly_stats table
-- Domain: Analytics — service_role write only, has updated_at trigger
-- 14 columns, 1 FK, 8 CHECKs, 1 UNIQUE, 2 indexes

CREATE TABLE public.member_monthly_stats (
  id                   uuid          NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id              uuid          NOT NULL REFERENCES public.profiles(id),
  stat_month           date          NOT NULL,
  events_attended      integer       NOT NULL DEFAULT 0 CHECK (events_attended >= 0),
  attendance_rate      numeric(5,2)  NOT NULL DEFAULT 0.00 CHECK (attendance_rate >= 0 AND attendance_rate <= 100),
  challenges_joined    integer       NOT NULL DEFAULT 0 CHECK (challenges_joined >= 0),
  progress_logs_count  integer       NOT NULL DEFAULT 0 CHECK (progress_logs_count >= 0),
  recognitions_received integer      NOT NULL DEFAULT 0 CHECK (recognitions_received >= 0),
  recognitions_given   integer       NOT NULL DEFAULT 0 CHECK (recognitions_given >= 0),
  posts_count          integer       NOT NULL DEFAULT 0 CHECK (posts_count >= 0),
  composite_score      numeric(6,2)  NOT NULL DEFAULT 0.00 CHECK (composite_score >= 0),
  computed_at          timestamptz   NOT NULL DEFAULT now(),
  created_at           timestamptz   NOT NULL DEFAULT now(),
  updated_at           timestamptz   NOT NULL DEFAULT now(),
  UNIQUE (user_id, stat_month)
);

CREATE INDEX idx_monthly_stats_user ON public.member_monthly_stats (user_id, stat_month DESC);
CREATE INDEX idx_monthly_stats_month ON public.member_monthly_stats (stat_month, composite_score DESC);

ALTER TABLE public.member_monthly_stats ENABLE ROW LEVEL SECURITY;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.member_monthly_stats TO authenticated;
GRANT SELECT ON public.member_monthly_stats TO anon;
