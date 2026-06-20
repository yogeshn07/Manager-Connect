-- Migration 052: RLS policies for recognition_recipients (4 policies)
-- INSERT uses subquery to verify caller is the recognition giver

CREATE POLICY recognition_recipients_select_authenticated ON public.recognition_recipients
  FOR SELECT USING (auth.uid() IS NOT NULL AND is_active_user());

CREATE POLICY recognition_recipients_insert_own ON public.recognition_recipients
  FOR INSERT WITH CHECK (
    auth.uid() IS NOT NULL AND is_active_user()
    AND recognition_id IN (
      SELECT id FROM public.recognitions WHERE giver_id = auth.uid()
    )
  );

CREATE POLICY recognition_recipients_update_blocked ON public.recognition_recipients
  FOR UPDATE USING (false);

CREATE POLICY recognition_recipients_delete_blocked ON public.recognition_recipients
  FOR DELETE USING (false);
