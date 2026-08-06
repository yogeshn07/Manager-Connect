// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'gi_news_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(GiNewsFeedNotifier)
const giNewsFeedProvider = GiNewsFeedNotifierProvider._();

final class GiNewsFeedNotifierProvider
    extends $NotifierProvider<GiNewsFeedNotifier, GINewsFeedState> {
  const GiNewsFeedNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'giNewsFeedProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$giNewsFeedNotifierHash();

  @$internal
  @override
  GiNewsFeedNotifier create() => GiNewsFeedNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(GINewsFeedState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<GINewsFeedState>(value),
    );
  }
}

String _$giNewsFeedNotifierHash() =>
    r'1cdb5d2efd93412ae2e3b741710e16845d62f098';

abstract class _$GiNewsFeedNotifier extends $Notifier<GINewsFeedState> {
  GINewsFeedState build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref = this.ref as $Ref<GINewsFeedState, GINewsFeedState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<GINewsFeedState, GINewsFeedState>,
              GINewsFeedState,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}
