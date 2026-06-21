import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:manager_connect/features/auth/data/models/profile_dto.dart';
import 'package:manager_connect/features/auth/data/repositories/profile_repository.dart';
import 'package:manager_connect/shared/providers/supabase_provider.dart';

part 'profile_provider.g.dart';

class ProfileState {
  const ProfileState({
    this.profile,
    this.isLoading = false,
    this.error,
  });

  final ProfileDto? profile;
  final bool isLoading;
  final String? error;

  ProfileState copyWith({
    ProfileDto? Function()? profile,
    bool? isLoading,
    String? Function()? error,
  }) {
    return ProfileState(
      profile: profile != null ? profile() : this.profile,
      isLoading: isLoading ?? this.isLoading,
      error: error != null ? error() : this.error,
    );
  }
}

@riverpod
class ProfileNotifier extends _$ProfileNotifier {
  ProfileRepository? _repo;

  @override
  ProfileState build(String userId) {
    final client = ref.watch(supabaseClientProvider);
    _repo = ProfileRepository(client);
    return const ProfileState();
  }

  Future<void> load() async {
    state = state.copyWith(isLoading: true, error: () => null);
    try {
      final profile = await _repo!.getProfile(userId);
      state = state.copyWith(
        profile: () => profile,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString);
    }
  }

  Future<void> updateProfile({
    String? fullName,
    String? title,
    String? bio,
    List<String>? interestTags,
  }) async {
    try {
      await _repo!.updateProfile(
        userId: userId,
        fullName: fullName,
        title: title,
        bio: bio,
        interestTags: interestTags,
      );
      await load();
    } catch (_) {}
  }

  Future<void> updateNotificationPreferences(
    Map<String, bool> prefs,
  ) async {
    try {
      await _repo!.updateProfile(
        userId: userId,
        notificationPreferences: prefs,
      );
      await load();
    } catch (_) {}
  }
}
