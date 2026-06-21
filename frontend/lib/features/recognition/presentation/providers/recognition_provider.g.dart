// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'recognition_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(RecognitionFeedNotifier)
const recognitionFeedProvider = RecognitionFeedNotifierProvider._();

final class RecognitionFeedNotifierProvider
    extends $NotifierProvider<RecognitionFeedNotifier, RecognitionFeedState> {
  const RecognitionFeedNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'recognitionFeedProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$recognitionFeedNotifierHash();

  @$internal
  @override
  RecognitionFeedNotifier create() => RecognitionFeedNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(RecognitionFeedState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<RecognitionFeedState>(value),
    );
  }
}

String _$recognitionFeedNotifierHash() =>
    r'd893e01bf0255e02365a404d5b1289391f7df1db';

abstract class _$RecognitionFeedNotifier
    extends $Notifier<RecognitionFeedState> {
  RecognitionFeedState build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref = this.ref as $Ref<RecognitionFeedState, RecognitionFeedState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<RecognitionFeedState, RecognitionFeedState>,
              RecognitionFeedState,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}
