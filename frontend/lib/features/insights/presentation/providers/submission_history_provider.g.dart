// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'submission_history_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(SubmissionHistoryNotifier)
const submissionHistoryProvider = SubmissionHistoryNotifierProvider._();

final class SubmissionHistoryNotifierProvider
    extends
        $NotifierProvider<SubmissionHistoryNotifier, SubmissionHistoryState> {
  const SubmissionHistoryNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'submissionHistoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$submissionHistoryNotifierHash();

  @$internal
  @override
  SubmissionHistoryNotifier create() => SubmissionHistoryNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SubmissionHistoryState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SubmissionHistoryState>(value),
    );
  }
}

String _$submissionHistoryNotifierHash() =>
    r'1841a688f4616c221e242fd25386ef235b3aa435';

abstract class _$SubmissionHistoryNotifier
    extends $Notifier<SubmissionHistoryState> {
  SubmissionHistoryState build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref =
        this.ref as $Ref<SubmissionHistoryState, SubmissionHistoryState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<SubmissionHistoryState, SubmissionHistoryState>,
              SubmissionHistoryState,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}
