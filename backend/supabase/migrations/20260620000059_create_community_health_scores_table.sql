-- Migration 059: Create community_health_scores table
-- Domain: Analytics — service_role write only, NO updated_at (upserted, not updated)
-- 10 columns, no FKs, 6 CHECKs, 1 UNIQUE (score_month)

CREATE TABLE public.community_health_scores (
  id                       uuid          NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  score_month              date          NOT NULL UNIQUE,
  score                    numeric(5,2)  NOT NULL CHECK (score >= 0 AND score <= 100),
  active_member_count      integer       NOT NULL DEFAULT 0 CHECK (active_member_count >= 0),
  avg_attendance_rate      numeric(5,2)  NOT NULL DEFAULT 0.00 CHECK (avg_attendance_rate >= 0 AND avg_attendance_rate <= 100),
  challenge_engagement_rate numeric(5,2) NOT NULL DEFAULT 0.00 CHECK (challenge_engagement_rate >= 0 AND challenge_engagement_rate <= 100),
  recognition_activity_rate numeric(5,2) NOT NULL DEFAULT 0.00 CHECK (recognition_activity_rate >= 0 AND recognition_activity_rate <= 100),
  participation_rate       numeric(5,2)  NOT NULL DEFAULT 0.00 CHECK (participation_rate >= 0 AND participation_rate <= 100),
  computed_at              timestamptz   NOT NULL DEFAULT now(),
  created_at               timestamptz   NOT NULL DEFAULT now()
);

-- No additional indexes needed — UNIQUE(score_month) covers the primary query pattern

ALTER TABLE public.community_health_scores ENABLE ROW LEVEL SECURITY;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.community_health_scores TO authenticated;
GRANT SELECT ON public.community_health_scores TO anon;
