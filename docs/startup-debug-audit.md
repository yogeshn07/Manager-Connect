# Startup Debug Audit

**Date:** 2026-06-22

---

## Root Cause

Two issues caused startup problems:

### Issue 1: Firebase.initializeApp() crash (FIXED)

`main.dart` called `await Firebase.initializeApp()` unconditionally. On web, Firebase requires configuration (JS SDK in `index.html` or `firebase_options.dart`). Neither existed. When Firebase init threw, `main()` crashed before reaching `runApp()`, producing a white screen.

**Fix:** Wrapped Firebase initialization in try-catch. App starts regardless of Firebase availability. FCM push notifications are a future feature.

### Issue 2: Env assertion crash (FIXED)

`assert(Env.isConfigured)` would crash in debug mode if `--dart-define` values were missing, again before `runApp()`.

**Fix:** Replaced assertion with a graceful fallback that renders a `_MissingEnvApp` widget showing a helpful message instead of crashing.

### Issue 3: Passkeys console warning (NON-BLOCKING)

`supabase_flutter` transitively depends on `passkeys_web`, which logs `"Error: Passkeys Web SDK not loaded"` to the console. This is a **warning**, not a crash — the app renders correctly despite it. The passkeys package is not used (we use OTP auth).

A minimal JavaScript stub was added to `index.html` to suppress the warning, but the passkeys_web package checks for a specific Corbado SDK global that the stub doesn't fully satisfy. The warning remains in the console but does not affect rendering.

---

## Files Modified

| File | Change |
|------|--------|
| `frontend/lib/main.dart` | Firebase try-catch, env graceful fallback, notification try-catch |
| `frontend/web/index.html` | Passkeys stub script, title update |

---

## Startup Flow (After Fix)

```
main()
  ├── WidgetsFlutterBinding.ensureInitialized()
  ├── Firebase.initializeApp() → try-catch (skipped on web without config)
  ├── Env.isConfigured check → if false, renders MissingEnvApp
  ├── Supabase.initialize(url, key)
  ├── NotificationService.initialize() → try-catch
  └── runApp(ProviderScope(child: App()))
        └── MaterialApp.router → GoRouter → SplashScreen
              └── AuthNotifier.initialize() → check session → redirect
```

---

## Launch Commands

### Debug mode (with local Supabase):

```
flutter run -d chrome \
  --dart-define=SUPABASE_URL=http://127.0.0.1:54321 \
  --dart-define=SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZS1kZW1vIiwicm9sZSI6ImFub24iLCJleHAiOjE5ODM4MTI5OTZ9.CRXP1A7WOeoJeXxjNni43kdQwgnWNReilDMblYTn_I0
```

### Static build + serve:

```
flutter build web \
  --dart-define=SUPABASE_URL=http://127.0.0.1:54321 \
  --dart-define=SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZS1kZW1vIiwicm9sZSI6ImFub24iLCJleHAiOjE5ODM4MTI5OTZ9.CRXP1A7WOeoJeXxjNni43kdQwgnWNReilDMblYTn_I0

cd build/web && python -m http.server 8080
# Open http://localhost:8080
```

---

## Verification Results

| Check | Result |
|-------|--------|
| `flutter analyze` | **No issues found** |
| `flutter test` | **All tests passed** |
| `flutter build web` | **Built successfully** |
| `flutter run -d chrome` | **Debug service connects, main() executes, zero Dart exceptions** |
| Static serve at localhost:8080 | **All assets load (HTML, JS, bootstrap)** |
| Post-startup errors (60s runtime) | **Zero** (only passkeys console warning) |

---

## First Rendered Screen

On startup:
1. `/` → **SplashScreen** (logo + "Manager Connect" + spinner)
2. `AuthNotifier.initialize()` checks session → no session found
3. Route guard redirects → `/welcome`
4. **WelcomeScreen** renders (email input + "Send OTP" button + "I have an invitation code")

---

## Console Output (Expected)

```
Starting application from main method in: org-dartlang-app:/web_entrypoint.dart.
Error: Passkeys Web SDK not loaded. [...]   ← non-blocking warning, app renders despite it
```

No Dart exceptions. No red screen. App navigates correctly.

---

## Verdict

### APPLICATION STARTUP VERIFIED
