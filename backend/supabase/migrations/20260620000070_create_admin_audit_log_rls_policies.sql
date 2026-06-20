-- Migration 070: RLS policies for admin_audit_log (4 policies)
-- Fully immutable — no client can INSERT, UPDATE, or DELETE

CREATE POLICY admin_audit_log_select_admin ON public.admin_audit_log
  FOR SELECT USING (auth.uid() IS NOT NULL AND is_admin());

CREATE POLICY admin_audit_log_insert_blocked ON public.admin_audit_log
  FOR INSERT WITH CHECK (false);

CREATE POLICY admin_audit_log_update_blocked ON public.admin_audit_log
  FOR UPDATE USING (false);

CREATE POLICY admin_audit_log_delete_blocked ON public.admin_audit_log
  FOR DELETE USING (false);
