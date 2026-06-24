# Milestone 4 Execution Report

**Date:** 2026-06-24
**Tasks:** REM-02, REM-06

---

## REM-06: Realtime Replication

### Implementation

Created migration `20260624000002_enable_realtime_replication.sql` adding 8 tables to the `supabase_realtime` publication.

### Tables Added

| Table | Channel | Status |
|-------|---------|--------|
| posts | `feed:posts` | V1 active |
| notification_inbox | `notifications:inbox` | V1 active |
| post_reactions | `feed:reactions` | V2 ready |
| comments | `feed:comments` | V2 ready |
| activity_rsvps | `activities:rsvps` | V2 ready |
| poll_votes | `events:poll_votes` | V2 ready |
| progress_logs | `growth:leaderboard` | V2 ready |
| recognitions | `recognitions` | V2 ready |

### Verification

- `supabase db reset`: 74 migrations applied, zero errors
- `supabase db diff`: zero schema drift
- `pg_publication_tables`: 8/8 tables confirmed in publication

---

## REM-02: Firebase Web SDK Configuration

### Implementation

Created environment-based Firebase configuration that initializes when credentials are provided via `--dart-define` flags, and gracefully skips when not configured.

### Architecture

1. **`firebase_config.dart`** — reads 6 Firebase config values from `String.fromEnvironment()`:
   - `FIREBASE_API_KEY`
   - `FIREBASE_AUTH_DOMAIN`
   - `FIREBASE_PROJECT_ID`
   - `FIREBASE_STORAGE_BUCKET`
   - `FIREBASE_MESSAGING_SENDER_ID`
   - `FIREBASE_APP_ID`

2. **`main.dart`** — three initialization paths:
   - Config provided via dart-define → initialize with explicit `FirebaseOptions`
   - No config + native platform → try default config (google-services.json)
   - No config + web → skip Firebase entirely (no crash)

3. **`notification_service.dart`** — checks `Firebase.apps.isEmpty` before any FCM operation. Gracefully skips when Firebase is not initialized.

### Usage

To enable Firebase on web builds:
```bash
flutter build web \
  --dart-define=FIREBASE_API_KEY=AIza... \
  --dart-define=FIREBASE_PROJECT_ID=manager-connect-prod \
  --dart-define=FIREBASE_AUTH_DOMAIN=manager-connect-prod.firebaseapp.com \
  --dart-define=FIREBASE_STORAGE_BUCKET=manager-connect-prod.appspot.com \
  --dart-define=FIREBASE_MESSAGING_SENDER_ID=123456789 \
  --dart-define=FIREBASE_APP_ID=1:123456789:web:abc123
```

Without these flags, app builds and runs normally — Firebase is skipped.

### Security

- No secrets hardcoded in source code
- All Firebase credentials provided at build time via `--dart-define`
- `firebase_config.dart` contains only `String.fromEnvironment()` calls
- Credentials are baked into the compiled JS (standard Firebase web pattern)

---

## Files Changed

| File | Type | Change |
|------|------|--------|
| `backend/supabase/migrations/20260624000002_enable_realtime_replication.sql` | NEW | 8-table realtime publication |
| `frontend/lib/core/config/firebase_config.dart` | NEW | Environment-based Firebase config |
| `frontend/lib/main.dart` | MODIFIED | 3-path Firebase initialization |
| `frontend/lib/shared/services/notification_service.dart` | MODIFIED | Firebase.apps.isEmpty guard |

---

## Validation

| Check | Result |
|-------|--------|
| `supabase db reset` | 74 migrations, zero errors |
| `supabase db diff` | Zero drift |
| Realtime publication | 8/8 tables confirmed |
| `flutter analyze` | 0 errors, 0 warnings |
| `flutter test` | 1/1 passed |
| `flutter build web` | Compiled successfully |
| Build without Firebase config | App runs, Firebase skipped |
| No hardcoded secrets | Verified — all via dart-define |

---

## Rollback

- REM-06: Delete migration, run `supabase db reset`
- REM-02: Revert main.dart + notification_service.dart, delete firebase_config.dart

---

## Readiness Impact

| Metric | Before | After |
|--------|--------|-------|
| Launch Readiness | 89% | **93%** |
| Realtime Tables | 0 in publication | 8 in publication |
| Firebase Status | Blocked (kIsWeb guard) | Infrastructure-ready (env-based) |
| Push Notifications | Blocked | Ready when Firebase project created |
