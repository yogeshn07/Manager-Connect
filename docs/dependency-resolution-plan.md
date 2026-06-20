# Dependency Resolution Plan

## Problem

```
riverpod_generator ^2.6.5 requires source_gen ^2.0.0
freezed ^3.2.5 requires source_gen >=3.0.0
```

These two constraints are mutually exclusive. No version of `source_gen` satisfies both `^2.0.0` (2.x only) and `>=3.0.0` (3.x+) simultaneously. The resolution fails before pub even attempts to download packages.

Additionally, `freezed` 3.2.5 requires `analyzer >=9.0.0 <11.0.0`, but Dart 3.11.5 bundles analyzer 7.6.0 — a second incompatibility.

## Root Cause

The `freezed` package crossed a major boundary between 3.0.6 and 3.1.0:

| freezed version | source_gen | analyzer | build |
|----------------|-----------|---------|-------|
| 3.0.6 (Mar 2025) | `^2.0.0` | `>=6.9.0 <8.0.0` | `^2.3.1` |
| 3.1.0 (Jul 2025) | `>=3.0.0 <5.0.0` | `>=9.0.0 <11.0.0` | `>=3.0.0 <5.0.0` |
| 3.2.5 (Feb 2026) | `>=3.0.0 <5.0.0` | `>=9.0.0 <11.0.0` | `>=3.0.0 <5.0.0` |

`freezed` 3.1.0+ jumped to `source_gen` 3.x and `analyzer` 9.x — targeting a newer Dart SDK than 3.11.5 provides. The `^3.2.5` constraint in pubspec.yaml cannot resolve on this SDK.

**The compatible freezed 3.x version for Dart 3.11.5 is 3.0.6** (or 3.0.5). These use `source_gen ^2.0.0` and `analyzer <8.0.0`, matching both `riverpod_generator` 2.6.5 and the SDK-bundled analyzer 7.6.0.

---

## Compatible Package Set

All packages verified against: **Dart 3.11.5 / Flutter 3.41.7 / analyzer 7.6.0**

### Codegen Pipeline

| Package | Version | source_gen | analyzer | build | Dart SDK |
|---------|---------|-----------|---------|-------|----------|
| `build_runner` | 2.5.4 | — | `>=4.4.0 <8.0.0` ✅ | 2.5.4 (pinned) | `^3.7.0` ✅ |
| `riverpod_generator` | 2.6.5 | `^2.0.0` | (via rau 0.5.10: `^7.0.0`) ✅ | — | `>=2.17.0` ✅ |
| `riverpod_analyzer_utils` | 0.5.10 | — | `^7.0.0` ✅ | — | `>=3.0.0` ✅ |
| `freezed` | **3.0.6** | `^2.0.0` ✅ | `>=6.9.0 <8.0.0` ✅ | `^2.3.1` ✅ | `>=3.6.0` ✅ |
| `json_serializable` | 6.9.5 | `^2.0.0` ✅ | `>=6.9.0 <8.0.0` ✅ | — | `>=3.6.0` ✅ |
| `source_gen` | **2.0.0** | — | — | — | — |

**source_gen 2.0.0 satisfies all four generators** (`^2.0.0` from riverpod_generator, freezed, json_serializable, and build_resolvers).

**analyzer 7.6.0 satisfies all packages** (`^7.0.0` from riverpod_analyzer_utils, `>=6.9.0 <8.0.0` from freezed 3.0.6, `>=6.9.0 <8.0.0` from json_serializable, `>=4.4.0 <8.0.0` from build_runner).

### Riverpod Ecosystem

| Package | Version | Depends on |
|---------|---------|-----------|
| `flutter_riverpod` | 2.6.1 | `riverpod: 2.6.1` |
| `riverpod` | 2.6.1 | (core) |
| `riverpod_annotation` | 2.6.1 | `riverpod: 2.6.1` |
| `riverpod_generator` | 2.6.5 | `riverpod_annotation: 2.6.1`, `riverpod_analyzer_utils: 0.5.10` |

### Freezed Ecosystem

| Package | Version | Depends on |
|---------|---------|-----------|
| `freezed_annotation` | 3.1.0 | (annotations only — no analyzer/build dependency) |
| `freezed` | 3.0.6 | `freezed_annotation: ^3.0.0` ✅ accepts 3.1.0 |

**Note:** `freezed_annotation` 3.1.0 is a pure annotation package with no transitive build dependencies. `freezed` 3.0.6 declares `freezed_annotation: ^3.0.0` which resolves to 3.1.0. There is no conflict.

### JSON Ecosystem

| Package | Version |
|---------|---------|
| `json_annotation` | 4.9.0 |
| `json_serializable` | 6.9.5 |

No changes needed — these were already compatible.

---

## Compatibility Proof

```
Dart 3.11.5 → analyzer 7.6.0

                    source_gen 2.0.0
                    ┌──────────────────────────────────────┐
                    │                                      │
  riverpod_generator 2.6.5     freezed 3.0.6     json_serializable 6.9.5
  source_gen: ^2.0.0 ✅        source_gen: ^2.0.0 ✅    source_gen: ^2.0.0 ✅
                    │                                      │
                    └──────────────────────────────────────┘

                    analyzer 7.6.0
                    ┌──────────────────────────────────────┐
                    │                                      │
  riverpod_analyzer_utils 0.5.10   freezed 3.0.6   json_serializable 6.9.5
  analyzer: ^7.0.0 ✅         analyzer: >=6.9.0 <8.0.0 ✅  analyzer: >=6.9.0 <8.0.0 ✅
                    │                                      │
                    └──────────────────────────────────────┘

                    build 2.5.4
                    ┌──────────────────────────────────────┐
                    │                                      │
  build_runner 2.5.4          freezed 3.0.6
  build: 2.5.4 (pinned) ✅    build: ^2.3.1 ✅ (2.5.4 in range)
                    │                                      │
                    └──────────────────────────────────────┘
```

---

## Required pubspec.yaml Changes

Only **one line** needs to change from the current pubspec.yaml:

```yaml
# CURRENT (broken):
  freezed: ^3.2.5

# FIXED:
  freezed: ">=3.0.5 <3.1.0"
```

All other versions remain exactly as they are. The constraint `>=3.0.5 <3.1.0` resolves to freezed 3.0.5 or 3.0.6 — the last versions that use `source_gen ^2.0.0` and `analyzer <8.0.0`.

### Why this specific constraint

| Constraint style | Resolves to | Problem |
|-----------------|------------|---------|
| `^3.0.6` | 3.0.6 → **but allows 3.2.5** | Caret allows 3.1.0+ which is incompatible |
| `3.0.6` | 3.0.6 exactly | Works but prevents patch updates |
| `>=3.0.5 <3.1.0` | 3.0.5 or 3.0.6 | **Best** — allows the patch range, blocks the breaking 3.1.0 |

### Complete pubspec.yaml diff

```diff
  # Code Generation
  build_runner: ^2.4.11
  riverpod_generator: ^2.6.5
- freezed: ^3.2.5
+ freezed: ">=3.0.5 <3.1.0"
  json_serializable: ^6.9.5
```

No other lines change. The environment constraints, all runtime dependencies, and all other dev dependencies remain identical.

---

## Summary

| Question | Answer |
|----------|--------|
| Root cause | `freezed` 3.1.0+ migrated to `source_gen` 3.x and `analyzer` 9.x — incompatible with Dart 3.11.5 |
| Fix | Pin `freezed` to `>=3.0.5 <3.1.0` (last 3.x versions compatible with source_gen 2.x / analyzer 7.x) |
| Lines changed | 1 |
| dependency_overrides needed | No |
| Dart/Flutter downgrade needed | No |
| Risk | Minimal — freezed 3.0.6 is stable; annotation API unchanged from 3.0.6 to 3.2.5 |
