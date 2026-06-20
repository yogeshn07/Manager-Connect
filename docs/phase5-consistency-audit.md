# Phase 5 Consistency Audit

## Inconsistencies Found: 2

Both were pre-existing documentation drift in `rls-security-policies.md` where the RLS document was written before functional requirements were finalized.

### Inconsistency 1: Challenges creation permissions

| Source | Rule |
|--------|------|
| **FR-05.1, FR-05.2** (source of truth) | "Admin or any member can create" |
| `database-schema-design.md` | "Member or admin who created the challenge" |
| `rls-security-policies.md` (BEFORE fix) | `challenges_insert_admin` — admin only |
| SQL migration 041 | `challenges_insert_authenticated` — any member |

**Rationale:** FR-05.1 and FR-05.2 both explicitly say "Admin or any member." The schema design's `created_by` column description says "Member or admin." The SQL correctly implements the functional requirement.

**Fix applied:** Updated `rls-security-policies.md` to `challenges_insert_authenticated` with `created_by = auth.uid()`. Updated `database-migrations-plan.md` migration #41 description.

### Inconsistency 2: Progress logs visibility

| Source | Rule |
|--------|------|
| **FR-05.5** (source of truth) | "Challenge progress is visible to all members on a leaderboard" |
| `database-execution-plan.md` | "SELECT all authenticated (leaderboard requires all-member access)" |
| `rls-security-policies.md` (BEFORE fix) | `progress_logs_select_own` — own logs only |
| SQL migration 046 | `progress_logs_select_authenticated` — all members |

**Rationale:** FR-05.5 requires a leaderboard ranked by cumulative progress. If members can only see their own logs, the leaderboard is impossible. The execution plan's corrected version and the SQL both implement all-member SELECT.

**Fix applied:** Updated `rls-security-policies.md` to `progress_logs_select_authenticated` with `[active-user-guard]` and noted FR-05.5 leaderboard requirement.

## Documentation Updates Applied

| File | Change |
|------|--------|
| `rls-security-policies.md` | challenges: `challenges_insert_admin` → `challenges_insert_authenticated` |
| `rls-security-policies.md` | progress_logs: `progress_logs_select_own` → `progress_logs_select_authenticated` |
| `database-migrations-plan.md` | Migration #41 description: "INSERT admin" → "INSERT any active member" |

## Post-Fix Verification

| Check | Result |
|-------|--------|
| `challenges_insert_admin` in RLS doc | **0** remaining |
| `progress_logs_select_own` in RLS doc | **0** remaining |
| FR → RLS doc → SQL all consistent for challenges | ✓ |
| FR → RLS doc → SQL all consistent for progress_logs | ✓ |
| challenge_participants: FR → doc → SQL consistent | ✓ (no changes needed) |

## Source of Truth Hierarchy

For every permission decision:
1. **Functional requirements** (`functional-requirements.md`) — the business rule
2. **SQL migrations** — the implementation that must match FR
3. **RLS policies doc** — the design reference that must be updated to match FR + SQL

## Final Verdict

| Metric | Value |
|--------|-------|
| Inconsistencies found | **2** |
| Inconsistencies fixed | **2** |
| Inconsistencies remaining | **0** |
| Implementation matches FR | ✓ |
| Documentation matches implementation | ✓ |

### **PHASE 5 VERIFIED**
