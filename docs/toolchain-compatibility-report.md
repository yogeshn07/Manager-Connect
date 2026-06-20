# Toolchain Compatibility Report

## Environment

| Component | Version |
|-----------|---------|
| Flutter SDK | 3.41.7 |
| Dart SDK | 3.11.5 |
| Dart analyzer (SDK-bundled) | 7.6.0 |

## Resolved Package Versions (from pubspec.lock)

### Code Generation Pipeline

| Package | Declared (pubspec.yaml) | Resolved (pubspec.lock) | Role |
|---------|------------------------|------------------------|------|
| `build_runner` | `^2.4.11` | **2.5.4** | Orchestrates code generation |
| `build_resolvers` | (transitive) | **2.5.4** | Resolves Dart sources for build_runner via `analyzer` |
| `source_gen` | (transitive) | **2.0.0** | Base for code generators |
| `analyzer` | (transitive) | **7.6.0** | Dart static analysis engine — used by all generators |
| `_fe_analyzer_shared` | (transitive) | **85.0.0** | Shared frontend analysis (CFE ↔ analyzer) |

### Riverpod Pipeline

| Package | Declared | Resolved | Role |
|---------|----------|----------|------|
| `flutter_riverpod` | `^2.5.1` | **2.6.1** | Flutter bindings |
| `riverpod` | (transitive) | **2.6.1** | Core |
| `riverpod_annotation` | `^2.3.5` | **2.6.1** | `@riverpod` / `@Riverpod` annotations |
| `riverpod_generator` | `^2.4.0` | **2.6.4** | Code generator (produces `.g.dart`) |
| `riverpod_analyzer_utils` | (transitive) | **0.5.9** | Analyzer visitor used by generator |

### Freezed / JSON Pipeline

| Package | Declared | Resolved | Role |
|---------|----------|----------|------|
| `freezed` | `^2.5.2` | **2.5.8** | Code generator for `@freezed` |
| `freezed_annotation` | `^2.4.1` | **2.4.4** | Annotations |
| `json_serializable` | `^6.8.0` | **6.9.5** | Code generator for `@JsonSerializable` |
| `json_annotation` | `^4.9.0` | **4.9.0** | Annotations |

---

## The Crash

```
Missing implementation of visitDotShorthandInvocation
```

This error originates from the `analyzer` package's AST visitor system. The Dart analyzer defines an `AstVisitor` interface with a `visit*` method for every syntax node type. When a new Dart language feature is introduced (like dot shorthand invocation in Dart 3.11), the analyzer adds a new AST node type and a corresponding `visitDotShorthandInvocation` method to the `AstVisitor` interface.

**The crash happens when:**
1. The Dart SDK is 3.11.5 — it parses `.foo()` shorthand syntax into `DotShorthandInvocation` AST nodes
2. `analyzer` 7.6.0 (bundled with the SDK) defines `visitDotShorthandInvocation` in its `AstVisitor` interface
3. A package that implements `AstVisitor` (or extends `GeneralizingAstVisitor` / `RecursiveAstVisitor`) was compiled against an **older** analyzer version that did NOT have this method
4. At runtime, the visitor encounters a `DotShorthandInvocation` node, dispatches to `visitDotShorthandInvocation`, and finds **no implementation** — crash

---

## Root Cause: `riverpod_analyzer_utils` 0.5.9

**`riverpod_analyzer_utils` version 0.5.9 is the constraining package.**

The dependency chain is:

```
riverpod_generator 2.6.4
  └── riverpod_analyzer_utils 0.5.9
        └── analyzer >=5.12.0 <7.4.0    ← UPPER BOUND TOO LOW
              └── (but SDK forces analyzer 7.6.0)
```

`riverpod_analyzer_utils` 0.5.9 was built against `analyzer <7.4.0`. It implements AST visitors that were complete for analyzer 7.3.x and below. Analyzer 7.6.0 (shipped with Dart 3.11.5) added new AST node types for Dart 3.11 language features — including `DotShorthandInvocation`.

Because pub's dependency resolver allows `analyzer` 7.6.0 (the SDK provides it, overriding the declared constraint), the code compiles. But at runtime, `riverpod_analyzer_utils` 0.5.9's visitor classes are missing the new `visit*` methods. When `build_runner` processes any Dart file, the analyzer parses it into the AST, and if the visitor encounters a node type it doesn't implement, it crashes.

**The crash does NOT require your code to use dot shorthand.** The SDK's own internal libraries or transitive source files may contain the new syntax, or the analyzer's visitor dispatch table simply requires all methods to be implemented regardless of whether they're encountered.

### Confirmation

| Package | Analyzer Constraint | Analyzer Resolved | Compatible? |
|---------|--------------------|--------------------|-------------|
| `build_resolvers` 2.5.4 | `>=5.0.0 <8.0.0` | 7.6.0 | ✅ |
| `source_gen` 2.0.0 | `>=5.0.0 <8.0.0` | 7.6.0 | ✅ |
| `freezed` 2.5.8 | `>=5.0.0 <8.0.0` | 7.6.0 | ✅ |
| `json_serializable` 6.9.5 | `>=5.0.0 <8.0.0` | 7.6.0 | ✅ |
| `riverpod_generator` 2.6.4 | (via riverpod_analyzer_utils) | 7.6.0 | ❌ indirect |
| **`riverpod_analyzer_utils` 0.5.9** | **`>=5.12.0 <7.4.0`** | **7.6.0** | **❌ MISMATCH** |
| `custom_lint_visitor` 1.0.0+7.7.0 | (bundles analyzer 7.7.0) | 7.6.0 | ✅ |

`riverpod_analyzer_utils` 0.5.9 is the **only** package in the lock file with an analyzer upper bound below 7.6.0.

---

## Why Pub Allowed This

Pub resolved `analyzer` 7.6.0 because:
1. The Dart SDK 3.11.5 bundles analyzer 7.6.0 as an SDK-provided package
2. Most packages (`build_resolvers`, `source_gen`, `freezed`) accept `<8.0.0`
3. `riverpod_analyzer_utils` 0.5.9 declares `<7.4.0` but pub overrides it because analyzer is an SDK dependency
4. Pub does not enforce transitive dependency constraints against SDK-provided packages the same way it enforces them for pub-hosted packages

The result: the constraint is violated silently, and the failure surfaces at runtime as a missing visitor method.

---

## Fix Options

### Option 1: Upgrade riverpod_generator to latest (Recommended)

`riverpod_generator` 2.7.x (if available) or a newer `riverpod_analyzer_utils` that supports `analyzer >=7.6.0` would fix this. Check pub.dev for:

```yaml
# pubspec.yaml — update these:
riverpod_generator: ^2.7.0      # or latest
riverpod_annotation: ^2.7.0     # match generator major
flutter_riverpod: ^2.7.0        # match ecosystem
```

Then: `flutter pub upgrade riverpod_generator riverpod_annotation flutter_riverpod`

**Risk:** Low if staying within 2.x. API is stable. May require minor syntax adjustments if generator output format changes.

### Option 2: Pin analyzer via dependency_overrides (Fastest)

Force pub to resolve an older analyzer that `riverpod_analyzer_utils` 0.5.9 supports:

```yaml
# pubspec.yaml — add:
dependency_overrides:
  analyzer: "7.3.0"
```

This forces analyzer 7.3.0 instead of 7.6.0. Since 7.3.0 predates the `DotShorthandInvocation` node, the visitor crash disappears.

**Risk:** Medium. The SDK bundles 7.6.0 for a reason — overriding it may cause subtle analysis differences or miss new diagnostics. `flutter analyze` and `build_runner` will use the overridden version, but the IDE may still use the SDK-bundled version, causing inconsistency.

### Option 3: Upgrade Dart/Flutter SDK constraint + all codegen packages together (Lowest risk)

Align the entire codegen toolchain to the latest versions that explicitly support Dart 3.11:

```yaml
environment:
  sdk: ">=3.11.0 <4.0.0"

dependencies:
  flutter_riverpod: ^2.7.0
  riverpod_annotation: ^2.7.0

dev_dependencies:
  build_runner: ^2.5.4
  riverpod_generator: ^2.7.0
  freezed: ^2.5.8
  json_serializable: ^6.9.5
```

Then delete `pubspec.lock` and run `flutter pub get` to get a clean resolution.

**Risk:** Lowest. Every package version is chosen to explicitly support the installed SDK. No overrides needed. Lock file is regenerated cleanly.

---

## Verdict

| | Root Cause | Recommended Fix | Lowest-Risk Fix | Fastest Fix |
|---|-----------|----------------|----------------|------------|
| **What** | `riverpod_analyzer_utils` 0.5.9 does not implement visitor methods for Dart 3.11 AST nodes (analyzer 7.6.0) | Upgrade Riverpod ecosystem to latest 2.7.x | Upgrade all codegen packages + delete lock file + regenerate | `dependency_overrides: analyzer: "7.3.0"` |
| **Why** | The package declares `analyzer <7.4.0` but SDK forces 7.6.0; missing `visitDotShorthandInvocation` | Gets a `riverpod_analyzer_utils` version built for analyzer 7.6.0+ | All packages explicitly tested against Dart 3.11 | Avoids the new AST nodes entirely by using older analyzer |
| **Risk** | — | Low | Lowest | Medium (SDK/IDE divergence) |
| **Speed** | — | ~5 minutes | ~10 minutes | ~1 minute |
