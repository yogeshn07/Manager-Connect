// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'activities_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(ActivitiesNotifier)
const activitiesProvider = ActivitiesNotifierProvider._();

final class ActivitiesNotifierProvider
    extends $NotifierProvider<ActivitiesNotifier, ActivitiesState> {
  const ActivitiesNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'activitiesProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$activitiesNotifierHash();

  @$internal
  @override
  ActivitiesNotifier create() => ActivitiesNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ActivitiesState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ActivitiesState>(value),
    );
  }
}

String _$activitiesNotifierHash() =>
    r'6593f7226f566217a3b7dfbe7cce539cbfeed228';

abstract class _$ActivitiesNotifier extends $Notifier<ActivitiesState> {
  ActivitiesState build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref = this.ref as $Ref<ActivitiesState, ActivitiesState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<ActivitiesState, ActivitiesState>,
              ActivitiesState,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}
