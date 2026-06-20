-- Migration 055: Attach updated_at trigger to recognition_reactions

CREATE TRIGGER set_recognition_reactions_updated_at
  BEFORE UPDATE ON public.recognition_reactions
  FOR EACH ROW
  EXECUTE FUNCTION public.update_updated_at_column();
