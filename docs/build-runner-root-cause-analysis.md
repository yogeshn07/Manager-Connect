# Build Runner Root Cause Analysis — Final

## Root Cause

**`riverpod_generator` 2.x is fundamentally incompatible with Dart SDK 3.11.5.**

The Dart SDK 3.11.5 ships `_fe_analyzer_shared` 85.0.0 which adds `DotShorthandInvocation` AST nodes to the parser. The `analyzer` 7.x package (the only version `riverpod_generator` 2.x accepts) uses `AstBinaryWriter extends ThrowingAstVisitor` in its `BundleWriter` to serialize library summaries. `AstBinaryWriter` in every 7.x version (7.0.0 through 7.7.1) does NOT implement `visitDotShorthandInvocation`. When the SDK's parser creates these nodes during library linking (even for code that doesn't use dot shorthand syntax), `ThrowingAstVisitor` throws `Missing implementation of visitDotShorthandInvocation`.

### Proof

```
# build_runner output:
W SDK language version 3.11.0 is newer than `analyzer` language version 3.9.0.
E riverpod_generator on lib/core/config/env.dart:
  Exception: Missing implementation of visitDotShorthandInvocation
  #0  ThrowingAstVisitor._throw (package:analyzer/dart/ast/visitor.dart:2971:5)
  #2  DotShorthandInvocationImpl.accept (package:analyzer/src/dart/ast/ast.dart:5459:15)
  #3  ResolutionSink._writeNode (package:analyzer/src/summary2/bundle_writer.dart:955:10)
```

### Why no 7.x analyzer fixes it

```bash
# Both 7.6.0 and 7.7.1 have zero DotShorthand in AstBinaryWriter:
grep -c "DotShorthand" analyzer-7.6.0/lib/src/summary2/ast_binary_writer.dart → 0
grep -c "DotShorthand" analyzer-7.7.1/lib/src/summary2/ast_binary_writer.dart → 0

# Analyzer 8.0.0+ has the fix:
grep -c "DotShorthand" analyzer-8.0.0/lib/src/summary2/ast_binary_writer.dart → 4
```

### Why dependency_overrides don't work

The analyzer ecosystem (`analyzer`, `_fe_analyzer_shared`, `dart_style`, `custom_lint_visitor`, `build_resolvers`, `source_gen`) is tightly coupled. Overriding one package breaks others. Pub's solver must choose a coherent set.

## Fix Applied

Upgrade to Riverpod 3.x ecosystem — the only version family that uses `analyzer >=7.0.0 <9.0.0` (allowing 8.x which has the `DotShorthand` fix):

```yaml
# pubspec.yaml changes:
flutter_riverpod: ^3.0.3    # was ^2.6.1
riverpod_annotation: ^3.0.3  # was ^2.6.1
riverpod_generator: ^3.0.3   # was ^2.6.5
freezed: ^3.2.1              # was 3.0.6
```

Pub then resolves:
- `analyzer` 8.4.0 (has `DotShorthand` in `AstBinaryWriter`)
- `_fe_analyzer_shared` 91.0.0 (newer than SDK's bundled 85.0.0 — pub overrides SDK version)
- `source_gen` 4.2.0 (matches both generators)
- `custom_lint_visitor` 1.0.0+8.4.0 (matches analyzer 8.4.0)

No `dependency_overrides` needed. All packages resolved by pub's natural solver.

### Riverpod 3.x code changes required

1. `Ref` is now exported by `riverpod_annotation` — remove `import 'package:riverpod/riverpod.dart' show Ref`
2. Provider naming: `AuthNotifier` generates `authProvider` (not `authNotifierProvider`)
3. `@Riverpod(keepAlive: true)` syntax unchanged
4. Functional provider `@riverpod` syntax unchanged
5. `Ref ref` parameter syntax unchanged

## Why Previous Fixes Failed

| Attempt | Why it failed |
|---------|--------------|
| Upgrade `riverpod_analyzer_utils` to 0.5.10 | Crash is in `analyzer` BundleWriter, not in riverpod's visitors |
| Lower SDK constraint to `>=3.9.0` | SDK still runs at 3.11.5; transitive deps use 3.11 language version |
| Override `synchronized` to 3.4.0 | SDK parser creates DotShorthand nodes regardless of package versions |
| Override `analyzer` to 7.7.1 | 7.7.1's AstBinaryWriter still doesn't handle DotShorthand |
| Override `_fe_analyzer_shared` to 86.0.0 + analyzer 8.0.0 | `custom_lint_visitor`, `dart_style` break — tightly coupled ecosystem |
| Stay on Riverpod 2.x | No 7.x analyzer handles DotShorthand in BundleWriter. Dead end. |
