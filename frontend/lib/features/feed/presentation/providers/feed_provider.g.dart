// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'feed_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(FeedNotifier)
const feedProvider = FeedNotifierProvider._();

final class FeedNotifierProvider
    extends $NotifierProvider<FeedNotifier, FeedState> {
  const FeedNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'feedProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$feedNotifierHash();

  @$internal
  @override
  FeedNotifier create() => FeedNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(FeedState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<FeedState>(value),
    );
  }
}

String _$feedNotifierHash() => r'66274ef401240ee11aa1f3d894d60a3e06492fd0';

abstract class _$FeedNotifier extends $Notifier<FeedState> {
  FeedState build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref = this.ref as $Ref<FeedState, FeedState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<FeedState, FeedState>,
              FeedState,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}
