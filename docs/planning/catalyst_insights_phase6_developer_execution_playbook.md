# CATALYST INSIGHTS — PHASE 6.0
# DEVELOPER EXECUTION PLAYBOOK

**Classification:** Engineering Operating Manual  
**Status:** LOCKED  
**Authority:** Engineering Director  
**Applies To:** All engineers working on Catalyst Insights implementation  
**Sprint Coverage:** Sprint 1 through Sprint 4 + Production Release  
**Prerequisite Reading:** Phase 5.0 Implementation Master Guide (read before Sprint 1 Day 1)

---

## PART 1 — DEVELOPER RULES

These rules are non-negotiable. Any violation is a PR rejection. Any rule that conflicts with a time constraint is escalated to the Engineering Director — not circumvented.

### 1.1 Architecture Rules

| # | Rule | Consequence of Violation |
|---|------|--------------------------|
| AR-01 | Never modify the frozen architecture | PR rejected; architectural change requires a new phase document |
| AR-02 | Never change database schema after a migration is merged to `main` | A new migration must be written; existing migrations are immutable |
| AR-03 | Never change the folder structure defined in Phase 5.0 Part 2 | Files in wrong locations break the build order; PR rejected |
| AR-04 | Never introduce a new package (Dart or Deno) without Engineering Director approval | Dependency audit required; unapproved packages blocked at PR |
| AR-05 | Never change API contracts between Edge Functions after Sprint 2 merges | Downstream functions break silently; requires re-testing entire pipeline |
| AR-06 | Never modify the pipeline status enum values or state machine transitions | Pipeline integrity guaranteed by the 10-status state machine; any change requires Phase 3.8 re-review |

### 1.2 Data Access Rules

| # | Rule | Consequence of Violation |
|---|------|--------------------------|
| DA-01 | Never access Supabase directly from a Flutter widget or screen | All Supabase calls go through `InsightsRepository` or `InsightsAdminRepository` — never inline |
| DA-02 | Never bypass Riverpod for state management in the Insights feature | No `setState`, no `InheritedWidget`, no global variables — only `ref.watch`/`ref.read` |
| DA-03 | Never write SQL in Flutter source code | PostgREST queries only; no raw SQL in Dart |
| DA-04 | Never bypass Row-Level Security in production | Service role key never goes into Flutter; only Edge Functions use service role |
| DA-05 | Never call `batch_approve_high_confidence` RPC for the first 4 weeks of production | Documented in Phase 3.8; AI confidence reliability must be validated first |

### 1.3 Security Rules

| # | Rule | Consequence of Violation |
|---|------|--------------------------|
| SEC-01 | Never hardcode secrets, API keys, or passwords in source code | Immediate PR rejection; git history must be cleaned |
| SEC-02 | Never log PII, user IDs in plaintext, or secrets in Edge Function logs | Structured logger only; no raw values that identify individuals |
| SEC-03 | Never commit `.env` files, Supabase secret exports, or credential files | Added to `.gitignore`; if committed, rotate all secrets immediately |
| SEC-04 | Never skip HMAC verification in `validate_insight` | MF-01 finding; skipping it is a security regression |
| SEC-05 | Never remove prompt injection defenses from `enrich_insight` | MF-07 finding; removing sanitization opens attack surface |
| SEC-06 | Never expose the service role key to client code or logs | Service role bypasses RLS; exposure is a critical security incident |

### 1.4 Quality Rules

| # | Rule | Consequence of Violation |
|---|------|--------------------------|
| QA-01 | Never skip writing tests for a task that has specified test cases in Phase 5.0 | PR blocked until tests are written |
| QA-02 | Never merge a branch with failing tests | CI must be green; no exceptions without Engineering Director sign-off |
| QA-03 | Never merge a branch with `flutter analyze` errors | Zero-error analyze is required; warnings are documented, errors are fixed |
| QA-04 | Never use `console.log` in Edge Functions | All logging through `_shared/logger.ts`; `console.log` is banned in PR review |
| QA-05 | Never push directly to `main` | All changes via PR; `main` is branch-protected |
| QA-06 | Never merge without at least one code review approval | Solo-push to feature branches is allowed; PRs require ≥1 approval |
| QA-07 | Never modify a quality gate requirement without Engineering Director approval | Gates are the enforcement mechanism for Phase 3.8 findings |

### 1.5 Sprint Scope Rules

| # | Rule | Consequence of Violation |
|---|------|--------------------------|
| SC-01 | Never add scope to Sprint 3 without Engineering Director approval | Sprint 3 is at 100% capacity; any addition bumps an existing task |
| SC-02 | Never begin Sprint N+1 work before Gate N passes | Sprint branches exist; starting early risks forward-contaminating the gate evidence |
| SC-03 | Never defer a P0 CRITICAL task to a later sprint | P0 tasks define the sprint; deferring one changes the gate definition |
| SC-04 | Never mark a Phase 3.8 mandatory finding as resolved without the specified verification evidence | CF-01, MF-01 through MF-07 have explicit test cases; passing the test is the definition of resolved |

---

## PART 2 — DAILY ENGINEERING WORKFLOW

Every engineer follows this workflow every working day. The workflow is the same for all sprints and all roles.

```
START OF DAY
     │
     ▼
1. SYNC
     │  git fetch --all
     │  git pull origin <your-sprint-branch>
     │  Review any overnight PR comments
     ▼
2. BASELINE CHECK
     │  Run local tests for your current work area
     │  (Deno: deno test supabase/tests/)
     │  (Flutter: flutter test)
     │  Confirm baseline is clean before adding new code
     ▼
3. TASK SELECTION
     │  Open issue tracker
     │  Confirm your assigned task is still unblocked
     │  Read the full task definition in Phase 5.0 Part 3
     │  Read any task-specific inputs (Phase 3.5 section, Phase 3.8 finding)
     ▼
4. IMPLEMENTATION
     │  Code on your sprint branch only
     │  Commit frequently (at least once per logical unit)
     │  Push to remote at end of every session
     │  No implementation without reading the spec first
     ▼
5. LOCAL VALIDATION
     │  Run the verification steps from the Phase 5.0 task definition
     │  Check: no console.log, no hardcoded secrets, no flutter analyze errors
     │  Check: all Phase 3.8 finding requirements met if task touches a finding
     ▼
6. COMMIT & PUSH
     │  Commit message format: {type}({scope}): {description}
     │  git push origin <your-sprint-branch>
     ▼
7. PULL REQUEST (when task is complete)
     │  Open PR from sprint branch → main
     │  Use PR template (Section 3.2 of this document)
     │  Assign reviewer
     ▼
8. CODE REVIEW
     │  Reviewer uses Section 5 checklist
     │  Author addresses all comments before merge
     │  No self-approval
     ▼
9. MERGE (after approval)
     │  Squash or merge commit (team decides before Sprint 1 — consistent throughout)
     │  Delete remote sprint branch only AFTER all sprint tasks are merged
     ▼
10. POST-MERGE
     │  Update issue status to Done
     │  Verify CI passes after merge
     │  Update sprint board
END OF DAY
```

---

## PART 3 — BRANCH & MERGE STRATEGY

### 3.1 Branch Map

```
main (protected — no direct push)
├── feature/insights-sprint-1-database       (Database Engineer — Sprint 1)
├── feature/insights-sprint-2-pipeline       (Backend Engineer — Sprint 2)
├── feature/insights-sprint-3-enrichment     (Backend Engineer — Sprint 3)
└── feature/insights-sprint-4-flutter        (Flutter Engineer — Sprint 4)
    └── feature/insights-sprint-4-nav        (Flutter Engineer — Sprint 4 Day 6)
```

### 3.2 Branch Rules

| Rule | Detail |
|------|--------|
| All branches created from `main` | Before Sprint 1 Day 1; sprint-4-nav is the sole exception (from sprint-4-flutter on S4 Day 6) |
| One sprint branch per sprint | No sub-branches within a sprint; all sprint work on the one branch |
| Sprint branches merge sequentially | S1 merges first, then S2 can begin (Gate 1 evidence), then S3, then S4 |
| No cross-sprint branch commits | Backend Engineer never commits Flutter code; Flutter Engineer never commits Edge Function code |
| sprint-4-nav merges into sprint-4-flutter | Not directly to main; sprint-4-flutter is the PR to main |
| Sprint branch is not deleted until gate is passed | Branch preserved as rollback until gate review is complete |

### 3.3 Merge Strategy

**Sprint branch → main:** Use **merge commit** (not squash) to preserve the commit history as a chronological record of the sprint. This makes rollback straightforward: revert the merge commit.

**sprint-4-nav → sprint-4-flutter:** Use **merge commit** so the nav wiring is a distinct, identifiable commit that can be reverted independently if a GoRouter conflict is found post-merge.

### 3.4 Rollback via Revert

If a merged sprint introduces a regression:

1. `git revert -m 1 <merge-commit-hash>` — creates a revert commit, does not delete history
2. Push revert commit to `main`
3. Fix the issue on the original sprint branch (or a new hotfix branch)
4. Re-open PR with the fix

**Never use `git reset --hard` on `main`.** Revert commits only.

---

## PART 4 — PULL REQUEST REQUIREMENTS

### 4.1 PR Template

Every PR must complete this template. An incomplete template is a rejection reason.

```markdown
## Sprint & Tasks

Sprint: [1 / 2 / 3 / 4]
Tasks completed: [S1-DB-001, S1-DB-002, ...]

## Summary of Changes

[One paragraph: what was implemented, what files changed, what behaviour is new]

## Phase 3.8 Findings Addressed

[List each finding with status: MF-04 RESOLVED / CF-01 RESOLVED / Not applicable to this PR]

## Test Evidence

[List tests run and results]
- [ ] Migration regression (Sprint 1 only)
- [ ] Unit tests: [X/Y passing]
- [ ] Integration tests: [list scenarios and results]
- [ ] Security tests: [HMAC test — Sprint 2 only; injection tests — Sprint 3 only]
- [ ] Flutter analyze: zero errors (Sprint 4 only)

## Quality Gate Evidence

[Paste the Gate N checklist with all items checked]

## Deviations from Phase 5.0 Spec

[List any deviations and rationale; "None" if none]

## Known Issues / Follow-up

[List any P3 tasks deferred or known issues; "None" if none]
```

### 4.2 PR Approval Requirements

| Sprint | Required Approvals | Additional Requirements |
|--------|-------------------|------------------------|
| Sprint 1 | 1 (Tech Lead) | Gate 1 checklist attached |
| Sprint 2 | 1 (Tech Lead) | MF-01 HMAC test results attached; CF-01 integration test attached |
| Sprint 3 | 1 (Tech Lead) | Full pipeline E2E trace attached; MF-05/MF-07 test results |
| Sprint 4 | 1 (Tech Lead) + 1 (Engineering Director) | 8-scenario integration test results; SLO measurements; GoRouter regression matrix |

Sprint 4 requires Engineering Director approval because it contains the final go-live gate and all Phase 3.8 Flutter-layer findings.

### 4.3 PR Size Guidelines

PRs that are too large to review in a single session will be returned for splitting.

| Guideline | Threshold |
|-----------|-----------|
| Maximum files changed per PR | 20 files |
| Maximum lines changed (excluding generated code) | 800 lines |
| Maximum number of tasks per PR | One sprint per PR (Sprint 1 = one PR for all 16 tasks) |

Sprint PRs are naturally bounded to one sprint's scope. If a single sprint's PR exceeds 20 files, it is expected — this is a full sprint worth of work, not a feature PR guideline.

---

## PART 5 — CODE REVIEW CHECKLISTS

These checklists are used by the reviewer, not the author. An item marked ❌ is a blocking comment.

### 5.1 General Checklist (All PRs)

- [ ] No `console.log` in Edge Function files (use `_shared/logger.ts`)
- [ ] No hardcoded URLs, keys, passwords, or environment variable values
- [ ] No direct DB access in Flutter widgets or screens (all through repository)
- [ ] Commit messages follow `{type}({scope}): {description}` format
- [ ] No files in wrong directories (verify against Phase 5.0 Part 2 file tree)
- [ ] No new packages introduced without approval notation in PR
- [ ] PR template is complete — no section left blank without "N/A"

### 5.2 Database Checklist (Sprint 1 PRs)

- [ ] Migration files are named with correct timestamp prefix
- [ ] Migration M03 includes `is_evergreen BOOLEAN NOT NULL DEFAULT false` (MF-04)
- [ ] Migration M03 includes `reviewed_by UUID REFERENCES auth.users(id)` nullable (MF-06)
- [ ] Migration M03 includes `reviewed_at TIMESTAMPTZ` nullable (MF-06)
- [ ] Migration M05 includes `idx_insights_raw_updated_at` (CF-01)
- [ ] All FK constraints reference existing tables in the correct migration order
- [ ] All status CHECK constraints include all 10 valid values
- [ ] `UNIQUE` constraints present on `url_fingerprint` (both `insights_raw` and `catalyst_insights`)
- [ ] RLS enabled on all 6 tables
- [ ] Anon policy on `catalyst_insights` filters to `status = 'active'` only
- [ ] `batch_approve_high_confidence` is SECURITY INVOKER (not DEFINER)
- [ ] Seed file contains exactly 25 rows
- [ ] WEF `approved_domain` = `weforum.org/agenda/energy` (sub-path, not root domain)
- [ ] EC `approved_domain` = `ec.europa.eu/energy` (sub-path)
- [ ] Migration regression test result attached in PR

### 5.3 Backend (Edge Functions) Checklist (Sprint 2 + Sprint 3 PRs)

**Sprint 2:**
- [ ] `_shared/types.ts` created first — every other file imports from it
- [ ] `_shared/logger.ts` outputs single-line JSON with required fields: `timestamp`, `function_name`, `execution_id`, `level`, `event`
- [ ] `_shared/url_utils.ts`: UTM strip verified; max 3 redirect hops enforced
- [ ] `_shared/domain_validator.ts`: WEF sub-path matching correct; EC sub-path matching correct
- [ ] `_shared/keyword_scorer.ts`: tier bonus applied; threshold ≥ 0.3 for validation pass
- [ ] `collect_insight`: JWT verification present before any processing
- [ ] `validate_insight`: HMAC-SHA256 verification is the FIRST operation (MF-01)
- [ ] `validate_insight`: Returns 401 on missing or tampered signature (MF-01)
- [ ] `validate_insight`: Returns 200 for all operational outcomes (rejection/success) to prevent webhook retries on business logic failures
- [ ] `recover_stalled_insights`: Queries `updated_at < now() - interval '15 minutes'` (CF-01)
- [ ] `recover_stalled_insights`: Logs WARN when `recovered_count > 0`; INFO when 0

**Sprint 3:**
- [ ] `enrich_insight/ai_prompt.ts`: Strips `<INST>`, `[INST]`, `<system>` from input before constructing prompt (MF-07)
- [ ] `enrich_insight/ai_prompt.ts`: Output anomaly detection checks first word of `ai_summary`; sets `confidence_score = 0.0` on trigger words (MF-07)
- [ ] `enrich_insight/ai_client.ts`: Per-attempt Anthropic timeout is 25 seconds — NOT 30s (Phase 3.8 correction)
- [ ] `enrich_insight/ai_client.ts`: Retry backoff is 2s, 4s, 8s (exponential); max 3 attempts
- [ ] `enrich_insight/ai_client.ts`: Model constant named `AI_ENRICHMENT_MODEL` at file top
- [ ] `enrich_insight/image_validator.ts`: Binary header parsing for JPEG (SOF0/SOF2), PNG (IHDR bytes 16–23), WebP (VP8X bytes 24–31) (MF-05)
- [ ] `enrich_insight/image_validator.ts`: Unknown format returns `null` (fail-open) (MF-05)
- [ ] `mirror_insight_image`: CDN URL contains `?width=1200&quality=85&format=webp`
- [ ] `expire_old_insights`: Query filters `is_evergreen = false` (evergreen guard present)
- [ ] All 13 required log events emitted (Phase 3.8 §8.1)

### 5.4 Flutter Checklist (Sprint 4 PRs)

**Data Layer:**
- [ ] `InsightDto` has all 14 fields; field rename mapping correct (`ai_summary` → `summary`, `ai_why_matters` → `whyItMatters`, `ai_key_takeaway` → `keyTakeaway`, `ai_tags` → `tags`)
- [ ] `InsightReviewDto` includes `isEvergreen: bool` (MF-04)
- [ ] `InsightsError` is a sealed class with 7 subclasses
- [ ] `InsightsRepository` interface is abstract — no Supabase client reference in the interface file
- [ ] Concrete repository uses versioned cache key: `insights_page_0_v1`
- [ ] Cache TTL check: 60-minute threshold; returns `null` on expiry (not stale data)

**State Layer:**
- [ ] `InsightsNotifier` extends `Notifier<InsightsState>` — NOT `AsyncNotifier`
- [ ] `InsightsProvider` is `NotifierProvider` (lazy) — no `keepAlive()`
- [ ] Pre-fetch trigger: `index >= state.insights.length - 2` (not -1, not -3)
- [ ] `InsightsState.copyWith` covers all 8 fields (Freezed or manual — verify implementation)
- [ ] No `ref.watch` inside `InsightsNotifier` methods (Riverpod anti-pattern)
- [ ] All state mutations use `state = state.copyWith(...)` pattern

**UI Layer:**
- [ ] `CachedNetworkImage` includes `memCacheWidth: 1200` and `memCacheHeight: 900` (mf-02)
- [ ] `InsightCard` is wrapped in `RepaintBoundary`
- [ ] Card height: `MediaQuery.of(context).size.height`
- [ ] Category colours match the 6-colour map from Phase 3.8
- [ ] Null `heroImageUrl` handled — category background shown (no NPE)

**Admin Layer:**
- [ ] `InsightsAdminRepository.approveInsight()` sends `reviewed_by` + `reviewed_at` in PATCH (MF-06)
- [ ] `InsightsAdminRepository.rejectInsight()` sends `reviewed_by` + `reviewed_at` in PATCH (MF-06)
- [ ] `InsightsAdminRepository.editInsight()` sends `reviewed_by` + `reviewed_at` + `is_evergreen` in PATCH (MF-06, MF-04)
- [ ] `fetchAiErrorQueue()` method present in admin repository (MF-03)
- [ ] `retryEnrichment({required String rawId})` method present (MF-03)
- [ ] `InsightsAiErrorScreen` accessible as third tab in `InsightsAdminScreen` (MF-03)
- [ ] `PipelineHealth` type includes `ai_error_count` field (MF-03)
- [ ] Admin screens auth-gated (`is_admin = true` check)

**Navigation:**
- [ ] GoRouter routes created on `feature/insights-sprint-4-nav` branch (not on sprint-4-flutter)
- [ ] `app_router.dart` read and all existing routes documented before adding new routes (mf-07)
- [ ] GoRouter regression test matrix included in PR

**Quality:**
- [ ] `flutter analyze` output: zero errors
- [ ] `flutter test` passes
- [ ] No direct Supabase client access in any widget (repository pattern enforced)

### 5.5 Security Checklist (All PRs)

- [ ] No secrets, API keys, or connection strings in any committed file
- [ ] No `print()` or `console.log()` statements that could expose sensitive data
- [ ] HMAC verification present in `validate_insight` (Sprint 2+ PRs)
- [ ] Prompt injection defenses in `enrich_insight` (Sprint 3+ PRs)
- [ ] Admin operations verify auth session before executing
- [ ] RLS bypasses (service role) only in Edge Functions, never in Flutter

### 5.6 Performance Checklist (Sprint 3 + Sprint 4 PRs)

- [ ] No unbounded SELECT queries (all DB queries have LIMIT or WHERE clause)
- [ ] No N+1 query patterns (batch queries over loops)
- [ ] Image memory bounded (`memCacheWidth`/`memCacheHeight` on all `CachedNetworkImage`)
- [ ] Pre-fetch logic fires at `length - 2` to prevent blank card visible on slow network
- [ ] Cache hit serves in <100ms (no async operations on cache read path)
- [ ] Edge Function timeouts set: `og_extractor` 8s, Anthropic per-attempt 25s

### 5.7 Testing Checklist (All PRs)

- [ ] Every Phase 5.0 task with a "Verification" section has its specified tests written
- [ ] Test file names follow the convention: `{module}_test.ts` (Deno) / `{widget}_test.dart` (Flutter)
- [ ] Tests are in the correct directory (`supabase/tests/unit/` or `supabase/tests/integration/`)
- [ ] No test depends on external network calls (mock or stub external calls in unit tests)
- [ ] Integration tests use the staging Supabase environment (not production)
- [ ] Test results are documented in PR with PASS/FAIL for each test case

### 5.8 Documentation Checklist (All PRs)

- [ ] Any deviation from Phase 5.0 spec is documented in PR body under "Deviations"
- [ ] Phase 3.8 findings that are resolved in this PR are listed under "Findings Addressed"
- [ ] Issue tracker updated: tasks set to Done
- [ ] Sprint board updated: tasks moved to merged column
- [ ] No inline code comments explaining WHAT the code does (names should be self-documenting)
- [ ] One-line comments added only where WHY is non-obvious

---

## PART 6 — CODING STANDARDS

### 6.1 Deno / TypeScript (Edge Functions)

| Standard | Rule |
|----------|------|
| Imports | All imports use explicit file extensions (`.ts`); no barrel files |
| Shared utilities | Always imported from `../_shared/{module}.ts` — never copied |
| Error handling | Named error types (e.g., `AI_MAX_RETRIES_EXCEEDED`) — no generic `Error(message)` for domain errors |
| Async/await | Always `await` Promises; no `.then()/.catch()` chains |
| Function signatures | Explicit parameter types and return types on all exported functions |
| Constants | Module-level named constants (e.g., `AI_ENRICHMENT_MODEL`, `RELEVANCE_THRESHOLD`) — no magic numbers inline |
| Logging | Every exported function emits at least one log event on completion or failure |
| Environment variables | Read once at function invocation; validated at startup with descriptive error if missing |
| Deno permissions | Minimum required: `--allow-net`, `--allow-env`; no `--allow-all` |

### 6.2 Dart / Flutter

| Standard | Rule |
|----------|------|
| Naming | `lowerCamelCase` for variables/methods; `UpperCamelCase` for classes; `snake_case` for files |
| State | All Insights feature state through Riverpod; no `setState` in Insights screens |
| Null safety | Strict null safety; no `!` force-unwrap unless null is provably impossible with a comment explaining why |
| Async | `async/await` everywhere; no `.then()` callbacks |
| DTOs | `fromJson` factory constructors; no dynamic map access in widgets |
| Widgets | Stateless preferred; stateful only when local widget state is unavoidable (e.g., `PageController`) |
| Imports | Use relative imports within feature; package imports for cross-feature |
| Comments | Only where WHY is non-obvious; never "this method does X" (method name does that) |

### 6.3 Commit Message Standards

Format: `{type}({scope}): {description}`

**Types:**

| Type | Usage |
|------|-------|
| `feat` | New feature or new file |
| `fix` | Bug fix |
| `test` | Test file only |
| `chore` | Build config, migration, seed data, cron registration |
| `security` | Security fix (use for MF-01, MF-07 implementations) |
| `docs` | Documentation only |

**Scopes:**

| Scope | Usage |
|-------|-------|
| `db` | Migration files |
| `shared` | `_shared/` utilities |
| `pipeline` | `collect_insight`, `validate_insight` |
| `enrichment` | `enrich_insight`, `mirror_insight_image`, `recover_stalled_insights` |
| `scheduler` | `activate_scheduled_insights`, `expire_old_insights` |
| `flutter` | Flutter data layer, state layer |
| `admin` | Flutter admin screens and repository |
| `nav` | GoRouter wiring |
| `security` | Security-specific changes |

**Examples:**
```
feat(db): apply M03 with is_evergreen and reviewed_by audit columns
security(pipeline): add HMAC-SHA256 webhook signature verification (MF-01)
feat(enrichment): implement CF-01 recover_stalled_insights cron
security(enrichment): add prompt injection sanitization and output anomaly detection (MF-07)
feat(flutter): implement InsightsNotifier with pre-fetch at length-2
feat(admin): add InsightsAiErrorScreen as third admin tab (MF-03)
test(pipeline): add CF-01 integration test to schedulers_test.ts
```

---

## PART 7 — TESTING WORKFLOW

### 7.1 Test Execution by Sprint

| Sprint | Test Type | Command | When |
|--------|-----------|---------|------|
| Sprint 1 | Schema verification | `supabase db reset && supabase migration up` | After all migrations; before PR |
| Sprint 1 | RLS policy matrix | Manual Supabase client calls | After M06; document results |
| Sprint 2 | Unit tests (Deno) | `deno test supabase/tests/unit/` | After each utility file |
| Sprint 2 | Integration tests | Manual invoke via Supabase Dashboard | After functions deployed |
| Sprint 2 | HMAC security test | Manual — 3 curl requests | After S2-BE-012 |
| Sprint 3 | Unit tests (Deno) | `deno test supabase/tests/unit/enrich_insight_test.ts` | After ai_prompt, image_validator |
| Sprint 3 | Pipeline E2E | Manual — submit article, watch DB | After all Sprint 3 functions deployed |
| Sprint 4 | Flutter unit tests | `flutter test` | Continuously during development |
| Sprint 4 | Flutter integration | On device/simulator vs staging | Sprint 4 Day 7 |
| Sprint 4 | Performance SLO | Flutter DevTools + Supabase logs | Sprint 4 Day 8 |

### 7.2 Test Environment

| Environment | Usage | Notes |
|-------------|-------|-------|
| Local Supabase dev | Sprint 1 migration testing only | `supabase start` |
| Staging Supabase | All Sprint 2–4 integration testing | Separate project from production |
| Production Supabase | Only after Gate 5 is passed | Never use production for testing |

**No Sprint 2–4 integration tests run against production.** If staging is unavailable, the sprint is paused until staging is restored.

### 7.3 Test Data Management

- Do not leave test data in staging after testing is complete (clean up manually after each test run)
- Test articles: use URLs from Tier 1 sources only (IEEE, IEA) — they have stable OG metadata
- Test images: maintain a set of 3 test images (300×100, 400×200, and a .txt file) in the team shared folder
- Do not test AI enrichment with more than 1 article per session (token cost management)

### 7.4 Test Naming Conventions

**Deno:**
```
supabase/tests/unit/{module}_test.ts
supabase/tests/integration/{feature}_test.ts
```

Test function naming: `Deno.test("should {expected behaviour} when {condition}", ...)`

**Flutter:**
```
test/features/insights/{module}_test.dart
```

Test naming: `test('should {expected behaviour} when {condition}', ...)`

---

## PART 8 — DEPLOYMENT WORKFLOW

### 8.1 Deployment Sequence

Deployment follows this sequence strictly. Never deploy a later sprint before an earlier sprint is fully deployed and verified.

```
Sprint 1 complete → apply migrations to staging → verify schema
     │
     ▼
Sprint 2 complete → deploy collect_insight, validate_insight, recover_stalled_insights
                  → configure webhook + secret → register CF-01 cron
     │
     ▼
Sprint 3 complete → deploy enrich_insight, mirror_insight_image, schedulers
                  → add ANTHROPIC_API_KEY → register activate + expire crons
     │
     ▼
Sprint 4 complete → build Flutter app → install on device → smoke test
     │
     ▼
Gate 5 (Production Ready) → apply migrations to production → deploy all functions to production
                           → configure all secrets in production → seed production DB
                           → final smoke test → authorize go-live
```

### 8.2 Edge Function Deployment Commands

```
supabase functions deploy collect_insight --no-verify-jwt
supabase functions deploy validate_insight --no-verify-jwt
supabase functions deploy enrich_insight --no-verify-jwt
supabase functions deploy mirror_insight_image --no-verify-jwt
supabase functions deploy activate_scheduled_insights --no-verify-jwt
supabase functions deploy expire_old_insights --no-verify-jwt
supabase functions deploy recover_stalled_insights --no-verify-jwt
```

`--no-verify-jwt` is used because `validate_insight` is called by the Supabase webhook system (not by an authenticated client), and `recover_stalled_insights` / `activate_scheduled_insights` / `expire_old_insights` are cron-triggered. `collect_insight` verifies the admin JWT manually within the function body.

### 8.3 Deployment Verification (Per Sprint)

After every Edge Function deployment:

1. Check Supabase Dashboard → Edge Functions — function shows as deployed
2. Invoke the function manually with a valid test payload
3. Confirm the function log appears in the Dashboard
4. Confirm no startup errors (missing env vars, import errors)

After cron registration:

1. Wait for the next cron window
2. Confirm the execution log appears
3. Confirm log output matches the expected format (`recover_stalled.run`, etc.)

### 8.4 Pre-Production Checklist

Before any production deployment:

- [ ] All 4 sprints merged to `main`
- [ ] Gate 1 through Gate 4 evidence documented
- [ ] All Phase 3.8 finding resolution evidence documented
- [ ] Phase 4.0 Section 9 go-live criteria fully checked
- [ ] `ANTHROPIC_API_KEY` loaded in production Supabase Secrets
- [ ] `WEBHOOK_SECRET` loaded in production Supabase Secrets (different value from staging)
- [ ] 6 category default WebP images uploaded to production `insights-images/defaults/`
- [ ] At least 10 manually approved active insights seeded for first user experience
- [ ] Spend alert active on Anthropic API account

---

## PART 9 — ROLLBACK PROCEDURES

### 9.1 Rollback Decision Authority

| Situation | Decision Maker | Timeline |
|-----------|----------------|----------|
| Staging function misbehaving | Backend Engineer | Immediate; no approval needed |
| Staging migration causing errors | Database Engineer + Tech Lead | Within 1 hour |
| Production function causing errors | Engineering Director | Immediate; alert team |
| Production data integrity issue | Engineering Director | Immediate; consider full DB restore |

### 9.2 Edge Function Rollback

Edge Functions are versioned by Supabase. To roll back to the previous deployment:

1. In Supabase Dashboard → Edge Functions → select function → Versions
2. Select the previous version
3. Click "Set as Active"
4. Verify the function behaves correctly with a test invocation

If the Dashboard version history is unclear:

1. Redeploy the last known good code: `supabase functions deploy {function_name}`
2. This requires the previous version to be on your local branch

### 9.3 Database Rollback

**For migrations not yet in production:** `supabase migration repair --status reverted 20260717000006` — marks the migration as not applied. Then fix the migration file and re-apply.

**For migrations applied to staging:** `supabase db reset` (destroys all data) — only acceptable on staging, never on production.

**For production schema issues:** Use Supabase point-in-time recovery (Pro plan). Do NOT manually write `DROP TABLE` or `ALTER TABLE DROP COLUMN` SQL. Create a new forward migration that corrects the issue.

### 9.4 Flutter App Rollback

**Android:** Publish the previous version to Play Store internal testing track; force-update targeted users.

**iOS:** TestFlight build versioning; revert to previous build.

**Emergency (before store release):** If the app is not yet in the stores, the rollback is to reinstall the previous debug APK/IPA on devices.

### 9.5 Feature Isolation Rollback

The Insights tab can be hidden from users without a code change by modifying the navigation guard in `app_router.dart` (on the `sprint-4-nav` branch). If the sprint-4-nav branch is already merged, a hotfix PR that sets a route guard condition is the fastest path to hide the feature while preserving all data.

This is why the `sprint-4-nav` branch is kept separate — it can be reverted in isolation.

### 9.6 Rollback SLOs

| Component | Target Rollback Time |
|-----------|---------------------|
| Edge Function to previous version | < 5 minutes |
| Cron job disable | < 2 minutes |
| Flutter feature hide (via nav guard) | < 30 minutes (hotfix PR + build) |
| Full database restore (Pro plan PITR) | < 15 minutes to initiate; 1–2 hours to complete |

---

## PART 10 — DOCUMENTATION REQUIREMENTS

### 10.1 What Must Be Documented

| Item | Where | When |
|------|-------|------|
| Phase 3.8 finding resolution | PR body, "Findings Addressed" section | In the PR that resolves it |
| Migration schema verification | PR body, test evidence section | Sprint 1 PR |
| Any deviation from Phase 5.0 spec | PR body, "Deviations" section | In the PR where deviation occurs |
| HMAC test results (MF-01) | Sprint 2 PR | Sprint 2 PR |
| CF-01 integration test results | Sprint 2 PR | Sprint 2 PR |
| Full pipeline E2E trace | Sprint 3 PR | Sprint 3 PR |
| GoRouter regression matrix | Sprint 4 PR | Sprint 4 PR |
| Performance SLO measurements | Sprint 4 PR | Sprint 4 PR |
| Deferred items (V2) | Issue tracker with `deferred` label | When item is deferred |

### 10.2 What Does NOT Need to Be Documented

- Code comments explaining what the code does (self-documenting names handle this)
- Step-by-step tutorials for using the implemented feature (product documentation; not engineering)
- Architecture rationale (already in Phase 1–3.8 documents)
- Sprint retrospective notes (captured in separate retro session, not in code)

### 10.3 Phase Document Update Protocol

The Phase 1–5.0 documents are reference documents — they are not updated after they are published. If an implementation decision deviates from a planning document:

1. Document the deviation in the PR
2. The PR becomes the canonical record of what was actually built
3. If the deviation is significant (affects architecture), the Engineering Director decides whether a Phase 6.1 amendment document is warranted

---

## PART 11 — LOGGING REQUIREMENTS

### 11.1 Required Log Events

Every Edge Function must emit these events. Missing events are a PR comment.

| Event | Function | Fields Required |
|-------|----------|----------------|
| `collect_insight.queued` | collect_insight | `raw_id`, `source_id`, `og_fetch_duration_ms`, `url_fingerprint` |
| `collect_insight.duplicate` | collect_insight | `url_fingerprint`, `existing_raw_id` |
| `collect_insight.rejected` | collect_insight | `reason_code`, `domain` |
| `validate_insight.result` | validate_insight | `raw_id`, `final_status`, `first_failure_check`, `duration_ms` |
| `validate_insight.relevance` | validate_insight | `raw_id`, `score`, `tier`, `passed` |
| `validate_insight.dedup` | validate_insight | `raw_id`, `is_duplicate`, `level` |
| `enrich_insight.ai_call` | enrich_insight | `raw_id`, `attempt`, `duration_ms`, `success`, `confidence` |
| `enrich_insight.image_mirror` | enrich_insight | `raw_id`, `insight_id`, `source`, `duration_ms` |
| `enrich_insight.complete` | enrich_insight | `raw_id`, `insight_id`, `total_duration_ms` |
| `enrich_insight.ai_error` | enrich_insight | `raw_id`, `attempt_count`, `final_error` |
| `activate_scheduled.run` | activate_scheduled_insights | `activated_count`, `insight_ids`, `duration_ms` |
| `expire_insights.run` | expire_old_insights | `archived_count`, `from_age`, `duration_ms` |
| `recover_stalled.run` | recover_stalled_insights | `recovered_count`, `raw_ids`, `duration_ms` |

### 11.2 Log Format

All events: `{"timestamp":"ISO8601","level":"INFO|WARN|ERROR","function_name":"...","execution_id":"...","event":"...","...additional fields"}`

**Level guidelines:**

| Level | When |
|-------|------|
| INFO | Normal operations: queued, validated, completed, activated, expired |
| WARN | Abnormal but recoverable: CF-01 recovery triggered (`recovered_count > 0`), injection anomaly detected (`OUTPUT_ANOMALY_DETECTED`), rate limit approaching |
| ERROR | Requires human intervention: 3 AI retries exhausted, DB write failure, storage write failure |

### 11.3 What Must NOT Be Logged

- `SUPABASE_SERVICE_ROLE_KEY` or any portion of it
- `ANTHROPIC_API_KEY` or any portion of it
- `WEBHOOK_SECRET` or any portion of it
- User email addresses or phone numbers
- Full JWT tokens
- Article content (only the `raw_id` and metadata fields)

---

## PART 12 — DEBUGGING WORKFLOW

### 12.1 Edge Function Debugging

```
Symptom: Function returns unexpected status / insight stuck in wrong status
     │
     ▼
Step 1: Supabase Dashboard → Edge Functions → {function} → Logs
        Filter by execution_id if available
        Look for ERROR level events
     │
     ▼
Step 2: Check the status of the insight row in the DB
        Direct query: SELECT status, updated_at FROM insights_raw WHERE id = '{raw_id}'
     │
     ▼
Step 3: If stuck in validated > 15 min → CF-01 recovery should have fired
        Check: Supabase → Edge Functions → recover_stalled_insights → Logs
        If cron not firing: check cron schedule in Scheduled Functions dashboard
     │
     ▼
Step 4: If AI error → check enrich_insight logs for the failing raw_id
        Look for: AI_MAX_RETRIES_EXCEEDED, AI_RESPONSE_PARSE_ERROR
        Check ANTHROPIC_API_KEY is set: Supabase → Edge Functions → Secrets
     │
     ▼
Step 5: If image mirror fails → check mirror_insight_image logs
        Common causes: og_image_url is null (use category default), dimension rejection (correct)
     │
     ▼
Step 6: Manual recovery (if cron has not yet run)
        Dashboard → Edge Functions → recover_stalled_insights → Invoke
        Confirm recovered_count in log
```

### 12.2 Flutter Debugging

```
Symptom: Feed not loading / blank screen / error state
     │
     ▼
Step 1: Flutter DevTools → Network tab
        Check: PostgREST query response status
        If 401: Supabase session expired; check auth token refresh
        If 0 rows: Check DB has active insights; check RLS policies
     │
     ▼
Step 2: Riverpod DevTools (if installed)
        Check insightsProvider state: isLoading, error, insights.length
     │
     ▼
Step 3: Cache issue
        Clear SharedPreferences manually (via device app settings → clear storage)
        Force fresh fetch
     │
     ▼
Step 4: Pre-fetch not firing
        Add temporary debug log at the fetchMore call site
        Verify index value at time of trigger
     │
     ▼
Step 5: GoRouter not navigating
        Check console for GoRouterException
        Verify route is declared in app_router.dart
        Check for duplicate route paths
```

### 12.3 Known Debugging Gotchas

| Symptom | Likely Cause | Resolution |
|---------|-------------|-----------|
| `validate_insight` returning 401 for all webhooks | WEBHOOK_SECRET mismatch between Dashboard and Supabase Secrets | Regenerate and re-set both simultaneously |
| Insights stuck in `validated` for hours | `recover_stalled_insights` cron not registered | Register cron in Dashboard; manually invoke once |
| AI enrichment always returning `ai_error` | ANTHROPIC_API_KEY missing or expired | Check Supabase Secrets; verify key is valid |
| `hero_image_url` missing WebP params | CDN URL constructed without the `?width=1200&quality=85&format=webp` suffix | Review `mirror_insight_image/index.ts` URL construction |
| Flutter feed query returns 0 rows | RLS policy filtering out non-active insights, or no active insights in DB | Manually activate one insight for testing; verify RLS policy |
| `copyWith` not preserving unchanged fields | Manual `copyWith` implementation bug | Add unit test for each field individually |

---

## PART 13 — ISSUE HANDLING & BLOCKER ESCALATION

### 13.1 Issue Classification

| Class | Definition | Response Time |
|-------|-----------|---------------|
| P0 BLOCKER | Sprint cannot progress; no workaround exists | Escalate to Engineering Director within 1 hour |
| P1 HIGH | Quality gate cannot pass without resolution | Tech Lead notified same day |
| P2 MEDIUM | Task cannot complete but sprint can continue on other tasks | Team discussion next standup |
| P3 LOW | Minor gap; documented as known issue | Log in issue tracker; resolve within same sprint if capacity allows |

### 13.2 Blocker Escalation Process

```
Engineer identifies blocker
     │
     ▼
Document in issue tracker:
- What is blocked
- Why it is blocked
- What was attempted
- What is needed to unblock
     │
     ▼
Notify Tech Lead via team channel immediately
     │
     ▼
Tech Lead assessment (within 2 hours):
     ├─ Can resolve → assigns resolution task; updates issue
     └─ Cannot resolve → escalates to Engineering Director
              │
              ▼
         Engineering Director decision (within 4 hours):
              ├─ Unblock internally → assigns to engineer
              ├─ External dependency → contacts vendor/supplier
              └─ Descope blocker to V2 → updates backlog; documents in issue tracker
```

### 13.3 External Blockers

The only P0 external dependency is `ANTHROPIC_API_KEY` procurement. If this is delayed past Sprint 2 Day 8:

1. Sprint 3 is paused
2. The team continues with any remaining Sprint 2 tasks or begins Flutter data layer work (S4-FL-001 through S4-FL-006 can begin without the AI pipeline)
3. Engineering Director escalates Anthropic account approval immediately
4. Sprint 3 begins as soon as the key is confirmed in Supabase Secrets

### 13.4 Issue Tracker Conventions

| Label | Usage |
|-------|-------|
| `sprint-1` through `sprint-4` | Issue belongs to that sprint |
| `finding` | Phase 3.8 mandatory finding tracked as issue |
| `critical-path` | Blocks the next sprint if not resolved |
| `blocked` | Waiting on external dependency |
| `bug` | Defect found during testing |
| `deferred` | Explicitly moved to V2 scope |
| `security` | Security-related finding or fix |

---

## PART 14 — TASK EXECUTION FRAMEWORK

This framework applies to every task in Phase 5.0. Engineers follow this sequence for every task they pick up.

### 14.1 Before Development

| Step | Action |
|------|--------|
| Read the spec | Open Phase 5.0 Part 3 and read the full task definition: Description, Dependencies, Inputs, Outputs, Verification, DoD |
| Verify prerequisites | Confirm all listed dependencies are complete and merged |
| Check for findings | If the task mentions a Phase 3.8 finding (CF-01, MF-01 through MF-07), read the finding in Phase 3.8 §3 before coding |
| Pull latest | `git pull origin <sprint-branch>` — work always starts from the latest state |
| Confirm you are on the correct branch | `git branch --show-current` must match your sprint |

### 14.2 During Development

| Step | Action |
|------|--------|
| Follow file placement | All files in the exact locations specified in Phase 5.0 Part 2 file tree |
| Log as you build | Add log events as you implement (not as an afterthought at the end) |
| Do not modify adjacent files | Only touch files listed in your task's "Outputs"; prohibited modifications listed per task |
| Commit incrementally | One commit per logical unit; do not accumulate a day's work in one commit |
| Run local verification | After implementing each logical unit, run the verification steps from Phase 5.0 |

**Prohibited modifications (all tasks):**
- Never modify a migration file from a previous sprint
- Never modify `_shared/types.ts` schema to remove or rename existing fields (only add)
- Never modify another sprint's feature files
- Never change the `app_router.dart` file outside of the sprint-4-nav branch

### 14.3 Before Merge

Complete every item in the applicable Section 5 code review checklist as the PR author before requesting review. A PR that fails the author's own checklist wastes reviewer time.

| Check | Action |
|-------|--------|
| Section 5.1 General | Review every item; fix before submitting for review |
| Section 5.2–5.8 Domain | Apply the domain-specific checklist for your task's area |
| Tests | All Phase 5.0 verification steps executed and documented |
| Lint | `deno lint` (Deno) / `flutter analyze` (Flutter) — zero errors |
| Format | `deno fmt` (Deno) / `dart format .` (Flutter) |
| PR template | Complete all sections |

### 14.4 Before Sprint Completion

| Check | Action |
|-------|--------|
| All tasks Done | Every issue for the sprint is in Done state in the tracker |
| Gate evidence assembled | All required evidence (test results, screenshots, log outputs) for the gate checklist collected |
| Gate checklist completed | Engineer completes the gate checklist (Section 15) and attaches to the sprint PR |
| PR approved and merged | Sprint PR merged to `main` |
| CI passing on main | Verify the main branch CI is green after merge |
| Next sprint prerequisites | Confirm any "before Sprint N+1 begins" conditions are met |

---

## PART 15 — SPRINT GATES

### Gate 1 — Database Ready

**Entry Criteria:** Phase 4.0 Section 1 checklist complete; MF-04 and MF-06 signed off; Supabase Pro plan confirmed.

**Required Evidence:**

| Evidence | Description |
|----------|-------------|
| Migration regression | `supabase db reset && supabase migration up` output — clean exit |
| Schema verification | `\d catalyst_insights` screenshot showing `is_evergreen`, `reviewed_by`, `reviewed_at` |
| Index count | `SELECT COUNT(*) FROM pg_indexes WHERE tablename IN (...)` = 14 |
| RLS matrix | 6-row PASS/FAIL table |
| Seed checklist | All 6 Phase 3.5 §5.5 assertions verified |
| Supabase Pro plan | Screenshot of billing page showing Pro plan active |
| WebP transform | `curl` response header showing `Content-Type: image/webp` |

**Exit Criteria:** All 7 evidence items collected; Sprint 1 PR merged to `main`; no migration errors.

**Blocking Conditions:**
- Any migration fails on fresh stack
- `is_evergreen`, `reviewed_by`, or `reviewed_at` absent from M03
- `idx_insights_raw_updated_at` absent from M05
- Any RLS test fails (anon blocked where it should be, or accessible where it should not)
- Seed row count ≠ 25
- Supabase Pro plan not confirmed

---

### Gate 2 — Pipeline Ready

**Entry Criteria:** Gate 1 passed; `WEBHOOK_SECRET` in Supabase Secrets; `collect_insight` deployed; `validate_insight` deployed; DB webhook configured.

**Required Evidence:**

| Evidence | Description |
|----------|-------------|
| Shared utility tests | All 8 utility test files passing; keyword scorer ≥15 cases |
| MF-01 HMAC test (3 cases) | Valid → 200; tampered → 401; missing → 401 — documented with request/response |
| CF-01 integration test | `recovered_count = 1` in log; `enrich_insight` invoked for test row |
| Submit → validated E2E | Test article: row reaches `validated` status; `validate_insight.result` log visible |
| CF-01 cron registered | Dashboard screenshot showing `*/30 * * * *` schedule |

**Exit Criteria:** All 5 evidence items collected; Sprint 2 PR merged to `main`.

**Blocking Conditions:**
- HMAC verification test fails (any of the 3 cases)
- CF-01 recovery cron not registered
- Webhook not firing on `insights_raw` INSERT
- Any shared utility test suite failing

---

### Gate 3 — AI Ready

**Entry Criteria:** Gate 2 passed; `ANTHROPIC_API_KEY` confirmed in Supabase Secrets; all Sprint 3 functions deployed; all 3 crons registered.

**Required Evidence:**

| Evidence | Description |
|----------|-------------|
| Full pipeline E2E | Article progresses `pending → validated → ai_processed → active`; all 8 AI fields present; CDN URL correct |
| MF-07 injection tests | `<INST>` stripped; "Ignore..." output → confidence = 0.0 |
| MF-05 dimension tests | 300×100 rejected; 400×200 accepted; unknown format accepted |
| Evergreen guard | `is_evergreen=true` insight survives `expire_old_insights` |
| 25s timeout | Log evidence showing per-attempt timeout is 25s |
| Cron dashboard | Screenshot showing all 3 crons at correct schedules |
| Batch approve disabled | Statement in PR confirming `batch_approve_high_confidence` not called |

**Exit Criteria:** All 7 evidence items; Sprint 3 PR merged; pipeline runs end-to-end without manual intervention.

**Blocking Conditions:**
- Full pipeline E2E fails
- MF-07 or MF-05 test cases fail
- Evergreen guard missing in `expire_old_insights`
- Anthropic per-attempt timeout > 25s
- `batch_approve_high_confidence` called in any function

---

### Gate 4 — Flutter Ready

**Entry Criteria:** Gate 3 passed; ≥10 active insights in staging DB; sprint-4-nav branch merged into sprint-4-flutter.

**Required Evidence:**

| Evidence | Description |
|----------|-------------|
| 8-scenario integration suite | All 8 scenarios documented as PASS with observable evidence |
| GoRouter regression matrix | All pre-existing routes verified working |
| Performance SLO table | P50/P95 measurements for all 5 SLOs |
| MF-03 verification | `InsightsAiErrorScreen` screenshot; retry button triggers `enrich_insight` log |
| MF-04 verification | Evergreen toggle visible in review card; DB update confirmed |
| MF-06 verification | `reviewed_by` and `reviewed_at` non-null after approve/reject/edit (3 DB screenshots) |
| flutter analyze | Output showing zero errors |

**Exit Criteria:** All 7 evidence items; Sprint 4 PR merged to `main`; Engineering Director approval given.

**Blocking Conditions:**
- Any of the 8 integration test scenarios fails
- GoRouter regression found
- Any Phase 3.8 Flutter finding (MF-03, MF-04, MF-06) unverified
- Performance SLO breach at P95
- `flutter analyze` errors

---

### Gate 5 — Production Ready

**Entry Criteria:** Gate 4 passed; Phase 4.0 Section 9 go-live criteria fully checked; Engineering Director approval received.

**Required Evidence:**

| Evidence | Description |
|----------|-------------|
| Phase 4.0 Section 9 | All 30+ checklist items checked with signatory |
| Production secrets | All secrets confirmed in production Supabase Secrets (not staging) |
| Production seed | 25 `insights_sources` rows in production; seed checklist passed |
| Production smoke test | At least 1 full pipeline run (submit → active) on production |
| Rollback verified | Each rollback path in Section 9.2 tested on staging |
| Anthropic spend alert | $10/month alert active on production API key |
| Batch approve disabled | Documented in Engineering Director's sign-off: disabled for 4 weeks from go-live date |

**Exit Criteria:** All 7 evidence items; Engineering Director signs go-live authorization; deployment to production authorized.

**Blocking Conditions:**
- Any production secret missing
- Production smoke test fails
- Any rollback path not verified
- Engineering Director has not signed go-live authorization

---

## PART 16 — DEFINITIONS

### 16.1 Definition of Ready (DoR)

A task is ready to begin when ALL of the following are true:

- [ ] The task has a Task ID from Phase 5.0 and a corresponding issue in the tracker
- [ ] The task's issue has an assigned owner
- [ ] All listed dependencies in Phase 5.0 are marked Done in the tracker
- [ ] The gating sprint's quality gate has passed (for subsequent sprint tasks)
- [ ] Any Phase 3.8 findings that block this task have been acknowledged (e.g., MF-04 signed off before S1-DB-003)
- [ ] Required secrets/env vars for this task are available in Supabase Secrets
- [ ] The engineer has read the Phase 5.0 task definition in full

### 16.2 Definition of Done (DoD)

A task is Done when ALL of the following are true:

- [ ] Implementation matches Phase 5.0 task specification (or deviation is documented)
- [ ] All Phase 3.8 finding requirements for this task are implemented and evidence recorded
- [ ] All verification steps from the Phase 5.0 task definition pass
- [ ] Tests written and passing (as specified in Section 5 checklists and Phase 5.0 task verification)
- [ ] `flutter analyze` zero errors (Flutter tasks)
- [ ] No `console.log` in Edge Function files
- [ ] No hardcoded secrets
- [ ] All required log events emitted (Backend tasks)
- [ ] Code reviewed by at least one other engineer
- [ ] Issue tracker updated to Done state
- [ ] Sprint board updated

### 16.3 Definition of Tested (DoT)

A task is Tested when ALL of the following are true:

- [ ] Every test case listed in the Phase 5.0 "Verification" field for the task has been executed
- [ ] All specified Phase 5.0 Validation Checkpoints (VCP-01 through VCP-17) for this sprint have passed
- [ ] Test results are documented with PASS/FAIL for each case
- [ ] Integration tests ran against the staging environment (not local)
- [ ] Edge cases verified: null inputs, empty results, auth failures, network failures
- [ ] Security-relevant tests verified: HMAC (S2-SEC-001), injection (S3-QA-002), RLS (S1-QA-002)

### 16.4 Definition of Released (DoR-Release)

A sprint's work is Released to production when ALL of the following are true:

- [ ] The corresponding gate (Gate 1–5) is passed with all required evidence
- [ ] All migrations are applied to the production database
- [ ] All Edge Functions are deployed to the production project
- [ ] All secrets are present in production Supabase Secrets
- [ ] Production smoke test passes
- [ ] Rollback path is verified
- [ ] Engineering Director has signed the go-live authorization

---

## PART 17 — RISK MANAGEMENT

### 17.1 High-Risk Components

| Component | Risk | Why High Risk | Mitigation |
|-----------|------|---------------|------------|
| `validate_insight` → `enrich_insight` handoff | CF-01 (CRITICAL) | Fire-and-forget; no guaranteed delivery | `recover_stalled_insights` cron every 30 min |
| HMAC webhook verification | MF-01 | Security boundary; incorrect implementation creates open endpoint | 3-case test suite; constant-time comparison |
| Anthropic AI enrichment | AI availability | External dependency; rate limits; response format changes | 3-retry with backoff; `ai_error` recovery UI; 25s timeout |
| GoRouter integration | mf-07 | Existing app navigation may conflict | Isolated to sprint-4-nav branch; regression test matrix |
| `InsightsState.copyWith` | mf-01 | 8-field manual copyWith is error-prone | Unit test all 8 fields individually; use Freezed if available |
| `ANTHROPIC_API_KEY` procurement | External | Only critical external dependency | Initiate Sprint 1 Day 1; escalate if not received by Sprint 2 Day 5 |

### 17.2 Fallback Procedures

| Scenario | Fallback |
|----------|---------|
| `enrich_insight` fails after 3 retries | Row → `ai_error`; admin retries manually via `InsightsAiErrorScreen` |
| OG image missing or invalid dimensions | Category default image used; pipeline continues |
| GoRouter conflict unresolvable | Defer Insights tab nav; serve Insights as a standalone modal route temporarily |
| Anthropic API unreachable | Insights pipeline pauses; existing `active` insights continue serving; admin notified via pipeline health |
| Supabase Storage outage | CachedNetworkImage serves cached images; new articles queued but not visible until storage recovers |
| `batch_approve_high_confidence` called prematurely | Revert the admin action; manually reject wrongly auto-approved items; document incident |

### 17.3 Rollback Strategy by Component

See Part 9 for detailed rollback procedures. Summary:

| Component | Rollback Method | Time to Rollback |
|-----------|----------------|-----------------|
| Edge Function | Supabase Dashboard version revert | < 5 min |
| Cron job | Dashboard disable | < 2 min |
| Database migration (staging) | `supabase migration repair` + fix | < 30 min |
| Database migration (production) | PITR restore (Engineering Director approval) | 1–2 hours |
| Flutter feature | sprint-4-nav revert or nav guard hotfix | < 30 min to build |

### 17.4 Incident Response

**Severity 1 (Production down — users see errors):**
1. Engineering Director and Tech Lead alerted immediately
2. Begin rollback of most recent deployment
3. Communicate status to team every 30 minutes
4. Post-mortem within 48 hours

**Severity 2 (Pipeline degraded — new insights not processing):**
1. Tech Lead alerted
2. Check pipeline health widget for stuck counts
3. Manually invoke `recover_stalled_insights`
4. If AI errors: check Anthropic API status; notify admin
5. Fix within 4 hours

**Severity 3 (Non-critical degradation — feature partial):**
1. Log issue in tracker with `bug` label
2. Fix in next available sprint slot
3. Document workaround if applicable

---

## PART 18 — DEVELOPER CHECKLISTS

### 18.1 Daily Checklist

Every engineer runs this at the start and end of each working day.

**Start of Day:**
- [ ] `git pull origin <sprint-branch>` — am I up to date?
- [ ] Are there any overnight PR comments I need to address?
- [ ] Is my assigned task still unblocked?
- [ ] Have I read the full Phase 5.0 task definition for what I'm working on today?
- [ ] Are the required secrets/environments available (Supabase CLI running, Supabase staging accessible)?

**End of Day:**
- [ ] Have I pushed all local commits to remote?
- [ ] Is there anything blocking me that needs escalation?
- [ ] Have I updated my task status in the issue tracker?
- [ ] If I opened a PR: is it assigned for review?
- [ ] If I received PR comments: have I addressed or acknowledged them?

### 18.2 Task Checklist

Run before marking a task as Done:

- [ ] Read Phase 5.0 task Definition of Done — every item checked
- [ ] All verification steps from Phase 5.0 task definition executed and passed
- [ ] No `console.log` in my files (Deno tasks)
- [ ] No hardcoded secrets in my files
- [ ] `flutter analyze` zero errors (Flutter tasks)
- [ ] `deno check` passes (Deno tasks)
- [ ] Required log events emitted (Deno tasks)
- [ ] Phase 3.8 finding requirements satisfied if this task addresses a finding
- [ ] Test results documented
- [ ] Issue moved to Done in tracker

### 18.3 Sprint Checklist

Run before submitting the sprint PR:

- [ ] All tasks in the sprint are Done in the tracker
- [ ] All Phase 5.0 Validation Checkpoints for this sprint are PASS
- [ ] All Phase 5.0 Deployment Checkpoints for this sprint are complete
- [ ] Gate evidence assembled and attached to PR body
- [ ] PR template complete
- [ ] PR assigned for review to Tech Lead
- [ ] Sprint 4 PR: assigned to Engineering Director as well

### 18.4 Release Checklist

Run before authorizing production deployment (Gate 5):

- [ ] Phase 4.0 Section 9 go-live criteria — all 30+ items checked
- [ ] All production secrets verified (SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY, ANTHROPIC_API_KEY, WEBHOOK_SECRET)
- [ ] Production Supabase project migrations applied successfully
- [ ] 25-row `insights_sources` seed in production
- [ ] At least 10 active insights manually approved and in production
- [ ] 6 category default images in production Storage bucket
- [ ] All 3 crons registered in production (`activate_scheduled`, `expire_old`, `recover_stalled`)
- [ ] Production smoke test: one full pipeline run completed
- [ ] All 5 performance SLOs measured in production (P95 targets met)
- [ ] All rollback paths verified on staging
- [ ] Spend alert active on production Anthropic API key
- [ ] `batch_approve_high_confidence` disabled for first 4 weeks — documented with go-live date
- [ ] Engineering Director signed go-live authorization

### 18.5 Hotfix Checklist

A hotfix is a critical production fix that cannot wait for the next sprint. Hotfixes bypass the normal sprint process but not the quality gates.

- [ ] Issue classified as Severity 1 or Severity 2 by Engineering Director
- [ ] Hotfix branch created from `main`: `hotfix/insights-{short-description}`
- [ ] Fix scope limited to the minimum change required to resolve the incident
- [ ] Fix does NOT introduce new features or refactor unrelated code
- [ ] Unit test written for the specific failure mode
- [ ] PR opened to `main` with `hotfix` label
- [ ] PR reviewed by Tech Lead (minimum 1 hour review)
- [ ] Deployed to staging and verified before production
- [ ] Production deployed and verified
- [ ] Hotfix branch deleted after merge
- [ ] Post-mortem scheduled within 48 hours

---

## PART 19 — QUALITY STANDARDS

### 19.1 Code Quality

| Standard | Measurement | Acceptance |
|----------|-------------|-----------|
| `deno lint` | Zero warnings or errors | Required before every PR |
| `flutter analyze` | Zero errors | Required before every PR; zero warnings target |
| `dart format .` | All files formatted | Required before every PR |
| `deno fmt` | All files formatted | Required before every PR |
| Test coverage | All Phase 5.0 task-specified test cases present | Gate requirement |
| Dead code | No unreferenced exports | Caught by `deno lint` / `flutter analyze` |

### 19.2 Architecture Compliance

| Area | Compliance Check |
|------|-----------------|
| Repository pattern | No Supabase client reference in widgets, screens, or providers |
| Riverpod pattern | All state through `NotifierProvider`; no `setState` in Insights feature |
| Shared utilities | No utility logic duplicated — always import from `_shared/` |
| Status machine | All status transitions match the 10-state pipeline machine |
| RLS | Service role only in Edge Functions; anon key in Flutter |
| Phase 5.0 file tree | All files in exact specified locations |

### 19.3 Documentation Completeness

| Item | Standard |
|------|---------|
| Phase 3.8 finding resolution | Every finding has documented evidence of resolution in the PR that resolves it |
| Deviations from spec | Every deviation documented with rationale in PR |
| Test evidence | Every test result documented with PASS/FAIL and the test conditions |
| Gate evidence | Every gate checklist item checked and evidence attached |

### 19.4 Performance Expectations

These are expectations during development, not just production SLOs:

| Expectation | Detail |
|-------------|--------|
| No unbounded queries | Every SELECT has WHERE or LIMIT |
| No N+1 patterns | Batch DB calls; no loops that issue per-item queries |
| Cache hit latency | Cache read path must complete in <100ms (synchronous SharedPreferences read) |
| Image memory | `memCacheWidth`/`memCacheHeight` on every `CachedNetworkImage` |
| Edge Function cold starts | Minimise module-level computation; import at top, compute at invocation |

### 19.5 Security Expectations

| Expectation | Detail |
|-------------|--------|
| Zero secrets in source | Verified by grep on every PR: `grep -r "ANON_KEY\|SERVICE_ROLE\|API_KEY\|secret" --include="*.ts" --include="*.dart"` |
| HMAC in place | `validate_insight` always verifies signature as first operation |
| Injection defenses in place | `enrich_insight` always sanitizes input and checks output |
| RLS bypasses audited | Any use of service role key in Flutter → immediate PR rejection |
| Logs audited | No PII or credential in any log statement |

### 19.6 Maintainability Requirements

| Requirement | Detail |
|-------------|--------|
| Naming clarity | Function and variable names describe their purpose; no single-letter variables outside loop indexes |
| Module size | Edge Function files > 200 lines suggest a split into a utility module |
| Test coverage | Every exported function has at least one passing test |
| Single responsibility | Each `_shared/` utility does one thing; `og_extractor.ts` does not score relevance |
| No magic numbers | All thresholds, timeouts, limits defined as named constants at module top |

---

## APPENDIX A — QUICK REFERENCE

### A.1 All Edge Function Endpoints

| Function | Trigger | Method | Auth |
|----------|---------|--------|------|
| `collect_insight` | Admin UI | POST | Admin JWT |
| `validate_insight` | Supabase DB Webhook | POST | HMAC signature |
| `enrich_insight` | Fire-and-forget from validate; CF-01 recovery | POST | Internal |
| `mirror_insight_image` | Called from enrich_insight | POST | Internal |
| `activate_scheduled_insights` | Cron `0/15 * * * *` | Scheduled | Cron |
| `expire_old_insights` | Cron `0 2 * * *` | Scheduled | Cron |
| `recover_stalled_insights` | Cron `*/30 * * * *` | Scheduled | Cron |

### A.2 All Environment Variables

| Variable | Functions That Use It | Set In | Sprint |
|----------|-----------------------|--------|--------|
| `SUPABASE_URL` | All | Supabase Secrets | Pre-S1 |
| `SUPABASE_SERVICE_ROLE_KEY` | All | Supabase Secrets | Pre-S1 |
| `ANTHROPIC_API_KEY` | enrich_insight | Supabase Secrets | Pre-S3 (procure in S1) |
| `WEBHOOK_SECRET` | validate_insight | Supabase Secrets | Pre-S2 |

### A.3 Phase 3.8 Finding Resolution Summary

| Finding | Resolved In | Evidence Required |
|---------|------------|-------------------|
| CF-01 | S2-BE-013 + S2-OPS-001 + S2-QA-002 | CF-01 integration test; cron dashboard screenshot |
| MF-01 | S2-BE-012 + S2-SEC-001 | HMAC 3-case test results |
| MF-03 | S4-AD-001 + S4-AD-005 + S4-AD-006 | AI error screen screenshot; retry log |
| MF-04 | S1-DB-003 (DB) + S4-FL-002 + S4-AD-003 (Flutter) | `\d catalyst_insights` screenshot; DB update after toggle |
| MF-05 | S3-AI-003 + S3-QA-003 | 3 dimension test case results |
| MF-06 | S1-DB-003 (DB) + S4-AD-001 + S4-AD-002 (Flutter) | 3 DB screenshots (approve/reject/edit) |
| MF-07 | S3-AI-001 + S3-AI-002 + S3-QA-002 | 2 injection test case results |

### A.4 CDN URL Format (Do Not Deviate)

```
{SUPABASE_URL}/storage/v1/object/public/insights-images/insights/{insight_id}/hero.jpg?width=1200&quality=85&format=webp
```

Category defaults:
```
{SUPABASE_URL}/storage/v1/object/public/insights-images/defaults/{category}.webp
```

Where `{category}` is one of: `grid_technology`, `energy_transition`, `industry_standards`, `engineering_leadership`, `policy_markets`, `innovation`.

---

## AUTHORIZATION

This playbook is the engineering operating manual for Catalyst Insights implementation. It takes effect when Sprint 1 is authorized. No deviations from Part 1 (Developer Rules) are permitted without Engineering Director sign-off.

**Playbook approved by:**

Engineering Director: _____________________________ Date: _______________

Tech Lead: _____________________________ Date: _______________

---

🟢 PHASE 6.0 COMPLETE — DEVELOPER EXECUTION PLAYBOOK LOCKED
