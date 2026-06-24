# REM-07: Auth Callback URL Cleanup

## Problem

After magic link authentication, the `?code=` query parameter from Supabase Auth persists in the browser URL across all navigation. Example: `localhost:4200/?code=15616c71-95d3-4f73-8399-7d02f385a06f#/feed`

## Severity: LOW (cosmetic)

## Root Cause

Supabase Auth redirects back to the app with `?code=` in the URL. Flutter web's hash-based routing (`/#/`) preserves the query parameter because it sits before the hash. GoRouter does not strip it.

## Fix

In the `SplashScreen` or `AuthNotifier.initialize()`, after session is confirmed, use `window.history.replaceState` via `dart:html` to clean the URL:

```dart
import 'dart:html' as html;

// After auth confirmed:
final uri = Uri.parse(html.window.location.href);
if (uri.queryParameters.containsKey('code')) {
  html.window.history.replaceState(null, '', uri.replace(queryParameters: {}).toString());
}
```

## Files Impacted

| File | Change |
|------|--------|
| `frontend/lib/features/auth/presentation/providers/auth_notifier.dart` | ADD — URL cleanup after `handleSignIn()` |

## Estimated Effort: 30 minutes
