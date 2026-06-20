-- Migration 042: Attach updated_at trigger to challenges

CREATE TRIGGER set_challenges_updated_at
  BEFORE UPDATE ON public.challenges
  FOR EACH ROW
  EXECUTE FUNCTION public.update_updated_at_column();
