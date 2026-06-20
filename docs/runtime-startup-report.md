# Runtime Startup Report

## Launch Result: SUCCESS

| Check | Result |
|-------|--------|
| `flutter run -d chrome` | **PASS** — app launched in Chrome |
| Debug service | Connected (`ws://127.0.0.1:...`) |
| DevTools | Available |
| Crash | **None** |
| Fatal exceptions | **None** |

## Runtime Log

```
Launching lib\main.dart on Chrome in debug mode...
Waiting for connection from debug service on Chrome...             16.4s
Debug service listening on ws://127.0.0.1:55641/sDaStLpJp1w=/ws
A Dart VM Service on Chrome is available at: http://127.0.0.1:55641/sDaStLpJp1w=
The Flutter DevTools debugger and profiler on Chrome is available at: [...]
Starting application from main method in: org-dartlang-app:/web_entrypoint.dart.
```

## Runtime Messages

| Message | Severity | Source | Impact |
|---------|----------|-------|--------|
| `Passkeys Web SDK not loaded. Please include the Passkeys Web SDK (bundle.js)...` | Warning | `supabase_flutter` → `passkeys_web` | None — Passkeys not used by Manager Connect. Web Passkeys SDK is an optional feature of Supabase Auth for passwordless login via WebAuthn. Our app uses OTP, not Passkeys. |

## What Renders

With no `--dart-define` environment variables set:
- `Supabase.initialize()` is called with empty URL/key (from `String.fromEnvironment`)
- The GoRouter initializes and evaluates auth state
- `AuthNotifier` starts in `AppAuthStateInitial` state
- The route guard redirects to `/welcome` (no session)
- **Welcome screen renders** with app logo and "Get Started" button

## Fix Applied to Enable Launch

| File | Change | Reason |
|------|--------|--------|
| `pubspec.yaml` | Commented out `fonts:` section | Inter `.ttf` files not yet placed in `assets/fonts/Inter/`. Flutter fails asset bundling if declared fonts don't exist on disk. |

## Remaining Setup Items (not blockers)

| Item | Status | When Needed |
|------|--------|-------------|
| Inter font `.ttf` files | Not present | Before production — app falls back to system font |
| `--dart-define` for Supabase URL/key | Not set | Before connecting to Supabase backend |
| Firebase config files | Not present | Before push notifications work |
| Passkeys `bundle.js` | Not included | Never — OTP auth, not Passkeys |

## Bootstrap Pipeline Status

| Step | Status |
|------|--------|
| `flutter pub get` | **PASS** |
| `build_runner` | **PASS** — 4 providers, 8 outputs |
| `flutter analyze` | **PASS** — 0 issues |
| `flutter test` | **PASS** — 1 placeholder test |
| `flutter run -d chrome` | **PASS** — app launches, Welcome screen renders |
