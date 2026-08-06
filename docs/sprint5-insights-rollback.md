# Catalyst Insights — Rollback Procedures

**Module:** Catalyst Insights  
**Version:** 1.0.0+1  
**Sprint:** Sprint 5 — Insights Integration  
**Date:** 2026-07-21

---

## When to Roll Back

Initiate a rollback if, after deploying the Catalyst Insights module, any of the following are observed:

| Trigger | Severity | Action |
|---------|----------|--------|
| App crashes on launch (not present in previous build) | P0 | Immediate rollback |
| All Insights screens crash or show blank | P0 | Immediate rollback |
| Auth flow broken (login impossible) | P0 | Immediate rollback |
| Existing features (feed, events, growth, etc.) broken | P0 | Immediate rollback |
| `/admin/insights/review` accessible by non-admin users | P0 | Immediate rollback + security review |
| Persistent error state on Insights feed (no data loads) | P1 | Investigate → rollback if not fixable in 2h |
| `collect-insight` Edge Function returns 5xx consistently | P1 | Check EF logs → rollback if EF is down |
| Submit Insight form submits but data does not reach DB | P1 | Check RLS → rollback if unrecoverable |

---

## Rollback Strategy

The Catalyst Insights module is **additive only**. It adds 6 new screens and 6 new routes to an existing app. No existing screens, routes, or database tables were modified.

This means:

- **Rolling back Flutter is sufficient** to fully remove the Insights feature from production.
- **No database migration rollback is needed** — the `catalyst_insights`, `insights_raw`, and `insights_sources` tables are pre-existing backend infrastructure that can remain safely regardless of the Flutter version.
- **No Edge Function rollback is needed** — `collect-insight` and `review-insight` are pre-existing functions that remain safe when not called.

---

## Flutter Rollback Procedure

### Step 1 — Identify the Last Known Good Build

```bash
git log --oneline -20
# Identify the commit before the Insights module was merged
# Target: the commit on main/staging prior to branch ui-v0-feed-migration merge
```

The last known stable commit before Insights integration is the most recent commit on `main` that does **not** include:
- `frontend/lib/features/insights/`
- `frontend/lib/core/router/app_router.dart` (Insights routes)

### Step 2 — Build the Rollback APK

```bash
git checkout <last-known-good-commit>
cd frontend
flutter clean
flutter pub get
flutter build apk --release \
  --dart-define=SUPABASE_URL=https://xispkgjjhqaiddbcaudt.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=<anon_key>
```

### Step 3 — Distribute the Rollback Build

- **Android**: Replace the APK in Firebase App Distribution / internal channel with the previous build artifact.
- **iOS TestFlight**: Re-submit the previous IPA build from App Store Connect → TestFlight → previous build.

### Step 4 — Verify the Rollback

After distributing:
1. Existing beta testers install the rolled-back build
2. Confirm the app launches without crash
3. Confirm auth flow works
4. Confirm the main feed, events, growth, and analytics work
5. Confirm `/insights` routes return 404 or are unreachable (not wired in the old router)

---

## Partial Rollback — Disable Insights Entry Points Only

If the app is otherwise healthy and only the Insights entry points need to be hidden (e.g., while a specific screen is fixed), the fastest option is a **route guard patch**:

1. Add a feature flag constant in `lib/core/config/env.dart` (or a local bool):
   ```dart
   static const bool insightsEnabled = bool.fromEnvironment('INSIGHTS_ENABLED', defaultValue: true);
   ```
2. In the navigation UI (wherever Insights links appear), gate on this flag:
   ```dart
   if (Env.insightsEnabled) context.go(RouteNames.insights);
   ```
3. Build with `--dart-define=INSIGHTS_ENABLED=false` to disable at runtime without removing code.

> Note: This is a mitigation, not a true rollback. It hides the UI but the routes still exist in the app binary.

---

## Backend Rollback (If Required)

The backend tables and Edge Functions are separate from the Flutter rollback.

### Roll Back an Edge Function

```bash
# Deploy a previous version of collect-insight or review-insight
supabase functions deploy collect-insight --project-ref xispkgjjhqaiddbcaudt
supabase functions deploy review-insight --project-ref xispkgjjhqaiddbcaudt
```

If the previous function version is in git history:
```bash
git checkout <previous-commit> -- backend/supabase/functions/collect-insight/
git checkout <previous-commit> -- backend/supabase/functions/review-insight/
supabase functions deploy collect-insight
supabase functions deploy review-insight
```

### Disable an Edge Function (Emergency)

In the Supabase dashboard:
1. Go to Edge Functions
2. Select the function
3. Toggle off or redeploy with a 503-returning stub

### Database: No Rollback Required

The Insights tables (`catalyst_insights`, `insights_raw`, `insights_sources`) were created in prior sprints and contain real data. Do **not** drop these tables as part of a Flutter rollback. They are safe to leave in place regardless of the Flutter version deployed.

---

## Rollback Decision Tree

```
App deployed to beta testers
        │
        ▼
Crash or P0 issue observed?
    YES → Immediate APK rollback (Steps 1-4 above)
    NO  → P1 issue observed?
              YES → Investigate root cause first
                    Fixable within 2h? YES → Deploy fix, no rollback
                                      NO  → APK rollback
              NO  → No action needed
```

---

## Post-Rollback Actions

After completing a rollback:

1. Document the failure in the incident log
2. Identify root cause using crash reports / Supabase logs
3. Fix in a new branch (do not re-use the rolled-back branch)
4. Re-run the full S5-INT-003 validation suite before next deployment
5. Obtain explicit sign-off before the next release attempt
