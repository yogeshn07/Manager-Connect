// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'auth_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(AuthNotifier)
const authProvider = AuthNotifierProvider._();

final class AuthNotifierProvider
    extends $NotifierProvider<AuthNotifier, AppAuthState> {
  const AuthNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'authProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$authNotifierHash();

  @$internal
  @override
  AuthNotifier create() => AuthNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AppAuthState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AppAuthState>(value),
    );
  }
}

String _$authNotifierHash() => r'7b0832cf4c34c5d9f00e64df4e20f5e9df6aacb3';

abstract class _$AuthNotifier extends $Notifier<AppAuthState> {
  AppAuthState build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref = this.ref as $Ref<AppAuthState, AppAuthState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AppAuthState, AppAuthState>,
              AppAuthState,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}
