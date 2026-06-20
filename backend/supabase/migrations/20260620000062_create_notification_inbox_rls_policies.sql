-- Migration 062: RLS policies for notification_inbox (4 policies)

CREATE POLICY notification_inbox_select_own ON public.notification_inbox
  FOR SELECT USING (
    auth.uid() IS NOT NULL AND is_active_user()
    AND recipient_id = auth.uid()
  );

CREATE POLICY notification_inbox_insert_blocked ON public.notification_inbox
  FOR INSERT WITH CHECK (false);

CREATE POLICY notification_inbox_update_own ON public.notification_inbox
  FOR UPDATE USING (
    auth.uid() IS NOT NULL AND is_active_user()
    AND recipient_id = auth.uid()
  );

CREATE POLICY notification_inbox_delete_blocked ON public.notification_inbox
  FOR DELETE USING (false);
