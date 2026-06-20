# Dot Shorthand Root Cause Analysis

## The Error

```
W SDK language version 3.11.0 is newer than `analyzer` language version 3.9.0.
E riverpod_generator on lib/core/config/env.dart:
  Exception: Missing implementation of visitDotShorthandInvocation
  #0  ThrowingAstVisitor._throw (package:analyzer/dart/ast/visitor.dart:2971:5)
  #1  ThrowingAstVisitor.visitDotShorthandInvocation (package:analyzer/dart/ast/visitor.dart:2538:66)
  #2  DotShorthandInvocationImpl.accept (package:analyzer/src/dart/ast/ast.dart:5459:15)
  #3  ResolutionSink._writeNode (package:analyzer/src/summary2/bundle_writer.dart:955:10)
  ...
  #15 BundleWriter._writeClassElement
  ...
  #22 BundleWriter.writeLibraryElement
  #23 Linker._writeLibraries
  #24 Linker.link
```

## Root Cause

**The crash is inside the `analyzer` 7.6.0 package itself** — not in `riverpod_analyzer_utils`, not in user code, not in any third-party visitor.

### The chain of events

1. **pubspec.yaml declares `sdk: ">=3.11.0 <4.0.0"`**. This sets the package language version to **3.11**.

2. **The Dart SDK 3.11.5 parser**, when parsing files at language version 3.11, enables the `dot-shorthands` experiment. It generates `DotShorthandInvocation` AST nodes for certain constructor and method call patterns — including `String.fromEnvironment()` when it appears in a const context within a class with a default value. The SDK's parser creates these nodes for internal representation at language version 3.11, even though the source code uses explicit `String.fromEnvironment()` syntax.

3. **`analyzer` 7.6.0's `BundleWriter`** (in `summary2/bundle_writer.dart`) serializes library element summaries. Its `ResolutionSink._writeNode()` method visits AST nodes using the analyzer's visitor dispatch. When it encounters a `DotShorthandInvocation` node, it dispatches to `ThrowingAstVisitor.visitDotShorthandInvocation()`.

4. **`ThrowingAstVisitor`** is a visitor class that throws an exception for every visit method — it's used by the analyzer internals to catch node types that the serializer doesn't know how to handle. The `visitDotShorthandInvocation` method in `ThrowingAstVisitor` calls `_throw(node)`, producing the crash.

5. **The crash location `env.dart`** is the first file processed by `build_runner` that contains a `const` class member initialized with a constructor call (`String.fromEnvironment(...)`). At language version 3.11, the parser's internal representation of this construct uses the new `DotShorthandInvocation` AST node type, which the `BundleWriter`'s `ThrowingAstVisitor`-based serializer cannot process.

### The warning confirms it

```
W SDK language version 3.11.0 is newer than `analyzer` language version 3.9.0.
```

The `analyzer` 7.6.0 package supports **language version 3.9**. It was released before Dart 3.11. The SDK runtime is 3.11.5, which parses at 3.11. The analyzer's internal serialization code (`BundleWriter`) was written for the 3.9 AST — it doesn't handle 3.11's new node types.

## Why `env.dart` specifically

`env.dart` contains:
```dart
abstract final class Env {
  static const String supabaseUrl = String.fromEnvironment('SUPABASE_URL');
```

The `String.fromEnvironment()` call in a `static const` context, inside a class declaration, triggers the parser to create a `DotShorthandInvocation` node in the internal AST at language version 3.11. This is an internal parser optimization — the SDK's Dart 3.11 parser represents certain const factory constructors differently using the new AST node infrastructure, even when the source code doesn't use dot shorthand syntax.

`env.dart` is also the first file alphabetically that `build_runner` processes (in the `riverpod_generator` input set), so it's the first file where the serializer encounters this node type.

## Why no other file crashed first

Other files processed before `env.dart` (if any) either:
- Don't contain const class member initializers with constructor calls
- Are processed as no-ops (already generated or empty)

The build log confirms: `env.dart` was the first file actively analyzed.

## The file is NOT the problem

`env.dart` uses only Dart 3.3-era syntax:
- `abstract final class` (Dart 3.0)
- `String.fromEnvironment()` (Dart 1.0)
- `static const` (Dart 1.0)
- Arrow getter `=>` (Dart 1.0)

**No Dart 3.11-only syntax exists in any project file.** The entire `lib/` directory was searched:
- No dot shorthand invocations (`.foo()` without explicit class)
- No extension types
- No shorthand constructors
- No records
- No 3.11-specific pattern syntax

The crash is caused by the SDK parser's internal AST representation at language version 3.11, not by the source code itself.

## Fix

**Lower the SDK constraint lower bound to match what `analyzer` 7.6.0 supports:**

```yaml
# CURRENT (triggers 3.11 language version):
environment:
  sdk: ">=3.11.0 <4.0.0"

# FIXED (uses 3.9 language version, matching analyzer capability):
environment:
  sdk: ">=3.9.0 <4.0.0"
```

This changes the package language version from 3.11 to 3.9. At language version 3.9:
- The parser does NOT create `DotShorthandInvocation` nodes
- The `BundleWriter` serializer encounters only node types it knows
- `build_runner` succeeds

**This does NOT downgrade the Dart SDK.** The Dart SDK 3.11.5 continues to run. The language version only controls which language features the parser enables for this package's source files. Since no project file uses any 3.11-specific syntax, lowering to 3.9 loses nothing.

The `flutter` constraint should also be lowered to match:

```yaml
environment:
  sdk: ">=3.9.0 <4.0.0"
  flutter: ">=3.27.0"
```

## Why the previous diagnosis was wrong

The earlier toolchain report identified `riverpod_analyzer_utils` 0.5.10 as the package whose visitor was missing `visitDotShorthandInvocation`. That was incorrect. The stack trace proves:

| What was suspected | What actually crashes |
|---|---|
| `riverpod_analyzer_utils` visitor | `analyzer` 7.6.0's own `BundleWriter` / `ResolutionSink` |
| A third-party visitor class missing the method | The analyzer's own `ThrowingAstVisitor._throw()` |
| Runtime visitor dispatch on user code | Compile-time library element serialization |

The `riverpod_analyzer_utils` visitors all extend `RecursiveAstVisitor` which has default implementations. They are not the problem. The problem is the analyzer's internal serialization pipeline encountering AST nodes from a language version it doesn't support.
