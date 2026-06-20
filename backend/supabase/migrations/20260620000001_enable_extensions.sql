-- Migration 001: Enable required PostgreSQL extensions
-- Extensions: uuid-ossp (UUID generation), pgcrypto (cryptographic functions)
-- Both are used across all 26 tables for gen_random_uuid() default PKs
-- and for SHA-256 token hashing in the invitation flow.

CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";
