# Phase 5 Implementation Audit

## Migrations Created

| # | File | Object |
|---|------|--------|
| 40 | `20260620000040_create_challenges_table.sql` | `challenges` table + 1 index + 4 CHECKs + RLS + grants |
| 41 | `20260620000041_create_challenges_rls_policies.sql` | 4 RLS policies |
| 42 | `20260620000042_create_challenges_updated_at_trigger.sql` | Trigger |
| 43 | `20260620000043_create_challenge_participants_table.sql` | `challenge_participants` table + 2 indexes + 1 UNIQUE + RLS + grants |
| 44 | `20260620000044_create_challenge_participants_rls_policies.sql` | 4 RLS policies |
| 45 | `20260620000045_create_progress_logs_table.sql` | `progress_logs` table + 1 index + 1 CHECK + 1 UNIQUE + RLS + grants |
| 46 | `20260620000046_create_progress_logs_rls_policies.sql` | 5 RLS policies |
| 47 | `20260620000047_create_progress_logs_updated_at_trigger.sql` | Trigger |

**Phase 5 migrations: 8 files** (3 tables + 3 RLS + 2 triggers)

## Cumulative Schema Counts (Phase 0–5)

| Metric | Phase 4 End | Phase 5 Added | Total | Verified |
|--------|-------------|---------------|-------|----------|
| Tables | 14 | +3 | **17** | ✓ |
| Triggers | 9 | +2 | **11** | ✓ |
| Policies | 63 | +13 | **76** | ✓ |
| Foreign Keys | 27 | +6 | **33** | ✓ |
| Indexes | 25 | +4 | **29** | ✓ |
| CHECK constraints | 9 | +5 | **14** | ✓ |
| Migrations | 40 | +8 | **48** | ✓ |

## Schema Drift

```
No schema changes found
```

**Zero drift.**

## RLS Test Results

| # | Test | Persona | Table | Expected | Actual | Status |
|---|------|---------|-------|----------|--------|--------|
| T1 | Member SELECT challenges | Active member | challenges | 1 | 1 | ✓ |
| T2 | Inactive SELECT challenges | Inactive | challenges | 0 | 0 | ✓ |
| T3 | Anonymous SELECT challenges | Anonymous | challenges | 0 | 0 | ✓ |
| T4 | Member INSERT challenge | Active member | challenges | INSERT 1 | INSERT 1 | ✓ |
| T5 | Member DELETE challenge blocked | Active member | challenges | DELETE 0 | DELETE 0 | ✓ |
| T6 | end_date CHECK enforced | Superuser | challenges | Error | CHECK violation | ✓ |
| T7 | Member SELECT participants | Active member | challenge_participants | 1 | 1 | ✓ |
| T8 | Admin JOIN challenge | Admin | challenge_participants | INSERT 1 | INSERT 1 | ✓ |
| T9 | Duplicate JOIN blocked | Active member | challenge_participants | Error | UNIQUE violation | ✓ |
| T10 | Member LEAVE own | Active member | challenge_participants | DELETE 1 | DELETE 1 | ✓ |
| T11 | Member SELECT all logs (leaderboard) | Active member | progress_logs | 1 | 1 | ✓ |
| T12 | Admin SELECT all logs | Admin | progress_logs | 1 | 1 | ✓ |
| T13 | Member INSERT own log | Active member | progress_logs | INSERT 1 | INSERT 1 | ✓ |
| T14 | Member UPDATE own log | Active member | progress_logs | UPDATE 1 | UPDATE 1 | ✓ |
| T15 | Member DELETE log blocked | Active member | progress_logs | DELETE 0 | DELETE 0 | ✓ |
| T16 | Negative value CHECK | Superuser | progress_logs | Error | CHECK violation | ✓ |
| T17 | Trigger fires on UPDATE | — | progress_logs | updated_at advances | PASS | ✓ |

**17/17 tests pass.**

## Issues Discovered

| # | Issue | Source | Resolution |
|---|-------|--------|-----------|
| 1 | `rls-security-policies.md` says challenges INSERT is admin-only; FR-05.1/FR-05.2 say "Admin or any member" | Doc inconsistency | Implemented per FR (any member). Same pattern as activities (FR-04.1). |
| 2 | `rls-security-policies.md` says progress_logs SELECT is own-only for members; leaderboard requires all-member access | Doc inconsistency | Implemented per `database-execution-plan.md` corrected version (all authenticated). |

Both are pre-existing documentation inconsistencies (the RLS doc was written before the functional requirements were finalized). The SQL implements the correct business rules.
