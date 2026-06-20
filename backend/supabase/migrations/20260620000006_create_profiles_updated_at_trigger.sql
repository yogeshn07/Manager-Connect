-- Migration 006: Attach updated_at trigger to profiles
-- Uses the shared update_updated_at_column() function from migration 002

CREATE TRIGGER set_profiles_updated_at
  BEFORE UPDATE ON public.profiles
  FOR EACH ROW
  EXECUTE FUNCTION public.update_updated_at_column();
