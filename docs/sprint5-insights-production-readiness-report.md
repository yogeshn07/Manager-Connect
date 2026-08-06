# Catalyst Insights — Production Readiness Report

**Module:** Catalyst Insights  
**Version:** 1.0.0+1  
**Sprint:** Sprint 5 — Insights Integration (S5-INT-001 → S5-INT-003)  
**Report Date:** 2026-07-21  
**Branch:** ui-v0-feed-migration

---

## Executive Summary

The Catalyst Insights module is **READY FOR INTERNAL BETA**. All 6 screens are implemented, all 6 routes are wired, 123/123 automated tests pass, and the analyzer reports zero errors. One deployment prerequisite remains outstanding before Play Store distribution: Android release signing must be migrated from the debug keystore to a production keystore.

**Production Readiness Score: 90 / 100**  
**Recommendation: DEPLOY TO INTERNAL BETA — Hold for production keystore before Play Store**

---

## 1. Repository Intelligence Report

### Module Scope

| Item | Detail |
|------|--------|
| Feature | Catalyst Insights — curated AI-enriched industry insights pipeline |
| User roles | Members (read + submit), Admins (review + pipeline monitoring) |
| Screens delivered | 6 |
| Routes registered | 6 |
| Database tables | catalyst_insights, insights_raw, insights_sources |
| Edge Functions called | collect-insight, review-insight |
| Sprint tasks | S5-INT-001 (screens + providers), S5-INT-002 (tests), S5-INT-003 (this report) |

### Architecture Assessment

| Layer | Implementation | Status |
|-------|---------------|--------|
| Data — DTOs | InsightDto, InsightRawDto, InsightSourceDto, InsightReviewDto, PipelineHealthDto | ✓ |
| Data — Repository | InsightRepository (Supabase + EF calls) | ✓ |
| State — Providers | 5 Riverpod notifiers (Riverpod 3.x, riverpod_annotation) | ✓ |
| Presentation — Screens | 6 screens, all with loading / error / empty / data states | ✓ |
| Navigation | GoRouter — 6 routes, 4 nested under /insights, 2 under /admin | ✓ |
| Route constants | RouteNames.insights, .insightSubmit, .insightHistory, .insightDetail, .adminInsightReview, .adminInsightPipeline | ✓ |
| Clean Architecture | Feature → Data → Domain boundary respected; no cross-feature imports | ✓ |

### Screen Inventory

| Screen | Route | Auth | Admin Only |
|--------|-------|------|------------|
| InsightsFeedScreen | /insights | ✓ | — |
| InsightDetailScreen | /insights/:id | ✓ | — |
| SubmitInsightScreen | /insights/submit | ✓ | — |
| SubmissionHistoryScreen | /insights/history | ✓ | — |
| ReviewQueueScreen | /admin/insights/review | ✓ | ✓ |
| PipelineHealthScreen | /admin/insights/pipeline | ✓ | ✓ |

---

## 2. Production Validation Results

### 2a. Flutter Analyze

| Category | Count | Assessment |
|----------|-------|------------|
| Errors | **0** | ✓ PASS |
| Warnings | **1** | Pre-existing: `unnecessary_cast` in `feed_repository.dart:537` (not in Insights module) |
| Infos — Insights module | **5** | `unnecessary_import` in 5 Insights providers (flutter_riverpod re-exported by riverpod_annotation) |
| Infos — Test files | **22** | `prefer_const_constructors` in S5-INT-002 test files |
| Infos — Other production files | **5** | `prefer_const_constructors` in feed/growth/notification files (pre-existing) |
| **Total issues** | **33** | Exit code 1 (any issue = exit 1) |

**Verdict: PASS.** Zero analyzer errors. The single warning is pre-existing and unrelated to the Insights module. All infos are cosmetic. No Insights module code changes are required.

### 2b. Flutter Test

| Suite | Tests | Pass | Fail |
|-------|-------|------|------|
| DTO unit tests | 32 | 32 | 0 |
| Provider state unit tests | 41 | 41 | 0 |
| Widget tests (6 screens) | 49 | 49 | 0 |
| Sanity (widget_test.dart) | 1 | 1 | 0 |
| **Total** | **123** | **123** | **0** |

**Verdict: PASS.** All 123 tests pass. Test run completed in approximately 18 seconds.

### 2c. Android Release Build

| Item | Status |
|------|--------|
| Build configuration reviewed | ✓ |
| `applicationId` | com.managerconnect.manager_connect |
| `compileSdkVersion` | flutter.compileSdkVersion |
| `minSdkVersion` | flutter.minSdkVersion |
| Java compatibility | Java 17 (source + target) |
| `desugar_jdk_libs` | 2.1.4 (core library desugaring enabled) |
| Release signing config | **DEBUG KEYSTORE** (TODO in build.gradle.kts:37) |
| Build artifact | ✅ `build/app/outputs/flutter-apk/app-release.apk` (58.3 MB, 289s) |
| Font tree-shaking | MaterialIcons-Regular.otf: 1.6 MB → 23 KB (98.6% reduction). CupertinoIcons font note (non-blocking). |

> **KNOWN RISK (P1):** The release build target in `build.gradle.kts` uses `signingConfigs.getByName("debug")`. A build artifact signed with the debug keystore is suitable only for internal beta distribution (direct APK install, Firebase App Distribution). It **cannot** be submitted to the Play Store. A production keystore must be created and wired before Play Store submission. See `sprint5-insights-deployment.md` § 3 for signing configuration steps.

### 2d. iOS Build Validation

| Item | Status |
|------|--------|
| CFBundleDisplayName | "The Catalysts" ✓ |
| CFBundleIdentifier | $(PRODUCT_BUNDLE_IDENTIFIER) ✓ |
| CFBundleShortVersionString | $(FLUTTER_BUILD_NAME) → 1.0.0 ✓ |
| CFBundleVersion | $(FLUTTER_BUILD_NUMBER) → 1 ✓ |
| Portrait orientation | Supported ✓ |
| Full build validation | **DEFERRED** — requires macOS + Xcode |

### 2e. Dependency Audit

**Tool:** `flutter pub outdated`

| Category | Result |
|----------|--------|
| Security advisories for locked versions | None identified |
| Upgradable within current constraints | 17 packages (minor/patch, non-breaking) |
| Resolvable with constraint relaxation | 30 packages (includes major-version upgrades) |
| `path_provider_foundation` override | 2.4.4 — intentional, documented (dart-lang/native#2993) |

**Key packages — locked version assessment:**

| Package | Locked | Upgradable To | Risk |
|---------|--------|--------------|------|
| supabase_flutter | 2.15.0 | 2.16.0 | LOW — patch, no breaking changes |
| firebase_messaging | 15.2.10 | 16.4.3 | OUT OF SCOPE — major version |
| firebase_core | 3.15.2 | 4.12.1 | OUT OF SCOPE — major version |
| go_router | 14.8.1 | 17.3.0 | OUT OF SCOPE — major version |
| flutter_riverpod | 3.0.3 | 3.3.2 | LOW — patch within ^3.0.3 constraint |
| google_fonts | 8.1.0 | 8.2.0 | LOW — minor, upgradable now |
| path_provider_foundation | 2.4.4 (override) | 2.6.0 | HOLD — override intentional |

**Verdict:** No known CVEs or security advisories at the locked versions. The 17 upgradable packages represent normal package drift acceptable for an internal beta release.

---

## 3. Security Configuration Review

| Check | Finding | Status |
|-------|---------|--------|
| `service_role` key in Flutter source | Not present in any `frontend/` file | ✓ PASS |
| Supabase anon key exposure | Hardcoded in `env.dart` as fallback; also injected via `--dart-define`. Anon key is public by Supabase design. | ✓ ACCEPTABLE |
| `--dart-define` injection | `SUPABASE_URL` and `SUPABASE_ANON_KEY` supported | ✓ PASS |
| `Env.isConfigured` guard | Checked before Supabase.initialize() | ✓ PASS |
| RLS on `catalyst_insights` | Members see only `status = 'active'` rows (server-side) | ✓ PASS |
| RLS on `insights_raw` | Users see only `submitted_by = auth.uid()` rows | ✓ PASS |
| Admin route guard | `/admin/insights/review` and `/admin/insights/pipeline` require `is_admin = true` | ✓ PASS |
| Edge Function auth | `collect-insight` and `review-insight` require valid JWT | ✓ PASS |
| `review-insight` admin check | Admin status re-verified server-side in EF, not trusted from client | ✓ PASS |
| No user PII logged | No `print()` or `debugPrint()` of user data in Insights screens | ✓ PASS |
| `insights_raw` write-block | RLS policy `insights_raw_update_blocked` prevents client-side UPDATE | ✓ PASS |

---

## 4. Environment Configuration Verification

| Config Item | Mechanism | Value | Status |
|-------------|-----------|-------|--------|
| Supabase URL | `--dart-define=SUPABASE_URL` → `Env.supabaseUrl` | xispkgjjhqaiddbcaudt.supabase.co (fallback) | ✓ |
| Supabase Anon Key | `--dart-define=SUPABASE_ANON_KEY` → `Env.supabaseAnonKey` | Hardcoded anon key (fallback) | ✓ |
| App name (Android) | `AndroidManifest.xml` android:label | "The Catalysts" | ✓ |
| App name (iOS) | `Info.plist` CFBundleDisplayName | "The Catalysts" | ✓ |
| Application ID | `build.gradle.kts` applicationId | com.managerconnect.manager_connect | ✓ |
| Version name | `pubspec.yaml` version | 1.0.0 | ✓ |
| Version code | `pubspec.yaml` version | +1 | ✓ |
| Flutter SDK | `pubspec.yaml` environment.flutter | >=3.38.0 | ✓ |
| Dart SDK | `pubspec.yaml` environment.sdk | >=3.9.0 <4.0.0 | ✓ |
| `path_provider_foundation` override | `pubspec.yaml` dependency_overrides | 2.4.4 | ✓ (documented) |

---

## 5. Logging Verification

| Screen/Layer | Logging Behaviour | Status |
|-------------|-------------------|--------|
| InsightRepository | Errors mapped via `mapSupabaseError()` → `AppException` | ✓ |
| AppException | `toString()` → `AppException(statusCode): message` | ✓ |
| mapSupabaseError | Handles AuthException, PostgrestException, FunctionException | ✓ |
| All screens | Errors surfaced as UI state (`error` field on state) | ✓ |
| No production `print()` | No unguarded print/debugPrint in Insights files | ✓ |
| Supabase client logs | Controlled by `supabase_flutter` — no custom log hooks needed | ✓ |

---

## 6. Error-Handling Validation

| Failure Scenario | Screen | Behaviour |
|-----------------|--------|-----------|
| Network error loading feed | InsightsFeedScreen | "Failed to load insights" + "Try again" button |
| Network error loading detail | InsightDetailScreen | "Failed to load insight" + "Try again" button |
| Sources fail to load | SubmitInsightScreen | "Failed to load sources — tap to retry" |
| Submit returns error | SubmitInsightScreen | Error message surfaced in `submissionError` field |
| History fails to load | SubmissionHistoryScreen | "Could not load submissions" |
| Review queue fails | ReviewQueueScreen | Shared `ErrorState` with "Something went wrong" + "Try Again" |
| Pipeline health fails | PipelineHealthScreen | Shared `ErrorState` with "Something went wrong" + "Try Again" |
| User not logged in | SubmissionHistoryScreen | Guards on `auth.currentUser == null` → empty state |
| Supabase 403 (RLS) | Any screen | Maps to `AppException` → error state |
| Edge Function 4xx | SubmitInsightScreen, ReviewQueueScreen | `AppException` from `_checkEfResponse()` → error state |

---

## 7. Performance Sanity Validation

| Scenario | Implementation | Assessment |
|----------|---------------|------------|
| Feed pagination | 20 items per page; `range(page*20, page*20+19)` | ✓ Bounded |
| Infinite scroll trigger | `loadMore()` called on scroll end; `hasMore` guards extra calls | ✓ |
| Category filter | Server-side `.eq('category', ...)` — no client-side filter | ✓ |
| Pipeline health queries | 2 queries (rawRows + ciRows); in-memory aggregation | ✓ |
| Latency sample cap | `latencySamples.length < 50` limits computation | ✓ |
| Stale threshold | 15-minute window computed via `DateTime.now().toUtc().subtract(...)` | ✓ |
| Image loading | `hero_image_url` loaded lazily by Flutter's Image widget | ✓ |
| Pull-to-refresh | Resets state and re-runs full load (intentional) | ✓ |

---

## 8. Files Created — S5-INT-003

All files are new. No production files were modified.

| File | Purpose |
|------|---------|
| `docs/sprint5-insights-release-checklist.md` | P0/P1 release gate checklist |
| `docs/sprint5-insights-deployment.md` | Build, sign, and distribute instructions |
| `docs/sprint5-insights-rollback.md` | Rollback decision tree and procedures |
| `docs/sprint5-insights-runbook.md` | Operational monitoring and incident response |
| `docs/sprint5-insights-production-readiness-report.md` | This document |

---

## 9. Files Created — S5-INT-002 (Prior Task, Reference)

| File | Tests |
|------|-------|
| `frontend/test/helpers/insight_fixtures.dart` | Shared test data |
| `frontend/test/unit/features/insights/data/models/insight_dto_test.dart` | 8 tests |
| `frontend/test/unit/features/insights/data/models/insight_raw_dto_test.dart` | 6 tests |
| `frontend/test/unit/features/insights/data/models/insight_source_dto_test.dart` | 5 tests |
| `frontend/test/unit/features/insights/data/models/insight_review_dto_test.dart` | 7 tests |
| `frontend/test/unit/features/insights/data/models/pipeline_health_dto_test.dart` | 6 tests |
| `frontend/test/unit/features/insights/presentation/providers/insights_provider_state_test.dart` | 8 tests |
| `frontend/test/unit/features/insights/presentation/providers/pipeline_health_provider_state_test.dart` | 8 tests |
| `frontend/test/unit/features/insights/presentation/providers/review_queue_provider_state_test.dart` | 9 tests |
| `frontend/test/unit/features/insights/presentation/providers/submit_insight_provider_state_test.dart` | 9 tests |
| `frontend/test/unit/features/insights/presentation/providers/submission_history_provider_state_test.dart` | 7 tests |
| `frontend/test/widget/features/insights/insights_feed_screen_test.dart` | 9 tests |
| `frontend/test/widget/features/insights/insight_detail_screen_test.dart` | 8 tests |
| `frontend/test/widget/features/insights/submit_insight_screen_test.dart` | 8 tests |
| `frontend/test/widget/features/insights/submission_history_screen_test.dart` | 7 tests |
| `frontend/test/widget/features/insights/review_queue_screen_test.dart` | 8 tests |
| `frontend/test/widget/features/insights/pipeline_health_screen_test.dart` | 9 tests |

---

## 10. Files Modified

**Zero production files modified during S5-INT-002 or S5-INT-003.**

All work was delivered as new files only, in accordance with Phase 9 Feature Integration Guardian rules (SAFE = new files only; FORBIDDEN = modifying production files).

---

## 11. Remaining Risks

| Risk | Severity | Status | Mitigation |
|------|----------|--------|------------|
| Android release build uses debug signing | P1 | OPEN | Acceptable for internal beta; create production keystore before Play Store (see deployment doc §3) |
| iOS build not validated on macOS | P1 | OPEN | Deferred to macOS build machine; iOS config verified at Info.plist level |
| No end-to-end smoke test on physical device | P1 | OPEN | Deferred to beta testers; all unit + widget tests pass |
| 5 `unnecessary_import` infos in Insights providers | P2 | ACCEPTED | Cosmetic; `flutter_riverpod` is already provided by `riverpod_annotation`. Removing requires modifying production files (FORBIDDEN in Phase 9). |
| 17 packages upgradable (minor/patch) | P2 | ACCEPTED | No CVEs at locked versions; upgrade deferred to maintenance sprint |
| `avgTimeToPublishMs` accuracy | P3 | ACCEPTED | Sample ≤50 rows; acknowledged in runbook |
| Supabase anon key hardcoded as fallback | P3 | ACCEPTED | Anon key is public by design; documented in security review |

---

## 12. Production Readiness Score

| Category | Weight | Score | Notes |
|----------|--------|-------|-------|
| Functionality | 20 | **18/20** | All screens + routes working; no manual device smoke test |
| Test Coverage | 20 | **19/20** | 123/123 pass; no integration tests against live backend |
| Code Quality | 20 | **17/20** | 0 errors; 5 cosmetic infos in Insights providers; pre-existing warning |
| Security | 20 | **19/20** | All security checks pass; anon key fallback acceptable |
| Release Readiness | 20 | **17/20** | Android APK built ✅ (58.3 MB, debug-signed); iOS unverified; no production signing yet |
| **Total** | **100** | **90/100** | |

---

## 13. Sprint Progress

| Task | Status | Deliverables |
|------|--------|-------------|
| S5-INT-001 | COMPLETE | 6 screens, 5 providers, 3 DTOs, InsightRepository |
| S5-INT-002 | COMPLETE | 123/123 tests passing across 17 test files |
| S5-INT-003 | **COMPLETE** | Analyzer validation, test validation, dependency audit, security review, 5 doc files |

**Sprint 5 Insights Integration: COMPLETE**

---

## 14. Overall Progress

| Sprint | Status | Key Deliverable |
|--------|--------|----------------|
| Sprint 1 | COMPLETE | 6 Edge Functions, database bootstrap |
| Sprint 2 | COMPLETE | 4 Edge Functions, auth + profiles |
| Sprint 3 | COMPLETE | 4 Edge Functions, events + polls |
| Sprint 4 | COMPLETE | 4 Edge Functions, growth + analytics |
| Sprint 5 (backend) | COMPLETE | 3 Edge Functions, scheduled jobs |
| Sprint 5 (Insights) | **COMPLETE** | Catalyst Insights module + tests + release validation |

**Cumulative Edge Functions: 21/21**  
**Flutter Insights Screens: 6/6**  
**Automated Tests: 123 passing**  
**Overall Project: READY FOR INTERNAL BETA**

---

## 15. Final Deployment Recommendation

**APPROVED FOR INTERNAL BETA DISTRIBUTION**

The Catalyst Insights module meets all P0 release gates:

- ✅ All 6 screens implemented with full state handling
- ✅ All 6 routes registered and guarded appropriately
- ✅ 123/123 automated tests passing
- ✅ Zero analyzer errors
- ✅ Security configuration verified (no secrets, RLS enforced, admin routes guarded)
- ✅ Error handling validated for all failure scenarios
- ✅ Deployment, rollback, and operational runbook documentation complete

**BLOCKED FOR PLAY STORE** until:

1. Production keystore created and wired in `build.gradle.kts` (see `sprint5-insights-deployment.md` §3)
2. Android release APK/AAB re-built and verified with production signing
3. iOS build validated on macOS with correct provisioning profile

**Next action:** Distribute debug-signed APK to internal beta testers. Collect feedback. Address Android signing and iOS validation before public release.
