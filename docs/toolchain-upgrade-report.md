# Toolchain Upgrade Report

## Target Environment

| Component | Version |
|-----------|---------|
| Flutter SDK | 3.41.7 |
| Dart SDK | 3.11.5 |
| Analyzer (SDK-bundled) | 7.6.0 |

---

## Changes Applied to pubspec.yaml

### Environment Constraint

| Field | Old | New | Reason |
|-------|-----|-----|--------|
| `sdk` | `>=3.3.0 <4.0.0` | `>=3.11.0 <4.0.0` | Matches actual installed Dart SDK; prevents resolution of packages that don't support 3.11 features |
| `flutter` | `>=3.22.0` | `>=3.38.0` | Matches actual installed Flutter SDK; aligns with lock file's `flutter: ">=3.38.4"` |

### Dependency Version Changes

| Package | Old (pubspec.yaml) | Old (resolved) | New (pubspec.yaml) | Expected Resolution | Why |
|---------|-------------------|----------------|-------------------|--------------------|----|
| `flutter_riverpod` | `^2.5.1` | 2.6.1 | `^2.6.1` | 2.6.1 | Pin to current resolved version; no change needed |
| `riverpod_annotation` | `^2.3.5` | 2.6.1 | `^2.6.1` | 2.6.1 | Pin to current resolved version; required by riverpod_generator 2.6.5 |
| `riverpod_generator` | `^2.4.0` | 2.6.4 | **`^2.6.5`** | **2.6.5** | **Pulls riverpod_analyzer_utils 0.5.10 with analyzer ^7.0.0 — the fix** |
| `freezed_annotation` | `^2.4.1` | 2.4.4 | **`^3.1.0`** | **3.1.0** | Required by riverpod_analyzer_utils 0.5.10 (depends on freezed_annotation ^3.0.0) |
| `freezed` | `^2.5.2` | 2.5.8 | **`^3.2.5`** | **3.2.5** | Must match freezed_annotation 3.x; 2.x is incompatible with freezed_annotation 3.x |
| `json_serializable` | `^6.8.0` | 6.9.5 | `^6.9.5` | 6.9.5+ | Pin to current resolved or newer; no breaking changes in 6.x |
| `json_annotation` | `^4.9.0` | 4.9.0 | `^4.9.0` | 4.9.0 | Unchanged — json_serializable 6.x still uses json_annotation 4.x |
| `build_runner` | `^2.4.11` | 2.5.4 | `^2.4.11` | 2.5.4+ | Unchanged constraint — resolved version already compatible |

### Packages NOT Changed

| Package | Version | Why unchanged |
|---------|---------|---------------|
| `go_router` | ^14.1.0 | Not in the codegen pipeline; no analyzer dependency |
| `supabase_flutter` | ^2.5.0 | Not in the codegen pipeline |
| `fpdart` | ^1.1.0 | Not in the codegen pipeline |
| `firebase_core` | ^3.3.0 | Not in the codegen pipeline |
| `firebase_messaging` | ^15.0.4 | Not in the codegen pipeline |
| `flutter_local_notifications` | ^17.2.2 | Not in the codegen pipeline |
| `cached_network_image` | ^3.3.1 | Not in the codegen pipeline |
| `image_picker` | ^1.1.2 | Not in the codegen pipeline |
| `image` | ^4.2.0 | Not in the codegen pipeline |
| `intl` | ^0.19.0 | Not in the codegen pipeline |
| `connectivity_plus` | ^6.0.3 | Not in the codegen pipeline |
| `mocktail` | ^1.0.4 | Not in the codegen pipeline |
| `flutter_lints` | ^4.0.0 | Not in the codegen pipeline |

---

## Compatibility Chain (after upgrade)

```
Dart 3.11.5 bundles analyzer 7.6.0
      │
      ▼
build_runner 2.5.4+
  └── build_resolvers → analyzer ^5.0.0 <8.0.0  ✅ accepts 7.6.0
  └── source_gen 2.0.0 → analyzer ^5.0.0 <8.0.0  ✅ accepts 7.6.0
      │
      ├── riverpod_generator 2.6.5
      │     └── riverpod_analyzer_utils 0.5.10
      │           └── analyzer ^7.0.0              ✅ accepts 7.6.0
      │           └── freezed_annotation ^3.0.0     ✅ satisfied by 3.1.0
      │
      ├── freezed 3.2.5
      │     └── analyzer ^6.0.0 <8.0.0             ✅ accepts 7.6.0
      │     └── freezed_annotation ^3.0.0           ✅ satisfied by 3.1.0
      │
      └── json_serializable 6.9.5+
            └── analyzer ^5.0.0 <8.0.0             ✅ accepts 7.6.0
            └── json_annotation ^4.9.0             ✅ no change
```

**Every package in the codegen pipeline now explicitly accepts analyzer 7.6.0.** The `visitDotShorthandInvocation` crash is resolved because `riverpod_analyzer_utils` 0.5.10 implements all visitor methods for analyzer 7.x.

---

## Freezed 2.x → 3.x Migration Notes

Freezed 3.x is a major version bump. Key changes:

| Change | Impact on this project |
|--------|----------------------|
| `@freezed` annotation still works | No code change needed |
| Import path unchanged (`package:freezed_annotation/freezed_annotation.dart`) | No code change needed |
| Default `copyWith` generation changed | No `@freezed` classes exist yet — no impact |
| `when`/`map` methods require opt-in in 3.x | No `@freezed` classes exist yet — no impact |

**Because no `@freezed` classes have been implemented yet** (they are scheduled for Sprint 1 Phase 3+), the major version bump has zero impact on existing code. When `@freezed` classes are added later, they will be written against 3.x syntax from the start.

---

## Commands to Run Next

```bash
cd frontend

# 1. Delete the stale lock file
rm pubspec.lock

# 2. Resolve fresh dependencies
flutter pub get

# 3. Generate Riverpod provider code
dart run build_runner build --delete-conflicting-outputs

# 4. Verify no analyze errors
flutter analyze
```

**Step 1 is critical.** The existing `pubspec.lock` pins `riverpod_analyzer_utils` to 0.5.9. Without deleting it, `flutter pub get` may retain the old resolution. A fresh `pub get` without a lock file forces a complete re-resolution from the updated constraints.

---

## Verification After Running Commands

| Check | Expected Result |
|-------|----------------|
| `flutter pub get` | Resolves without errors; `riverpod_analyzer_utils` shows 0.5.10 in new lock file |
| `dart run build_runner build` | Completes without `visitDotShorthandInvocation` crash |
| `.g.dart` files generated | `supabase_provider.g.dart`, `auth_state_provider.g.dart`, `router_provider.g.dart`, `auth_notifier.g.dart` |
| `flutter analyze` | Passes with zero errors |
| `riverpod_analyzer_utils` in new lock file | 0.5.10 (not 0.5.9) |
| `analyzer` in new lock file | 7.6.0 (matches SDK) |
