-- Migration 057: RLS policies for member_monthly_stats (4 policies)
-- All writes blocked for clients — service_role only (compute-monthly-stats EF)

CREATE POLICY member_monthly_stats_select_authenticated ON public.member_monthly_stats
  FOR SELECT USING (auth.uid() IS NOT NULL AND is_active_user());

CREATE POLICY member_monthly_stats_insert_blocked ON public.member_monthly_stats
  FOR INSERT WITH CHECK (false);

CREATE POLICY member_monthly_stats_update_blocked ON public.member_monthly_stats
  FOR UPDATE USING (false);

CREATE POLICY member_monthly_stats_delete_blocked ON public.member_monthly_stats
  FOR DELETE USING (false);
