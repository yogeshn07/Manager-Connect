// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'review_queue_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(ReviewQueueNotifier)
const reviewQueueProvider = ReviewQueueNotifierProvider._();

final class ReviewQueueNotifierProvider
    extends $NotifierProvider<ReviewQueueNotifier, ReviewQueueState> {
  const ReviewQueueNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'reviewQueueProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$reviewQueueNotifierHash();

  @$internal
  @override
  ReviewQueueNotifier create() => ReviewQueueNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ReviewQueueState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ReviewQueueState>(value),
    );
  }
}

String _$reviewQueueNotifierHash() =>
    r'8951eac2e645f21751e683883f22a9fd887d3d73';

abstract class _$ReviewQueueNotifier extends $Notifier<ReviewQueueState> {
  ReviewQueueState build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref = this.ref as $Ref<ReviewQueueState, ReviewQueueState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<ReviewQueueState, ReviewQueueState>,
              ReviewQueueState,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}
