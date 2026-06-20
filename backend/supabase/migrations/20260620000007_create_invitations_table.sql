-- Migration 007: Create invitations table
-- Domain: Identity
-- 11 columns, 2 FKs (profiles), 1 CHECK, 1 UNIQUE, 2 indexes
-- RLS enabled immediately on creation

CREATE TABLE public.invitations (
  id              uuid        NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  invitee_name    text        NOT NULL,
  invitee_email   text,
  invitee_phone   text,
  token_hash      text        NOT NULL UNIQUE,
  status          text        NOT NULL DEFAULT 'pending'
                              CHECK (status IN ('pending', 'accepted', 'expired', 'revoked')),
  invited_by      uuid        NOT NULL REFERENCES public.profiles(id),
  accepted_by     uuid        REFERENCES public.profiles(id),
  expires_at      timestamptz NOT NULL,
  created_at      timestamptz NOT NULL DEFAULT now(),
  updated_at      timestamptz NOT NULL DEFAULT now()
);

-- Indexes
CREATE INDEX idx_invitations_token ON public.invitations (token_hash);
CREATE INDEX idx_invitations_status ON public.invitations (status) WHERE status = 'pending';

-- Enable RLS immediately
ALTER TABLE public.invitations ENABLE ROW LEVEL SECURITY;

-- Grant access to Supabase roles (RLS policies control actual row visibility)
GRANT SELECT, INSERT, UPDATE, DELETE ON public.invitations TO authenticated;
GRANT SELECT ON public.invitations TO anon;
