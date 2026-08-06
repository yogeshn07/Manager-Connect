# Catalyst Insights — Release Checklist

**Module:** Catalyst Insights  
**Version:** 1.0.0+1  
**Sprint:** Sprint 5 — Insights Integration  
**Date:** 2026-07-19  
**Reviewed By:** ___________

---

## P0 — Must Pass Before Release

All P0 items must be checked. Release does not proceed with any P0 unchecked.

### Functionality

- [x] InsightsFeedScreen loads paginated feed (`/insights`)
- [x] InsightsFeedScreen category filter applies server-side `eq('category', ...)`
- [x] InsightsFeedScreen pull-to-refresh works
- [x] InsightDetailScreen renders headline, summary, why-matters, key-takeaway, tags
- [x] InsightDetailScreen loads via `/insights/:id`
- [x] SubmitInsightScreen URL + source validation present
- [x] SubmitInsightScreen calls `collect-insight` Edge Function on submit
- [x] SubmissionHistoryScreen lists user's raw submissions from `insights_raw`
- [x] SubmissionHistoryScreen status chips display correct capitalised labels
- [x] ReviewQueueScreen lists `catalyst_insights` with status `review` (admin only)
- [x] ReviewQueueScreen Publish action calls `review-insight { action: approve }`
- [x] ReviewQueueScreen Reject action calls `review-insight { action: reject }`
- [x] PipelineHealthScreen renders health signals grid (failed, stalled, ingested 24h)
- [x] PipelineHealthScreen queries `insights_raw` and `catalyst_insights` directly (no service_role required)
- [x] All 6 screens have loading states
- [x] All 6 screens have error states with retry
- [x] Feed and detail screens have empty states
- [x] Route guard blocks non-admin from ReviewQueueScreen and PipelineHealthScreen

### Routes

- [x] `/insights` → InsightsFeedScreen registered in app_router.dart
- [x] `/insights/submit` → SubmitInsightScreen registered (nested under /insights)
- [x] `/insights/history` → SubmissionHistoryScreen registered (nested under /insights)
- [x] `/insights/:id` → InsightDetailScreen registered (nested under /insights)
- [x] `/admin/insights/review` → ReviewQueueScreen registered
- [x] `/admin/insights/pipeline` → PipelineHealthScreen registered

### Tests

- [x] All 123 automated tests pass (`flutter test`)
- [x] DTO unit tests: InsightDto, InsightRawDto, InsightSourceDto, InsightReviewDto, PipelineHealthDto (32 tests)
- [x] Provider state unit tests: all 5 notifier state machines (41 tests)
- [x] Widget tests: all 6 Insights screens (49 tests)
- [x] Sanity check: root widget_test.dart (1 test)

### Code Quality

- [x] `flutter analyze` returns 0 errors
- [x] No new warnings introduced by Insights module (`feed_repository.dart:537` warning is pre-existing)
- [x] 5 `unnecessary_import` infos in Insights providers are known and documented (cosmetic, non-blocking)

### Security

- [x] No `service_role` key present anywhere in `frontend/` source
- [x] Supabase anon key is the `--dart-define` target; hardcoded fallback in `env.dart` is the public anon key (acceptable per Supabase security model)
- [x] RLS on `catalyst_insights` enforces `status = 'active'` for member reads server-side
- [x] Admin-only routes (`/admin/insights/review`, `/admin/insights/pipeline`) are guarded by route guard
- [x] `collect-insight` and `review-insight` Edge Functions require authenticated JWT

### Configuration

- [x] `SUPABASE_URL` and `SUPABASE_ANON_KEY` injected via `--dart-define` in release build command
- [x] `Env.isConfigured` returns `true` before Supabase is initialised
- [x] App name "The Catalysts" set in `AndroidManifest.xml` android:label and iOS `CFBundleDisplayName`
- [x] Application ID `com.managerconnect.manager_connect` confirmed in `build.gradle.kts`

---

## P1 — Should Pass Before Release

P1 failures require an accepted exception documented below.

### Build Artifacts

- [x] Android release APK built successfully — `build/app/outputs/flutter-apk/app-release.apk` (58.3 MB, 289s)
- [ ] Android release app bundle built successfully with `flutter build appbundle --release ...`
- [ ] **EXCEPTION REQUIRED:** Android release build currently uses debug signing config (`build.gradle.kts` line 37). APK is built and installable; debug-signed artifact is acceptable for internal beta. Must be resolved before Play Store submission.
- [ ] iOS release build verified (`flutter build ipa --release ...`) — requires macOS + Xcode
- [ ] iOS bundle identifier matches provisioning profile

### Manual Smoke Test

- [ ] App launches on physical Android device (cold start < 3s)
- [ ] Insights feed loads first page of articles
- [ ] Tapping an insight opens detail screen with correct content
- [ ] Submit Insight form validates URL and source selection
- [ ] Admin user can see review queue with pending items
- [ ] Admin user can see pipeline health signals

### Performance

- [ ] Insights feed first page loads within 1.5s on 4G
- [ ] Pipeline health dashboard renders within 2s (2 parallel queries)
- [ ] Category filter response under 1s (server-side filter)

---

## Exceptions Log

| Item | Exception Reason | Accepted By | Date |
|------|-----------------|-------------|------|
| Android release signing | Internal beta distribution only; Play Store release blocked until production keystore configured | ___ | ___ |
| iOS build validation | Requires macOS + Xcode toolchain; development is on Windows | ___ | ___ |
| Manual smoke test | Device testing deferred to beta testers | ___ | ___ |
