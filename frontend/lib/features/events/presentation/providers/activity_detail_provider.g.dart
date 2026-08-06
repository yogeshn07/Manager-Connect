// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'activity_detail_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(ActivityDetailNotifier)
const activityDetailProvider = ActivityDetailNotifierFamily._();

final class ActivityDetailNotifierProvider
    extends $NotifierProvider<ActivityDetailNotifier, ActivityDetailState> {
  const ActivityDetailNotifierProvider._({
    required ActivityDetailNotifierFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'activityDetailProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$activityDetailNotifierHash();

  @override
  String toString() {
    return r'activityDetailProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  ActivityDetailNotifier create() => ActivityDetailNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ActivityDetailState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ActivityDetailState>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is ActivityDetailNotifierProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$activityDetailNotifierHash() =>
    r'ffbb14fb82472a887db24057f948ee496d474a35';

final class ActivityDetailNotifierFamily extends $Family
    with
        $ClassFamilyOverride<
          ActivityDetailNotifier,
          ActivityDetailState,
          ActivityDetailState,
          ActivityDetailState,
          String
        > {
  const ActivityDetailNotifierFamily._()
    : super(
        retry: null,
        name: r'activityDetailProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  ActivityDetailNotifierProvider call(String activityId) =>
      ActivityDetailNotifierProvider._(argument: activityId, from: this);

  @override
  String toString() => r'activityDetailProvider';
}

abstract class _$ActivityDetailNotifier extends $Notifier<ActivityDetailState> {
  late final _$args = ref.$arg as String;
  String get activityId => _$args;

  ActivityDetailState build(String activityId);
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build(_$args);
    final ref = this.ref as $Ref<ActivityDetailState, ActivityDetailState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<ActivityDetailState, ActivityDetailState>,
              ActivityDetailState,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}
