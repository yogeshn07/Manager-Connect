import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:manager_connect/features/admin/data/models/admin_dto.dart';
import 'package:manager_connect/features/admin/data/repositories/admin_repository.dart';
import 'package:manager_connect/features/auth/data/models/profile_dto.dart';
import 'package:manager_connect/shared/providers/supabase_provider.dart';

part 'admin_provider.g.dart';

class AdminDashboardState {
  const AdminDashboardState({
    this.counts = const {},
    this.isLoading = false,
    this.error,
  });
  final Map<String, int> counts;
  final bool isLoading;
  final String? error;

  AdminDashboardState copyWith({
    Map<String, int>? counts,
    bool? isLoading,
    String? Function()? error,
  }) => AdminDashboardState(
    counts: counts ?? this.counts,
    isLoading: isLoading ?? this.isLoading,
    error: error != null ? error() : this.error,
  );
}

@Riverpod(keepAlive: true)
class AdminDashboardNotifier extends _$AdminDashboardNotifier {
  AdminRepository? _repo;

  @override
  AdminDashboardState build() {
    final client = ref.watch(supabaseClientProvider);
    _repo = AdminRepository(client);
    return const AdminDashboardState();
  }

  Future<void> load() async {
    state = state.copyWith(isLoading: true, error: () => null);
    try {
      final counts = await _repo!.getDashboardCounts();
      state = state.copyWith(counts: counts, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString);
    }
  }
}

class MemberManagementState {
  const MemberManagementState({
    this.members = const [],
    this.isLoading = false,
    this.error,
  });
  final List<ProfileDto> members;
  final bool isLoading;
  final String? error;

  MemberManagementState copyWith({
    List<ProfileDto>? members,
    bool? isLoading,
    String? Function()? error,
  }) => MemberManagementState(
    members: members ?? this.members,
    isLoading: isLoading ?? this.isLoading,
    error: error != null ? error() : this.error,
  );
}

@riverpod
class MemberManagementNotifier extends _$MemberManagementNotifier {
  AdminRepository? _repo;

  @override
  MemberManagementState build() {
    final client = ref.watch(supabaseClientProvider);
    _repo = AdminRepository(client);
    return const MemberManagementState();
  }

  Future<void> load() async {
    state = state.copyWith(isLoading: true, error: () => null);
    try {
      final members = await _repo!.getAllMembers();
      state = state.copyWith(members: members, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString);
    }
  }

  Future<void> deactivate(String userId) async {
    await _repo!.deactivateUser(userId);
    await load();
  }

  Future<void> reactivate(String userId) async {
    await _repo!.reactivateUser(userId);
    await load();
  }

  Future<void> remove(String userId) async {
    await _repo!.removeUser(userId);
    await load();
  }
}

class InvitationManagementState {
  const InvitationManagementState({
    this.invitations = const [],
    this.isLoading = false,
    this.error,
  });
  final List<InvitationDto> invitations;
  final bool isLoading;
  final String? error;

  InvitationManagementState copyWith({
    List<InvitationDto>? invitations,
    bool? isLoading,
    String? Function()? error,
  }) => InvitationManagementState(
    invitations: invitations ?? this.invitations,
    isLoading: isLoading ?? this.isLoading,
    error: error != null ? error() : this.error,
  );
}

@riverpod
class InvitationManagementNotifier extends _$InvitationManagementNotifier {
  AdminRepository? _repo;

  @override
  InvitationManagementState build() {
    final client = ref.watch(supabaseClientProvider);
    _repo = AdminRepository(client);
    return const InvitationManagementState();
  }

  Future<void> load() async {
    state = state.copyWith(isLoading: true, error: () => null);
    try {
      final invitations = await _repo!.getInvitations();
      state = state.copyWith(invitations: invitations, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString);
    }
  }

  Future<Map<String, dynamic>> send({
    required String name,
    String? email,
    String? phone,
  }) async {
    final result = await _repo!.sendInvitation(
      inviteeName: name,
      inviteeEmail: email,
      inviteePhone: phone,
    );
    await load();
    return result;
  }

  Future<void> revoke(String invitationId) async {
    await _repo!.revokeInvitation(invitationId);
    await load();
  }
}

class ModerationState {
  const ModerationState({
    this.flags = const [],
    this.isLoading = false,
    this.error,
  });
  final List<FlaggedContentDto> flags;
  final bool isLoading;
  final String? error;

  ModerationState copyWith({
    List<FlaggedContentDto>? flags,
    bool? isLoading,
    String? Function()? error,
  }) => ModerationState(
    flags: flags ?? this.flags,
    isLoading: isLoading ?? this.isLoading,
    error: error != null ? error() : this.error,
  );
}

@riverpod
class ModerationNotifier extends _$ModerationNotifier {
  AdminRepository? _repo;

  @override
  ModerationState build() {
    final client = ref.watch(supabaseClientProvider);
    _repo = AdminRepository(client);
    return const ModerationState();
  }

  Future<void> load() async {
    state = state.copyWith(isLoading: true, error: () => null);
    try {
      final flags = await _repo!.getPendingFlags();
      state = state.copyWith(flags: flags, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString);
    }
  }

  Future<void> resolve(String flagId, String action) async {
    await _repo!.resolveFlag(flagId: flagId, action: action);
    await load();
  }
}
