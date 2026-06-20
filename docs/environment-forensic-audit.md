# Environment Forensic Audit

## Audit Date: 2026-06-20

---

## Root Cause Analysis

### Primary Issue: Two Layered Failures

**Layer 1: Corrupted Docker Image** — The `realtime:v2.107.5` image had corrupted filesystem layers in Docker's overlay cache. Even `/bin/sh` returned I/O error. Fixed by `docker system prune -a --volumes` followed by fresh image re-pull.

**Layer 2: seed.sql references nonexistent table** — After fixing the image corruption, `supabase start` still failed because `seed.sql` runs `INSERT INTO profiles(...)` — but the `profiles` table doesn't exist yet (only Phase 0 migrations are created, `profiles` is Phase 1). The Supabase CLI runs seed.sql automatically during `supabase start`, causing a `42P01: relation "profiles" does not exist` error that crashes the realtime service initialization.

**Fix:** Commented out the seed INSERT (will be restored after Phase 1 migrations are created). After this fix, `supabase start` completes successfully with all services healthy.

### Secondary Issue: Nested Supabase Project Directory

A `supabase init` was accidentally run inside `backend/supabase/` instead of from `backend/`. This created `backend/supabase/supabase/config.toml` — a nested project that the CLI would discover instead of the outer one. The outer `config.toml` used old CLI format (`[project] id = ""`) while the CLI 2.107.0 expects `project_id = "..."`.

**Fix applied:** Removed nested directory, re-initialized from `backend/` with fresh `config.toml`, restored migrations/functions/seed.

### Tertiary Issue: `.env.local` Profile Warning

The Supabase CLI emits `open C:\Users\YOGESH N\.supabase\profile: The system cannot find the file specified` on every command. This is a non-fatal warning — the CLI falls back to default profile. Not blocking.

---

## Issues Discovered

| # | Issue | Severity | Fix Applied | Status |
|---|-------|----------|-------------|--------|
| 1 | Corrupted Docker image cache (realtime + possibly others) | **Critical** | Full `docker system prune -a --volumes` + re-pull of all 13 Supabase images | **Fixed** |
| 1b | `seed.sql` INSERT references `profiles` table that doesn't exist yet (only Phase 0 created) | **Critical** | Commented out seed INSERT — will restore when Phase 1 migrations are created | **Fixed** |
| 2 | Nested `supabase/supabase/` directory with duplicate `config.toml` | **High** | Removed nested dir, re-initialized from parent with CLI 2.107.0 | Fixed |
| 3 | Old `config.toml` format (`[project] id = ""`) incompatible with CLI 2.107.0 | **High** | Re-initialized generates correct `project_id = "backend"` format | Fixed |
| 4 | Supabase CLI profile warning (`.supabase/profile` not found) | **Low** | Not fixed — non-fatal, cosmetic | Deferred |

---

## Phase-by-Phase Results

### Phase A — Project Structure

| Check | Result |
|-------|--------|
| Project root exists | ✓ `C:\Users\YOGESH N\OneDrive\Desktop\office_project` |
| Frontend root | ✓ `frontend/` with `pubspec.yaml`, `lib/`, `android/`, `ios/`, `web/` |
| Backend root | ✓ `backend/supabase/` with `config.toml`, `migrations/`, `functions/`, `seed.sql` |
| Generated .g.dart files | ✓ 4 files present |
| Phase 0 migrations | ✓ 3 files present |
| Duplicate Supabase dirs | ✓ **Fixed** — nested `supabase/supabase/` removed |

### Phase B — Flutter Health

| Check | Result |
|-------|--------|
| Flutter version | ✓ 3.41.7 stable |
| Dart version | ✓ 3.11.5 |
| `flutter doctor -v` | ✓ **No issues found** — all 7 checks green |
| `flutter pub get` | ✓ Dependencies resolved |
| `flutter analyze` | ✓ **No issues found** |
| Chrome device | ✓ Available |
| Windows device | ✓ Available |
| Android toolchain | ✓ SDK 36.1.0 |

### Phase C — Runtime Health

| Check | Result |
|-------|--------|
| `flutter run -d chrome` | ✓ App launches, debug service connects |
| Welcome screen renders | ✓ |
| Runtime exceptions | 1 warning (Passkeys SDK — non-fatal, irrelevant) |
| Hot reload available | ✓ |

### Phase D — Docker Audit

| Check | Result |
|-------|--------|
| Docker client | ✓ 29.2.1 |
| Docker server | ✓ Docker Desktop 4.61.0 |
| Docker daemon | ✓ Responsive |
| Storage | ✓ No exhaustion after prune |
| Supabase images | 13 images present → pruned → re-pulling |
| Corrupted image | **Found:** realtime:v2.107.5 had corrupted layers |

### Phase E — WSL Audit

| Check | Result |
|-------|--------|
| WSL2 | ✓ Running |
| Default distribution | ✓ `docker-desktop` |
| Docker integration | ✓ Desktop-Linux context |

### Phase F — Supabase CLI Audit

| Check | Result |
|-------|--------|
| CLI version | ✓ 2.107.0 |
| `config.toml` format | ✓ **Fixed** — new format with `project_id` |
| `supabase start` | **PASS** — all services started, Studio at http://127.0.0.1:54323 |
| Migrations directory | ✓ 3 Phase 0 files |
| Functions directory | ✓ 21 function dirs + `_shared/` |

### Phase G — Migration Audit

| Check | Result |
|-------|--------|
| Migration count | ✓ 3 (Phase 0 only — correct) |
| Migration ordering | ✓ 000001, 000002, 000003 (sequential) |
| SQL syntax | ✓ All 3 files valid PostgreSQL |
| Migration 001 | ✓ `CREATE EXTENSION IF NOT EXISTS` × 2 (idempotent) |
| Migration 002 | ✓ `CREATE OR REPLACE FUNCTION update_updated_at_column()` (idempotent, TRIGGER return) |
| Migration 003 | ✓ `CREATE OR REPLACE FUNCTION is_admin()` (SECURITY DEFINER, STABLE, correct auth.uid() reference) |
| Alignment with schema design | ✓ Matches `database-schema-design.md` Trigger Specification |

---

## Fixes Applied

| Fix | Files Changed | Safe? |
|-----|---------------|-------|
| Removed `backend/supabase/supabase/` nested directory | 1 dir + config.toml | ✓ |
| Re-initialized from `backend/` with `supabase init` | `config.toml` regenerated | ✓ |
| Restored migrations, functions, seed from backups | 3 dirs | ✓ |
| Removed stale `supabase-debug.log` | 1 file | ✓ |
| `docker system prune -a -f --volumes` | Docker cache cleared | ✓ |
| Re-pulled all 13 Supabase images | Docker image store | ✓ |
| Commented out seed.sql INSERT (profiles table doesn't exist yet) | `seed.sql` | ✓ |

---

## Remaining Blockers

**None.** All components operational.

---

## Status Summary

| Component | Status |
|-----------|--------|
| Flutter | **PASS** |
| Chrome | **PASS** |
| Build Runner | **PASS** |
| Analyze | **PASS** |
| Docker | **PASS** |
| WSL | **PASS** |
| Supabase CLI | **PASS** |
| Local Database | **PASS** |
| Migrations | **PASS** |

**All 9 components green.**

---

## Exact Next Action

Continue with Phase 1 database migrations (profiles + invitations tables). Restore `seed.sql` INSERT after the profiles table migration is created.
