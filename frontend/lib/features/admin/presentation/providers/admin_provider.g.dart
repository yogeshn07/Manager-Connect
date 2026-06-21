// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'admin_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(AdminDashboardNotifier)
const adminDashboardProvider = AdminDashboardNotifierProvider._();

final class AdminDashboardNotifierProvider
    extends $NotifierProvider<AdminDashboardNotifier, AdminDashboardState> {
  const AdminDashboardNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'adminDashboardProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$adminDashboardNotifierHash();

  @$internal
  @override
  AdminDashboardNotifier create() => AdminDashboardNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AdminDashboardState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AdminDashboardState>(value),
    );
  }
}

String _$adminDashboardNotifierHash() =>
    r'0d3d23ad6a2de3361bfb6bd70252048ffbbdfafc';

abstract class _$AdminDashboardNotifier extends $Notifier<AdminDashboardState> {
  AdminDashboardState build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref = this.ref as $Ref<AdminDashboardState, AdminDashboardState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AdminDashboardState, AdminDashboardState>,
              AdminDashboardState,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}

@ProviderFor(MemberManagementNotifier)
const memberManagementProvider = MemberManagementNotifierProvider._();

final class MemberManagementNotifierProvider
    extends $NotifierProvider<MemberManagementNotifier, MemberManagementState> {
  const MemberManagementNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'memberManagementProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$memberManagementNotifierHash();

  @$internal
  @override
  MemberManagementNotifier create() => MemberManagementNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(MemberManagementState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<MemberManagementState>(value),
    );
  }
}

String _$memberManagementNotifierHash() =>
    r'bc1e5e176d85a59de1a8ed6e0c526afc21cc35d8';

abstract class _$MemberManagementNotifier
    extends $Notifier<MemberManagementState> {
  MemberManagementState build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref = this.ref as $Ref<MemberManagementState, MemberManagementState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<MemberManagementState, MemberManagementState>,
              MemberManagementState,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}

@ProviderFor(InvitationManagementNotifier)
const invitationManagementProvider = InvitationManagementNotifierProvider._();

final class InvitationManagementNotifierProvider
    extends
        $NotifierProvider<
          InvitationManagementNotifier,
          InvitationManagementState
        > {
  const InvitationManagementNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'invitationManagementProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$invitationManagementNotifierHash();

  @$internal
  @override
  InvitationManagementNotifier create() => InvitationManagementNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(InvitationManagementState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<InvitationManagementState>(value),
    );
  }
}

String _$invitationManagementNotifierHash() =>
    r'82e51c973d53f0c55c522892d93ab6da714bd593';

abstract class _$InvitationManagementNotifier
    extends $Notifier<InvitationManagementState> {
  InvitationManagementState build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref =
        this.ref as $Ref<InvitationManagementState, InvitationManagementState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<InvitationManagementState, InvitationManagementState>,
              InvitationManagementState,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}

@ProviderFor(ModerationNotifier)
const moderationProvider = ModerationNotifierProvider._();

final class ModerationNotifierProvider
    extends $NotifierProvider<ModerationNotifier, ModerationState> {
  const ModerationNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'moderationProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$moderationNotifierHash();

  @$internal
  @override
  ModerationNotifier create() => ModerationNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ModerationState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ModerationState>(value),
    );
  }
}

String _$moderationNotifierHash() =>
    r'd9c748bf65bc0d04cd55ac6a62176a5a6bf8808d';

abstract class _$ModerationNotifier extends $Notifier<ModerationState> {
  ModerationState build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref = this.ref as $Ref<ModerationState, ModerationState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<ModerationState, ModerationState>,
              ModerationState,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}
