# Backend Closure Audit

**Date:** 2026-06-21

---

## 1. Edge Function Inventory (21/21)

| # | Function | Directory | index.ts | use-case.ts | API Contract |
|---|----------|-----------|----------|-------------|--------------|
| 1 | cancel-activity | PASS | PASS | PASS | PASS |
| 2 | close-challenge | PASS | PASS | PASS | PASS |
| 3 | close-poll | PASS | PASS | PASS | PASS |
| 4 | compute-monthly-stats | PASS | PASS | PASS | PASS |
| 5 | create-poll | PASS | PASS | PASS | PASS |
| 6 | create-post | PASS | PASS | PASS | PASS |
| 7 | create-profile | PASS | PASS | PASS | PASS |
| 8 | create-recognition | PASS | PASS | PASS | PASS |
| 9 | deactivate-user | PASS | PASS | PASS | PASS |
| 10 | pin-announcement | PASS | PASS | PASS | PASS |
| 11 | post-activity-update | PASS | PASS | PASS | PASS |
| 12 | post-connect-buddy-message | PASS | PASS | PASS | PASS |
| 13 | record-attendance | PASS | PASS | PASS | PASS |
| 14 | remove-user | PASS | PASS | PASS | PASS |
| 15 | resolve-flag | PASS | PASS | PASS | PASS |
| 16 | revoke-invitation | PASS | PASS | PASS | PASS |
| 17 | scheduled-cleanup | PASS | PASS | PASS | PASS |
| 18 | scheduled-connect-buddy | PASS | PASS | PASS | PASS |
| 19 | send-invitation | PASS | PASS | PASS | PASS |
| 20 | send-notification | PASS | PASS | PASS | PASS |
| 21 | validate-invite-token | PASS | PASS | PASS | PASS |

**Result: 21/21 functions exist, each with index.ts + use-case.ts, all referenced in API contracts.**

---

## 2. Compilation

```
supabase functions serve: 21 functions compiled
  5 listed explicitly + "and 16 more functions" = 21
  Using supabase-edge-runtime-1.74.1 (compatible with Deno v2.1.4)
  Zero compile errors
```

Cross-sprint CORS verification (one function per sprint):

| Function | Sprint | HTTP |
|----------|--------|------|
| send-notification | 1 | 200 |
| create-poll | 2 | 200 |
| close-poll | 3 | 200 |
| resolve-flag | 4 | 200 |
| compute-monthly-stats | 5 | 200 |

**Result: PASS**

---

## 3. Shared Utilities — Orphan Check

| Module | Import Count | Status |
|--------|-------------|--------|
| `auth.ts` | 20 | USED |
| `constants.ts` | 6 | USED |
| `cors.ts` | 23 | USED |
| `crypto.ts` | 3 | USED |
| `errors.ts` | 47 | USED |
| `response.ts` | 21 | USED |
| `supabase-client.ts` | 22 | USED |
| `validators/admin.validators.ts` | 8 | USED |
| `validators/auth.validators.ts` | 3 | USED |
| `validators/events.validators.ts` | 3 | USED |
| `validators/feed.validators.ts` | 2 | USED |
| `validators/recognition.validators.ts` | 1 | USED |
| `validators/system.validators.ts` | 2 | USED |
| `services/audit.service.ts` | 8 | USED |
| `services/notification.service.ts` | 10 | USED |
| `repositories/` | 0 | EMPTY (contains only `.gitkeep`) |

The `repositories/` directory is empty — it was scaffolded but never used. All repository access is done inline in use-case files via the Supabase client. This is not dead code (empty dir with `.gitkeep`), but it is unused scaffolding.

**Result: No orphaned code. One empty scaffolding directory (`repositories/`).**

---

## 4. Dead Imports

All shared modules are imported by at least 1 function. No unreferenced exports detected.

**Result: PASS — no dead imports.**

---

## 5. TODO/FIXME Markers

```
$ git grep TODO -- "backend/"   → 0 results
$ git grep FIXME -- "backend/"  → 0 results
```

**Result: PASS — zero markers.**

---

## 6. Hardcoded Local URLs

```
$ git grep "localhost\|127\.0\.0\.1\|0\.0\.0\.0" -- "backend/supabase/functions/"  → 0 results
```

All URLs are resolved from `Deno.env.get('SUPABASE_URL')` at runtime.

**Result: PASS — no hardcoded URLs.**

---

## 7. Test-Only Code

```
$ git grep "test\|mock\|stub\|fake\|dummy" -- "backend/supabase/functions/"
```

Only result: `uuidPattern.test()` in `auth.validators.ts` — this is regex validation, not test code.

**Result: PASS — no test-only code remains.**

---

## 8. Connect Buddy System Account

### FINDING: DEPLOYMENT BLOCKER

The Connect Buddy system account (`00000000-0000-4000-8000-000000000001`) is **NOT** provisioned by any migration or seed file.

**Current state of `seed.sql`:**
```sql
-- Connect Buddy system profile
-- Must run AFTER the profiles table migration exists (Phase 1).
-- This seed is intentionally empty until Phase 1 migrations are created.
-- The INSERT will be added when the profiles table migration is ready.
--
-- UUID: 00000000-0000-4000-8000-000000000001
```

The file contains only comments — the INSERT was never restored after Phase 1 migrations were completed.

**Impact:**
- After a fresh `supabase db reset`, `profiles` table has 0 rows with the Connect Buddy ID
- `post-connect-buddy-message` returns SERVER_ERROR: "Connect Buddy system profile not found"
- `scheduled-connect-buddy` (all 7 triggers) returns the same error
- `create-profile` (which triggers a welcome message via Connect Buddy) would fail at the CB step

**Affected functions:** 3 of 21 (post-connect-buddy-message, scheduled-connect-buddy, create-profile)

**Required fix:** Populate `seed.sql` with:
1. INSERT into `auth.users` for the Connect Buddy UUID
2. INSERT into `public.profiles` for the Connect Buddy profile

**Severity:** BLOCKER — prevents automated deployment without manual intervention.

---

## 9. Fresh Database Reset

```
$ supabase db reset
  72 migrations applied, zero errors
  Seeding from seed.sql — no data inserted (comments only)

$ supabase db diff
  "No schema changes found"
```

| Metric | Value |
|--------|-------|
| Migrations | 72 applied, 0 errors |
| Schema drift | **ZERO** |
| Tables | 26 |
| RLS Policies | 114 |
| Triggers | 16 |
| Foreign Keys | 47 |
| Functions | 3 |

**Result: PASS — fresh reset succeeds, zero drift.**

---

## 10. Fresh Function Deployment

After fresh reset, `supabase functions serve` compiles all 21 functions with zero errors.

**Result: PASS — all 21 functions compile on fresh environment.**

---

## 11. Working Tree

```
$ git status
On branch main
nothing to commit, working tree clean
```

**Result: PASS**

---

## Audit Summary

| # | Check | Result |
|---|-------|--------|
| 1 | All 21 Edge Functions exist | **PASS** — 21/21 with index.ts + use-case.ts |
| 2 | All functions in API contracts | **PASS** — 21/21 referenced |
| 3 | All functions compile | **PASS** — 21 compiled, zero errors |
| 4 | No orphaned shared utilities | **PASS** — all modules imported (1 empty scaffolding dir) |
| 5 | No dead imports | **PASS** |
| 6 | No TODO/FIXME markers | **PASS** — 0 found |
| 7 | No hardcoded local URLs | **PASS** — 0 found |
| 8 | No test-only code | **PASS** |
| 9 | Connect Buddy via migration/seed | **FAIL** — seed.sql is empty, requires manual setup |
| 10 | Fresh reset + deploy | **PASS** — 72 migrations + 21 functions compile |

---

## Blockers

| # | Blocker | Severity | Affected Functions | Fix Required |
|---|---------|----------|--------------------|-------------|
| 1 | Connect Buddy system account not in seed.sql | **BLOCKER** | post-connect-buddy-message, scheduled-connect-buddy, create-profile | Populate seed.sql with auth.users + profiles INSERT |

---

## Verdict

**BACKEND COMPLETE cannot be declared.** One deployment blocker remains:

The Connect Buddy system account (`00000000-0000-4000-8000-000000000001`) must be provisioned automatically via `seed.sql` (or a migration). Currently requires manual SQL insertion after each `supabase db reset`.

Once `seed.sql` is populated with the Connect Buddy auth.users + profiles entries, all 21 functions will work on a fresh deployment with zero manual intervention.
