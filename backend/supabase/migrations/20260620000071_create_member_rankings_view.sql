-- Migration 071: Create member_rankings view
-- Used by rankings_screen.dart for leaderboard display

CREATE OR REPLACE VIEW public.member_rankings AS
SELECT
  ROW_NUMBER() OVER (ORDER BY s.composite_score DESC) AS rank,
  s.user_id,
  p.full_name,
  p.title,
  s.composite_score,
  s.stat_month
FROM (
  SELECT DISTINCT ON (user_id)
    user_id,
    composite_score,
    stat_month
  FROM public.member_monthly_stats
  ORDER BY user_id, stat_month DESC
) s
JOIN public.profiles p ON p.id = s.user_id
WHERE p.is_active = true AND p.is_system_account = false;

GRANT SELECT ON public.member_rankings TO authenticated;
GRANT SELECT ON public.member_rankings TO anon;
