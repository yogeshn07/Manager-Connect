// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'poll_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(PollDetailNotifier)
const pollDetailProvider = PollDetailNotifierFamily._();

final class PollDetailNotifierProvider
    extends $NotifierProvider<PollDetailNotifier, PollDetailState> {
  const PollDetailNotifierProvider._({
    required PollDetailNotifierFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'pollDetailProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$pollDetailNotifierHash();

  @override
  String toString() {
    return r'pollDetailProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  PollDetailNotifier create() => PollDetailNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(PollDetailState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<PollDetailState>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is PollDetailNotifierProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$pollDetailNotifierHash() =>
    r'ec8e50ed9ebe7edc16ea94daa66148d0d54c72c5';

final class PollDetailNotifierFamily extends $Family
    with
        $ClassFamilyOverride<
          PollDetailNotifier,
          PollDetailState,
          PollDetailState,
          PollDetailState,
          String
        > {
  const PollDetailNotifierFamily._()
    : super(
        retry: null,
        name: r'pollDetailProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  PollDetailNotifierProvider call(String pollId) =>
      PollDetailNotifierProvider._(argument: pollId, from: this);

  @override
  String toString() => r'pollDetailProvider';
}

abstract class _$PollDetailNotifier extends $Notifier<PollDetailState> {
  late final _$args = ref.$arg as String;
  String get pollId => _$args;

  PollDetailState build(String pollId);
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build(_$args);
    final ref = this.ref as $Ref<PollDetailState, PollDetailState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<PollDetailState, PollDetailState>,
              PollDetailState,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}
