// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'submit_insight_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(SubmitInsightNotifier)
const submitInsightProvider = SubmitInsightNotifierProvider._();

final class SubmitInsightNotifierProvider
    extends $NotifierProvider<SubmitInsightNotifier, SubmitInsightState> {
  const SubmitInsightNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'submitInsightProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$submitInsightNotifierHash();

  @$internal
  @override
  SubmitInsightNotifier create() => SubmitInsightNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SubmitInsightState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SubmitInsightState>(value),
    );
  }
}

String _$submitInsightNotifierHash() =>
    r'fe254ee1d2ca70139cec13f633c18151f2cdfbc7';

abstract class _$SubmitInsightNotifier extends $Notifier<SubmitInsightState> {
  SubmitInsightState build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref = this.ref as $Ref<SubmitInsightState, SubmitInsightState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<SubmitInsightState, SubmitInsightState>,
              SubmitInsightState,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}
