// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'analytics_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(AnalyticsNotifier)
const analyticsProvider = AnalyticsNotifierProvider._();

final class AnalyticsNotifierProvider
    extends $NotifierProvider<AnalyticsNotifier, AnalyticsState> {
  const AnalyticsNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'analyticsProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$analyticsNotifierHash();

  @$internal
  @override
  AnalyticsNotifier create() => AnalyticsNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AnalyticsState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AnalyticsState>(value),
    );
  }
}

String _$analyticsNotifierHash() => r'5d9c3871dcbab80f776205410f1757ec00514d92';

abstract class _$AnalyticsNotifier extends $Notifier<AnalyticsState> {
  AnalyticsState build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref = this.ref as $Ref<AnalyticsState, AnalyticsState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AnalyticsState, AnalyticsState>,
              AnalyticsState,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}

@ProviderFor(RankingsNotifier)
const rankingsProvider = RankingsNotifierProvider._();

final class RankingsNotifierProvider
    extends $NotifierProvider<RankingsNotifier, RankingsState> {
  const RankingsNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'rankingsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$rankingsNotifierHash();

  @$internal
  @override
  RankingsNotifier create() => RankingsNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(RankingsState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<RankingsState>(value),
    );
  }
}

String _$rankingsNotifierHash() => r'523e1fdca81b1efc3a0e93d90692fa8ba1654586';

abstract class _$RankingsNotifier extends $Notifier<RankingsState> {
  RankingsState build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref = this.ref as $Ref<RankingsState, RankingsState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<RankingsState, RankingsState>,
              RankingsState,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}
