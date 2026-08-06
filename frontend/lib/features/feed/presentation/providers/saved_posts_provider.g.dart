// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'saved_posts_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(SavedPostsNotifier)
const savedPostsProvider = SavedPostsNotifierProvider._();

final class SavedPostsNotifierProvider
    extends $AsyncNotifierProvider<SavedPostsNotifier, Set<String>> {
  const SavedPostsNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'savedPostsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$savedPostsNotifierHash();

  @$internal
  @override
  SavedPostsNotifier create() => SavedPostsNotifier();
}

String _$savedPostsNotifierHash() =>
    r'83bf96abb9cfec07770719d43409ac924b560e3c';

abstract class _$SavedPostsNotifier extends $AsyncNotifier<Set<String>> {
  FutureOr<Set<String>> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref = this.ref as $Ref<AsyncValue<Set<String>>, Set<String>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<Set<String>>, Set<String>>,
              AsyncValue<Set<String>>,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}
