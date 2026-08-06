// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'challenge_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(ChallengeListNotifier)
const challengeListProvider = ChallengeListNotifierProvider._();

final class ChallengeListNotifierProvider
    extends $NotifierProvider<ChallengeListNotifier, ChallengeListState> {
  const ChallengeListNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'challengeListProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$challengeListNotifierHash();

  @$internal
  @override
  ChallengeListNotifier create() => ChallengeListNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ChallengeListState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ChallengeListState>(value),
    );
  }
}

String _$challengeListNotifierHash() =>
    r'fc53b79db95147bf1f78011e4740c8a3705e3d62';

abstract class _$ChallengeListNotifier extends $Notifier<ChallengeListState> {
  ChallengeListState build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref = this.ref as $Ref<ChallengeListState, ChallengeListState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<ChallengeListState, ChallengeListState>,
              ChallengeListState,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}

@ProviderFor(ChallengeDetailNotifier)
const challengeDetailProvider = ChallengeDetailNotifierFamily._();

final class ChallengeDetailNotifierProvider
    extends $NotifierProvider<ChallengeDetailNotifier, ChallengeDetailState> {
  const ChallengeDetailNotifierProvider._({
    required ChallengeDetailNotifierFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'challengeDetailProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$challengeDetailNotifierHash();

  @override
  String toString() {
    return r'challengeDetailProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  ChallengeDetailNotifier create() => ChallengeDetailNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ChallengeDetailState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ChallengeDetailState>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is ChallengeDetailNotifierProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$challengeDetailNotifierHash() =>
    r'6a877ee23a793afd1485dacdacad769f2bcdd9fe';

final class ChallengeDetailNotifierFamily extends $Family
    with
        $ClassFamilyOverride<
          ChallengeDetailNotifier,
          ChallengeDetailState,
          ChallengeDetailState,
          ChallengeDetailState,
          String
        > {
  const ChallengeDetailNotifierFamily._()
    : super(
        retry: null,
        name: r'challengeDetailProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  ChallengeDetailNotifierProvider call(String challengeId) =>
      ChallengeDetailNotifierProvider._(argument: challengeId, from: this);

  @override
  String toString() => r'challengeDetailProvider';
}

abstract class _$ChallengeDetailNotifier
    extends $Notifier<ChallengeDetailState> {
  late final _$args = ref.$arg as String;
  String get challengeId => _$args;

  ChallengeDetailState build(String challengeId);
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build(_$args);
    final ref = this.ref as $Ref<ChallengeDetailState, ChallengeDetailState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<ChallengeDetailState, ChallengeDetailState>,
              ChallengeDetailState,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}
