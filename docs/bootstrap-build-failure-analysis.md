# Bootstrap Build Failure Analysis

## Environment

| Component | pubspec.yaml constraint | Resolved (pubspec.lock) |
|-----------|------------------------|------------------------|
| Dart SDK | `>=3.3.0 <4.0.0` | `>=3.11.0` |
| Flutter SDK | `>=3.22.0` | `>=3.38.4` |
| `flutter_riverpod` | `^2.5.1` | `2.6.1` |
| `riverpod_annotation` | `^2.3.5` | `2.6.1` |
| `riverpod_generator` | `^2.4.0` | `2.6.4` |
| `riverpod` (transitive) | — | `2.6.1` |

The installed SDK is Dart 3.11 / Flutter 3.38. The pubspec constraint says `>=3.3.0` but the lock file resolved to packages that require `>=3.11.0`. This means the actual runtime environment is Dart 3.11, which is fine — the packages work. The issue is not the SDK version.

---

## Root Cause: Riverpod 2.6.x Syntax Change

**`riverpod_generator` 2.6.x eliminated the generated `Ref` subclass typedefs.** In Riverpod 2.4.x and earlier, the code generator produced a typedef like `typedef AppRouterRef = AutoDisposeProviderRef<GoRouter>` inside the `.g.dart` file, and user code referenced it as the function parameter type.

Starting with **riverpod_generator 2.6.0+**, the generator no longer produces these `*Ref` typedefs. Instead, the generated code uses `Ref` directly (the base `Ref` type from `riverpod`). User code must now use `Ref` as the parameter type, not the old generated `*Ref` names.

This is the single root cause of all code generation failures and the cascade of compile errors.

---

## Issue 1: Functional providers use obsolete `*Ref` parameter types

### Affected files

| File | Line | Problem |
|------|------|---------|
| `lib/shared/providers/supabase_provider.dart` | 7 | `supabaseClient(SupabaseClientRef ref)` — `SupabaseClientRef` does not exist |
| `lib/shared/providers/auth_state_provider.dart` | 7 | `authStateStream(AuthStateStreamRef ref)` — `AuthStateStreamRef` does not exist |
| `lib/core/router/router_provider.dart` | 13 | `appRouter(AppRouterRef ref)` — `AppRouterRef` does not exist |

### Why it fails

The generator in 2.6.4 does not produce `typedef SupabaseClientRef = ...`. The generated `.g.dart` file expects the function to accept `Ref` (imported from `package:riverpod`). When it encounters a parameter type that doesn't exist, code generation either fails silently (produces no output) or produces a `.g.dart` that doesn't compile.

### Exact fix

Replace all custom `*Ref` types with `Ref`:

```dart
// supabase_provider.dart — line 7
// BEFORE:
SupabaseClient supabaseClient(SupabaseClientRef ref) {
// AFTER:
SupabaseClient supabaseClient(Ref ref) {

// auth_state_provider.dart — line 7
// BEFORE:
Stream<AuthState> authStateStream(AuthStateStreamRef ref) {
// AFTER:
Stream<AuthState> authStateStream(Ref ref) {

// router_provider.dart — line 13
// BEFORE:
GoRouter appRouter(AppRouterRef ref) {
// AFTER:
GoRouter appRouter(Ref ref) {
```

Each file also needs the `Ref` import. Add to each:
```dart
import 'package:riverpod/riverpod.dart' show Ref;
```
Or simply import it via the already-imported `riverpod_annotation` which re-exports `Ref`.

---

## Issue 2: `_GoRouterAuthRefreshListenable` stores the obsolete `AppRouterRef` type

### Affected file

`lib/core/router/router_provider.dart`, line 35:
```dart
final AppRouterRef _ref;
```

### Why it fails

Same root cause — `AppRouterRef` does not exist in 2.6.x. The private class stores a reference to the provider's ref, typed as `AppRouterRef`.

### Exact fix

Change the field type to `Ref`:
```dart
// BEFORE:
final AppRouterRef _ref;
// AFTER:
final Ref _ref;
```

And update the constructor parameter at line 29 accordingly (it already receives `ref` from the provider function, which will now be typed as `Ref`).

---

## Issue 3: `router_provider.dart` calls `guardRedirect()` without importing its file

### Affected file

`lib/core/router/router_provider.dart`, line 20:
```dart
redirect: (context, state) => guardRedirect(
```

### Why it fails

`guardRedirect` is defined in `lib/core/router/route_guards.dart`. The file `router_provider.dart` imports `app_router.dart` (which itself imports `route_guards.dart`), but Dart imports are not transitive — importing `app_router.dart` does not make `route_guards.dart`'s exports available.

### Exact fix

Add the missing import to `router_provider.dart`:
```dart
import 'package:manager_connect/core/router/route_guards.dart';
```

---

## Issue 4: `auth_state_provider.dart` has a name collision with Supabase's `AuthState`

### Affected file

`lib/shared/providers/auth_state_provider.dart`, line 7:
```dart
Stream<AuthState> authStateStream(Ref ref) {
```

### Why it fails

`supabase_flutter` exports a type called `AuthState` (from `package:supabase_flutter/supabase_flutter.dart`). The project also defines its own `AuthState` sealed class in `auth_notifier.dart`. In this file, the import of `supabase_flutter` brings in Supabase's `AuthState`, which is the correct one here (the stream returns Supabase's auth state changes). But if both are imported in the same file elsewhere, there will be an ambiguous name.

This is not a build_runner failure — it's a latent collision that will surface when `router_provider.dart` or other files import both. The fix is to use `show`/`hide` clauses or a prefix.

### Exact fix

No change needed in this file itself — Supabase's `AuthState` is the intended type here. But the project's own `AuthState` in `auth_notifier.dart` should be renamed to avoid the collision:

**Option A (recommended):** Rename the project's sealed class from `AuthState` to `AppAuthState` in `auth_notifier.dart` and all references (route_guards.dart, router_provider.dart).

**Option B:** Keep both names and use `import ... show` / `hide` in every file that needs to disambiguate. This is fragile and scales poorly.

---

## Issue 5: `app_theme.dart` — `WidgetStatePropertyAll` vs `MaterialStatePropertyAll`

### Affected file

`lib/core/theme/app_theme.dart`, line 30:
```dart
labelTextStyle: WidgetStatePropertyAll(
```

### Analysis

`WidgetStatePropertyAll` was introduced in **Flutter 3.22.0** (May 2024) as the replacement for the deprecated `MaterialStatePropertyAll`. The lock file shows `flutter: ">=3.38.4"` which means the installed SDK is 3.38+, so `WidgetStatePropertyAll` is available.

**This is NOT a build failure.** `WidgetStatePropertyAll` is valid on Flutter 3.22+. If the user's actual Flutter SDK is older than 3.22, this would fail, but the lock file proves it's 3.38+.

### Verdict

No fix needed. The code is correct for the installed SDK.

---

## Issue 6: `app_theme.dart` — `surfaceContainerLowest`, `surfaceContainerLow`, `surfaceContainerHigh`

### Affected file

`lib/core/theme/app_theme.dart`, lines 58, 75, 102:
```dart
fillColor: colorScheme.surfaceContainerLowest,
backgroundColor: colorScheme.surfaceContainerLow,
backgroundColor: colorScheme.surfaceContainerHigh,
```

### Analysis

These `ColorScheme` surface container tokens (`surfaceContainerLowest`, `surfaceContainerLow`, `surfaceContainerHigh`) were introduced in **Flutter 3.22.0** as part of the Material 3 color system update. The installed SDK is 3.38+, so they are available.

### Verdict

No fix needed. The code is correct for the installed SDK.

---

## Issue 7: `SnackBarThemeData.insetPadding` does not exist

### Affected file

`lib/core/theme/app_theme.dart`, lines 88–91:
```dart
snackBarTheme: SnackBarThemeData(
  ...
  insetPadding: const EdgeInsets.symmetric(
    horizontal: 12,
    vertical: 12,
  ),
),
```

### Why it fails

`SnackBarThemeData` does not have an `insetPadding` property. The correct property name for controlling SnackBar margins when `behavior: SnackBarBehavior.floating` is used is `insetPadding` on the `SnackBar` widget itself, not on `SnackBarThemeData`. The theme data class has no margin/padding override.

### Exact fix

Remove `insetPadding` from `SnackBarThemeData`:
```dart
snackBarTheme: SnackBarThemeData(
  behavior: SnackBarBehavior.floating,
  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(12),
  ),
),
```

The 12px inset margin should be applied per-SnackBar instance in `context_extensions.dart`'s `showSnackBar()` method using the `margin` property of `SnackBar`.

---

## Summary of Required Fixes

| # | Severity | File | Fix |
|---|----------|------|-----|
| 1 | **Critical** | `supabase_provider.dart` | Change `SupabaseClientRef ref` → `Ref ref` |
| 2 | **Critical** | `auth_state_provider.dart` | Change `AuthStateStreamRef ref` → `Ref ref` |
| 3 | **Critical** | `router_provider.dart` | Change `AppRouterRef ref` → `Ref ref`; change `final AppRouterRef _ref` → `final Ref _ref` |
| 4 | **Critical** | `router_provider.dart` | Add missing import for `route_guards.dart` |
| 5 | **High** | `auth_notifier.dart` + all references | Rename project's `AuthState` → `AppAuthState` to avoid collision with Supabase's `AuthState` |
| 6 | **High** | `app_theme.dart` | Remove `insetPadding` from `SnackBarThemeData` (property does not exist) |
| 7 | **None** | `app_theme.dart` | `WidgetStatePropertyAll` — no fix needed (valid on installed SDK) |
| 8 | **None** | `app_theme.dart` | Surface container tokens — no fix needed (valid on installed SDK) |

### Fix order

1. Fix issues 1–3 first (Ref types) — this unblocks `build_runner`
2. Run `dart run build_runner build --delete-conflicting-outputs` — `.g.dart` files will generate
3. Fix issue 4 (missing import) — this unblocks compilation
4. Fix issue 5 (AuthState rename) — this prevents future ambiguity
5. Fix issue 6 (insetPadding) — this fixes the theme compile error
6. Run `flutter analyze` — should pass clean
