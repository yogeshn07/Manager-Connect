// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'statuses_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(StatusesNotifier)
const statusesProvider = StatusesNotifierProvider._();

final class StatusesNotifierProvider
    extends $AsyncNotifierProvider<StatusesNotifier, List<StatusDto>> {
  const StatusesNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'statusesProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$statusesNotifierHash();

  @$internal
  @override
  StatusesNotifier create() => StatusesNotifier();
}

String _$statusesNotifierHash() => r'cb7483e993cbf7d55ea8731d35cbfb6f9028f2b9';

abstract class _$StatusesNotifier extends $AsyncNotifier<List<StatusDto>> {
  FutureOr<List<StatusDto>> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref = this.ref as $Ref<AsyncValue<List<StatusDto>>, List<StatusDto>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<List<StatusDto>>, List<StatusDto>>,
              AsyncValue<List<StatusDto>>,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}
