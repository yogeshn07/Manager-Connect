-- Migration 002: Create shared updated_at trigger function
-- This function is attached to 16 of the 26 tables via subsequent migrations.
-- It sets updated_at = now() BEFORE each UPDATE operation.
-- Tables without this trigger are append-only or immutable (see schema design).

CREATE OR REPLACE FUNCTION public.update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;
