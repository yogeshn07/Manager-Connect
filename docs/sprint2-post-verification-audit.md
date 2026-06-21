# Sprint 2 Post-Verification Audit

**Date:** 2026-06-21
**Scope:** Security review of migration `20260621000001_grant_service_role_access.sql`
**Prerequisite:** Sprint 2 end-to-end verification passed (9/9 tests, 0 failures)

---

## 1. Migration Under Review

```sql
GRANT ALL ON ALL TABLES IN SCHEMA public TO service_role;
GRANT ALL ON ALL SEQUENCES IN SCHEMA public TO service_role;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON TABLES TO service_role;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON SEQUENCES TO service_role;
```

## 2. Security Analysis

### 2.1 What GRANT ALL Provides

| Privilege | Granted | Risk Assessment |
|-----------|---------|----------------|
| SELECT | Yes | Required — Edge Functions read all tables |
| INSERT | Yes | Required — Edge Functions write to all tables |
| UPDATE | Yes | Required — Edge Functions update records |
| DELETE | Yes | Required — cancel/cleanup operations |
| TRUNCATE | Yes | Low risk — never invoked by application code |
| REFERENCES | Yes | No risk — DDL operation, not exploitable via API |
| TRIGGER | Yes | No risk — DDL operation, not exploitable via API |

**Verdict:** TRUNCATE, REFERENCES, and TRIGGER are included by `ALL` but cannot be invoked through the Supabase client library (`supabase-js`). They pose zero runtime risk. Granting individual privileges (SELECT, INSERT, UPDATE, DELETE) instead of ALL would be marginally tighter but would require updating the migration every time a new privilege is needed. `GRANT ALL` matches Supabase's own `roles.sql` pattern.

### 2.2 service_role Security Model

| Property | Value |
|----------|-------|
| Bypasses RLS | Yes — by Supabase design |
| Exposed to clients | **No** — only used server-side in Edge Functions via `createAdminClient()` |
| Key storage | `SUPABASE_SERVICE_ROLE_KEY` environment variable, injected by Supabase runtime |
| Flutter client uses | `publishableKey` (anon key) only |
| Can be called from browser | **No** — Edge Functions run on Deno, key never leaves server |

### 2.3 Why This Migration Is Needed

Supabase's `roles.sql` runs at database init and includes:
```sql
GRANT ALL ON ALL TABLES IN SCHEMA public TO ... service_role;
ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA public GRANT ALL ON TABLES TO ... service_role;
```

However, the `GRANT ALL ON ALL TABLES` line in `roles.sql` executes **before** any custom migrations run — so it only covers tables that exist at init time (none of ours). The `ALTER DEFAULT PRIVILEGES` should cover subsequently-created tables, but empirical testing showed `service_role` getting `permission denied` on our tables, requiring this explicit fix.

Our migration is **idempotent** — re-running it on a database where grants already exist is a no-op. It serves as a defensive guarantee that works regardless of migration runner behavior.

### 2.4 ALTER DEFAULT PRIVILEGES Scope

```sql
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON TABLES TO service_role;
```

Without `FOR ROLE`, this defaults to `CURRENT_USER` (= `postgres`, the migration runner). This ensures any future table created by `postgres` in the `public` schema automatically receives `service_role` grants. This is correct for our project — all migrations run as `postgres`.

### 2.5 Does This Weaken RLS?

**No.** `service_role` already bypasses RLS entirely — this is Supabase's intentional design for server-side operations. Table-level GRANTs and row-level security are independent PostgreSQL mechanisms:

- **GRANTs** = "can this role access this table at all?" (table-level)
- **RLS policies** = "which rows can this role see/modify?" (row-level)

`service_role` bypasses the second check by design. This migration only fixes the first check. All 114 RLS policies remain enforced for `authenticated` and `anon` roles.

## 3. Verification Results

### 3.1 Database Reset

```
supabase db reset → 72 migrations applied, zero errors
```

### 3.2 Schema Drift

```
supabase db diff → "No schema changes found"
```

### 3.3 Schema Counts

| Metric | Expected | Actual | Status |
|--------|----------|--------|--------|
| Tables | 26 | **26** | PASS |
| RLS Policies | 114 | **114** | PASS |
| Triggers | 16 | **16** | PASS |
| Foreign Keys | 47 | **47** | PASS |
| Functions | 3 | **3** | PASS |

All counts unchanged from pre-Sprint-2 baseline.

### 3.4 service_role Grant Coverage

| Table | Grant Status |
|-------|-------------|
| activities | FULL |
| activity_rsvps | FULL |
| activity_updates | FULL |
| admin_audit_log | FULL |
| challenge_participants | FULL |
| challenges | FULL |
| comments | FULL |
| community_health_scores | FULL |
| event_attendance | FULL |
| flagged_content | FULL |
| invitations | FULL |
| member_monthly_stats | FULL |
| notification_inbox | FULL |
| pinned_announcements | FULL |
| poll_options | FULL |
| poll_votes | FULL |
| polls | FULL |
| post_images | FULL |
| post_mentions | FULL |
| post_reactions | FULL |
| posts | FULL |
| profiles | FULL |
| progress_logs | FULL |
| recognition_reactions | FULL |
| recognition_recipients | FULL |
| recognitions | FULL |

**26/26 tables** have full service_role grants.

### 3.5 ALTER DEFAULT PRIVILEGES Active

Both `supabase_admin` and `postgres` grantors have active ALTER DEFAULT PRIVILEGES for `service_role` on public schema TABLEs and SEQUENCEs. Future tables will automatically receive grants.

### 3.6 No Privilege Escalation

The `anon` role's grants on public tables come from Supabase's own `roles.sql` defaults — not from this migration. Our migration only targets `service_role`. RLS policies enforce row-level restrictions for `anon` and `authenticated` as designed.

### 3.7 Git Status

```
Working tree clean (only .claude/settings.json modified — not project code)
```

## 4. Audit Verdict

| Check | Result |
|-------|--------|
| Migration is idempotent | **PASS** |
| No excessive privileges beyond Supabase pattern | **PASS** |
| service_role key not exposed to clients | **PASS** |
| RLS policies unaffected | **PASS** |
| All 26 tables have full service_role grants | **PASS** |
| ALTER DEFAULT PRIVILEGES covers future tables | **PASS** |
| Schema drift | **ZERO** |
| Schema counts unchanged | **PASS** |
| No security vulnerabilities introduced | **PASS** |

### SPRINT 2 POST-VERIFICATION AUDIT: PASSED

---

## 5. Sprint 2 Final Summary

| Metric | Value |
|--------|-------|
| Edge Functions implemented | 4 (create-poll, cancel-activity, post-activity-update, create-recognition) |
| Cumulative Edge Functions | 10 of 21 |
| Migrations added | 1 (service_role grants) |
| Cumulative migrations | 72 |
| Tables | 26 |
| RLS Policies | 114 |
| Critical issues found & fixed | 1 (service_role table-level GRANTs) |
| Remaining critical issues | 0 |
| Security audit | PASSED |

### SPRINT 2: FULLY CLOSED
