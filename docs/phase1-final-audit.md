# Phase 1 Final Audit

## Migration Execution

| Step | Migration | Result |
|------|-----------|--------|
| 1 | `20260620000001_enable_extensions.sql` | ✓ Applied |
| 2 | `20260620000002_create_update_timestamp_trigger.sql` | ✓ Applied |
| 3 | `20260620000003_create_is_admin_helper.sql` | ✓ Applied (includes `is_active_user()` + `is_admin()`) |
| 4 | `20260620000004_create_profiles_table.sql` | ✓ Applied |
| 5 | `20260620000005_create_profiles_rls_policies.sql` | ✓ Applied |
| 6 | `20260620000006_create_profiles_updated_at_trigger.sql` | ✓ Applied |
| 7 | `20260620000007_create_invitations_table.sql` | ✓ Applied |
| 8 | `20260620000008_create_invitations_rls_policies.sql` | ✓ Applied |
| 9 | `20260620000009_create_invitations_updated_at_trigger.sql` | ✓ Applied |

**`supabase db reset` completes from clean database with zero errors.**

## Schema Verification

| Artifact | Expected | Actual | Status |
|----------|----------|--------|--------|
| Tables | 2 (profiles, invitations) | **2** | ✓ |
| Triggers | 2 | **2** | ✓ |
| RLS policies | 10 (5 + 5) | **10** | ✓ |
| Indexes | 5 (3 + 2) | **5** | ✓ |
| Foreign keys | 3 (1 + 2) | **3** | ✓ |
| CHECK constraints | 2 (app_role, status) | **2** | ✓ |
| UNIQUE constraints | 1 (token_hash) | **1** | ✓ |
| Functions | 3 (update_updated_at_column, is_active_user, is_admin) | **3** | ✓ |
| Extensions | 2 (uuid-ossp, pgcrypto) | **2** | ✓ |

## RLS Verification

| Test | Persona | Operation | Expected | Actual | Status |
|------|---------|-----------|----------|--------|--------|
| T1 | Active member | SELECT profiles | 3 rows | 3 | ✓ |
| T2 | Inactive user | SELECT profiles | 0 rows | 0 | ✓ |
| T3 | Anonymous | SELECT profiles | 0 rows | 0 | ✓ |
| T4 | Admin | SELECT invitations | 2 rows (all) | 2 | ✓ |
| T5 | Member | SELECT invitations | 1 row (own) | 1 | ✓ |
| T6 | Member | INSERT profile | Blocked | Blocked | ✓ |
| T7 | Member | DELETE profile | 0 affected | 0 | ✓ |
| T8 | Member | UPDATE own profile | 1 updated | 1 | ✓ |
| T9 | Member | UPDATE other profile | 0 affected | 0 | ✓ |
| T10 | — | Trigger fires on UPDATE | updated_at advances | PASS | ✓ |

## Issues Found and Resolved During Implementation

| # | Issue | Severity | Resolution |
|---|-------|----------|-----------|
| 1 | RLS infinite recursion: `profiles_select_authenticated` policy queried `profiles` inline to check `is_active`, causing recursive RLS evaluation | **Critical** | Created `is_active_user()` SECURITY DEFINER function in migration 003 — bypasses RLS during policy evaluation |
| 2 | RLS column name mismatch: `rls-security-policies.md` says `used_by`, schema says `accepted_by` | **Medium** | Used `accepted_by` (schema is source of truth) |
| 3 | Missing table GRANTs for `authenticated` and `anon` roles | **High** | Added `GRANT SELECT,INSERT,UPDATE,DELETE ON ... TO authenticated` and `GRANT SELECT ON ... TO anon` in table creation migrations |

## Migration Files Modified

| File | Change |
|------|--------|
| `20260620000003_create_is_admin_helper.sql` | Added `is_active_user()` function alongside `is_admin()` |
| `20260620000004_create_profiles_table.sql` | Added GRANT statements for `authenticated` and `anon` roles |
| `20260620000005_create_profiles_rls_policies.sql` | Changed inline EXISTS to `is_active_user()` call to avoid recursion |
| `20260620000007_create_invitations_table.sql` | Added GRANT statements for `authenticated` and `anon` roles |
| `20260620000008_create_invitations_rls_policies.sql` | Changed inline EXISTS to `is_active_user()` call; fixed `used_by` → `accepted_by` |

## Final Counts

| Metric | Count |
|--------|-------|
| Tables created | **2** |
| Functions created | **3** |
| Triggers created | **2** |
| Indexes created | **5** |
| Policies created | **10** |
| CHECK constraints | **2** |
| UNIQUE constraints | **1** |
| Foreign keys | **3** |
| Extensions | **2** |
| Remaining issues | **0** |

## Verdict

| Criteria | Value |
|----------|-------|
| Critical issues | **0** |
| High issues | **0** |
| Medium issues | **0** |

### **PHASE 1 COMPLETE**

All migrations apply from a clean database. All schema objects verified. All RLS policies tested across 4 personas (active member, inactive user, anonymous, admin). No recursion. No missing references. No ordering issues.
