-- Migration 016b: Attach updated_at trigger to post_reactions

CREATE TRIGGER set_post_reactions_updated_at
  BEFORE UPDATE ON public.post_reactions
  FOR EACH ROW
  EXECUTE FUNCTION public.update_updated_at_column();
