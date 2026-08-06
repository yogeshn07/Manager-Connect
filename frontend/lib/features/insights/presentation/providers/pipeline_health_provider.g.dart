// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'pipeline_health_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(PipelineHealthNotifier)
const pipelineHealthProvider = PipelineHealthNotifierProvider._();

final class PipelineHealthNotifierProvider
    extends $NotifierProvider<PipelineHealthNotifier, PipelineHealthState> {
  const PipelineHealthNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'pipelineHealthProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$pipelineHealthNotifierHash();

  @$internal
  @override
  PipelineHealthNotifier create() => PipelineHealthNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(PipelineHealthState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<PipelineHealthState>(value),
    );
  }
}

String _$pipelineHealthNotifierHash() =>
    r'1037c2e9861f6cb3f58d59a6b3db065dbad2d69f';

abstract class _$PipelineHealthNotifier extends $Notifier<PipelineHealthState> {
  PipelineHealthState build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref = this.ref as $Ref<PipelineHealthState, PipelineHealthState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<PipelineHealthState, PipelineHealthState>,
              PipelineHealthState,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}
