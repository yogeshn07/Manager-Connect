-- Migration 026: RLS policies for activity_rsvps (4 policies)

CREATE POLICY activity_rsvps_select_authenticated ON public.activity_rsvps
  FOR SELECT USING (
    auth.uid() IS NOT NULL AND is_active_user()
  );

CREATE POLICY activity_rsvps_insert_own ON public.activity_rsvps
  FOR INSERT WITH CHECK (
    auth.uid() IS NOT NULL AND is_active_user()
    AND user_id = auth.uid()
  );

CREATE POLICY activity_rsvps_update_own ON public.activity_rsvps
  FOR UPDATE USING (
    auth.uid() IS NOT NULL AND is_active_user()
    AND user_id = auth.uid()
  );

CREATE POLICY activity_rsvps_delete_own ON public.activity_rsvps
  FOR DELETE USING (
    auth.uid() IS NOT NULL AND is_active_user()
    AND user_id = auth.uid()
  );
