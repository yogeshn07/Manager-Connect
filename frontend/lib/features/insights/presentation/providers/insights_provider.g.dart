// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'insights_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(InsightsFeedNotifier)
const insightsFeedProvider = InsightsFeedNotifierProvider._();

final class InsightsFeedNotifierProvider
    extends $NotifierProvider<InsightsFeedNotifier, InsightsFeedState> {
  const InsightsFeedNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'insightsFeedProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$insightsFeedNotifierHash();

  @$internal
  @override
  InsightsFeedNotifier create() => InsightsFeedNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(InsightsFeedState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<InsightsFeedState>(value),
    );
  }
}

String _$insightsFeedNotifierHash() =>
    r'd88c7ae6e4d127d6fe84f3b373cb9c508e745581';

abstract class _$InsightsFeedNotifier extends $Notifier<InsightsFeedState> {
  InsightsFeedState build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref = this.ref as $Ref<InsightsFeedState, InsightsFeedState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<InsightsFeedState, InsightsFeedState>,
              InsightsFeedState,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}

@ProviderFor(InsightDetailNotifier)
const insightDetailProvider = InsightDetailNotifierProvider._();

final class InsightDetailNotifierProvider
    extends $NotifierProvider<InsightDetailNotifier, InsightDetailState> {
  const InsightDetailNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'insightDetailProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$insightDetailNotifierHash();

  @$internal
  @override
  InsightDetailNotifier create() => InsightDetailNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(InsightDetailState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<InsightDetailState>(value),
    );
  }
}

String _$insightDetailNotifierHash() =>
    r'c1189ecb376006b9f05d1c3dec0b65ad0496e738';

abstract class _$InsightDetailNotifier extends $Notifier<InsightDetailState> {
  InsightDetailState build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref = this.ref as $Ref<InsightDetailState, InsightDetailState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<InsightDetailState, InsightDetailState>,
              InsightDetailState,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}
