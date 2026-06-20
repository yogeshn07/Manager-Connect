-- Migration 009: Attach updated_at trigger to invitations
-- Uses the shared update_updated_at_column() function from migration 002

CREATE TRIGGER set_invitations_updated_at
  BEFORE UPDATE ON public.invitations
  FOR EACH ROW
  EXECUTE FUNCTION public.update_updated_at_column();
