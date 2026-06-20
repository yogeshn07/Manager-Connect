-- Migration 050: Attach updated_at trigger to recognitions

CREATE TRIGGER set_recognitions_updated_at
  BEFORE UPDATE ON public.recognitions
  FOR EACH ROW
  EXECUTE FUNCTION public.update_updated_at_column();
