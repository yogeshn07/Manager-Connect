# Passkeys Fix Audit

**Date:** 2026-06-22

---

## Root Cause

The "Passkeys Web SDK not loaded" error is caused by `passkeys_web 2.9.0`, a **transitive dependency** of `supabase_flutter 2.15.0`.

```
supabase_flutter 2.15.0
  └── passkeys 2.20.0
        └── passkeys_web 2.9.0  ← requires JavaScript bundle on web
```

The passkeys package is bundled into the Supabase Flutter SDK for optional WebAuthn/passkey authentication. Our app uses OTP authentication, not passkeys — but the SDK loads the passkeys module on web regardless and prints an error when the JavaScript bundle is missing.

### Key Facts

- `passkeys` is NOT in `pubspec.yaml` (not a direct dependency)
- `passkeys` is NOT imported in any Dart file (zero imports)
- Removing it is impossible without forking `supabase_flutter`
- The error is a **console warning**, not a runtime crash — the app still runs

---

## Fix Applied

Added the Passkeys Web SDK script to `web/index.html`:

```html
<script src="https://github.com/corbado/flutter-passkeys/releases/download/2.4.0/bundle.js" defer></script>
```

This provides the JavaScript global that `passkeys_web` looks for, silencing the error. The `defer` attribute ensures it loads after HTML parsing without blocking the page.

---

## Files Modified

| File | Change |
|------|--------|
| `frontend/web/index.html` | Added passkeys SDK script tag, updated title to "Manager Connect" |

---

## Validation Results

| Check | Before Fix | After Fix |
|-------|-----------|-----------|
| `flutter analyze` | No issues | **No issues** |
| `flutter test` | All passed | **All passed** |
| `flutter build web` | Built | **Built** |
| `flutter run -d chrome` | Launches with passkeys error | **Launches clean** |
| Console error "Passkeys Web SDK not loaded" | Present | **Gone** |

---

## Local Access

When running `flutter run -d chrome`, the debug service assigns a dynamic port:

```
Debug service listening on ws://127.0.0.1:{PORT}/{TOKEN}/ws
```

The app opens automatically in Chrome. The DevTools URL is printed in the console. The port changes each run.

---

## Production Note

The script tag loads from GitHub. For production deployment, download `bundle.js` locally and serve it from the app's own web directory to avoid external dependency.

---

## Verdict

### PASSKEYS ISSUE RESOLVED
