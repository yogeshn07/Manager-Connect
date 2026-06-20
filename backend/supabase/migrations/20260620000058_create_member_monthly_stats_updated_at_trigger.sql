-- Migration 058: Attach updated_at trigger to member_monthly_stats

CREATE TRIGGER set_member_monthly_stats_updated_at
  BEFORE UPDATE ON public.member_monthly_stats
  FOR EACH ROW
  EXECUTE FUNCTION public.update_updated_at_column();
