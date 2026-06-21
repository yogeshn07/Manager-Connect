// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'post_detail_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(PostDetailNotifier)
const postDetailProvider = PostDetailNotifierFamily._();

final class PostDetailNotifierProvider
    extends $NotifierProvider<PostDetailNotifier, PostDetailState> {
  const PostDetailNotifierProvider._({
    required PostDetailNotifierFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'postDetailProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$postDetailNotifierHash();

  @override
  String toString() {
    return r'postDetailProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  PostDetailNotifier create() => PostDetailNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(PostDetailState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<PostDetailState>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is PostDetailNotifierProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$postDetailNotifierHash() =>
    r'83d510f6c2f9aa015223b95ee61c802c6be31fa8';

final class PostDetailNotifierFamily extends $Family
    with
        $ClassFamilyOverride<
          PostDetailNotifier,
          PostDetailState,
          PostDetailState,
          PostDetailState,
          String
        > {
  const PostDetailNotifierFamily._()
    : super(
        retry: null,
        name: r'postDetailProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  PostDetailNotifierProvider call(String postId) =>
      PostDetailNotifierProvider._(argument: postId, from: this);

  @override
  String toString() => r'postDetailProvider';
}

abstract class _$PostDetailNotifier extends $Notifier<PostDetailState> {
  late final _$args = ref.$arg as String;
  String get postId => _$args;

  PostDetailState build(String postId);
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build(_$args);
    final ref = this.ref as $Ref<PostDetailState, PostDetailState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<PostDetailState, PostDetailState>,
              PostDetailState,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}
