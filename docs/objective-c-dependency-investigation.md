# objective_c Dependency Investigation

## Dependency Chain

```
cached_network_image 3.4.1          ← direct dependency (pubspec.yaml)
  └── flutter_cache_manager 3.4.1
        └── path_provider 2.1.6
              └── path_provider_foundation 2.6.0   ← iOS/macOS platform implementation
                    └── objective_c 9.4.1           ← Objective-C FFI bridge
```

**`objective_c` is NOT pulled by `supabase_flutter` or `passkeys`.** It comes from `cached_network_image` → `flutter_cache_manager` → `path_provider` → `path_provider_foundation`.

`path_provider` 2.1.6 depends on `path_provider_foundation: ^2.3.2` (accepts 2.3.2 to <3.0.0). Pub resolves to 2.6.0 — the latest in range — which added `objective_c` as a dependency.

## Is objective_c Required for Android Builds?

**No.** The `objective_c` build hook (`hook/build.dart`) explicitly checks the target OS:

```dart
// hook/build.dart, lines 27-33:
if (!input.config.buildCodeAssets) {
  return;  // Skip non-code-asset builds
}

const supportedOSs = {OS.iOS, OS.macOS};
if (!supportedOSs.contains(os)) {
  return;  // Nothing to do for Android/Windows/Linux/Web
}
```

The hook returns immediately for non-Apple platforms. **The crash occurs BEFORE the hook executes** — during the hook compilation step (`dart compile kernel`), where the Dart compiler command fails because the path containing spaces is not properly quoted.

## Known Issue

### dart-lang/native #2993

**Title:** "[hooks_runner] Can't run build_runner when profile folder has a space"
**Status:** Open
**Priority:** P3 (lower priority)
**Labels:** `contributions-welcome`, `package:hooks_runner`, `package:objective_c`
**Milestone:** Native Assets v1.x
**Opened:** January 21, 2026
**URL:** https://github.com/dart-lang/native/issues/2993

The issue is in the `hooks_runner` package (part of Dart's native assets system), not in `objective_c` itself. The hooks runner constructs a `dart compile kernel` command without properly quoting the hook script path. When the path contains spaces (e.g., `C:\Users\YOGESH N\AppData\Local\Pub\Cache\...`), the command splits at the space:

```
Expected: dart compile kernel "C:\Users\YOGESH N\...\hook\build.dart"
Actual:   dart compile kernel C:\Users\YOGESH N\...\hook\build.dart
                               ↑ shell splits here
Result:   'C:\Users\YOGESH' is not recognized as an internal or external command
```

### dart-lang/native #2848

**Title:** "Windows build fails with 'C:\\Program' is not recognized ... when include paths contain spaces"
**Status:** Open
**Labels:** `package:native_toolchain_c`

Same class of bug — unquoted paths with spaces in the native toolchain.

### Maintainer Response

No fix has been merged. The issue is tagged `contributions-welcome` and assigned to the `Native Assets v1.x` milestone with no ETA.

## When objective_c Was Introduced

| `path_provider_foundation` version | `objective_c` dependency | Notes |
|-------------------------------------|-------------------------|-------|
| 2.3.2 | **None** | No native asset hooks |
| 2.4.4 | **None** | No native asset hooks |
| 2.5.0 | Unknown | Retracted from pub.dev |
| 2.5.1 | Unknown | |
| **2.6.0** | **`^9.2.1`** | First version requiring `objective_c` |

`path_provider_foundation` 2.4.4 is the latest version WITHOUT the `objective_c` dependency. It uses `sdk: ^3.9.0` and `flutter: ">=3.35.0"` — compatible with our environment.

## Fix Options

### Option 1: Pin `path_provider_foundation` to 2.4.4 (Recommended)

```yaml
dependency_overrides:
  path_provider_foundation: 2.4.4
```

This avoids `objective_c` entirely. The `path_provider` plugin still works — version 2.4.4 is a fully functional iOS/macOS implementation that predates the Objective-C FFI migration. It satisfies `path_provider`'s `^2.3.2` constraint.

**Risk:** Low. Version 2.4.4 is stable, supports the current SDK, and only differs from 2.6.0 in the internal implementation (uses the old plugin mechanism instead of Objective-C FFI).

### Option 2: Move project to a spaceless path

```powershell
mklink /J C:\dev\mcproject "C:\Users\YOGESH N\OneDrive\Desktop\office_project"
cd C:\dev\mcproject\frontend
flutter build apk --debug
```

**Risk:** None to code. Requires manual setup on every Windows dev machine.

### Option 3: Set PUB_CACHE to a spaceless path

```powershell
$env:PUB_CACHE = "C:\PubCache"
flutter pub get
flutter build apk --debug
```

**Risk:** Low. All pub packages re-download to the new cache location.

### Option 4: Wait for dart-lang/native #2993 fix

**Risk:** Indefinite wait. Issue is P3 with no assignee.

## Recommendation

**Option 1** is the lowest-risk, lowest-effort fix. It removes the problematic package from the dependency tree entirely, is a single-line pubspec.yaml change, and has no functional impact on Android or iOS builds (the older `path_provider_foundation` works identically for path resolution).
