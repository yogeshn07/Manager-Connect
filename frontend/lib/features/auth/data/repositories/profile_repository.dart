import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:manager_connect/core/constants/supabase_constants.dart';
import 'package:manager_connect/core/errors/app_exception.dart';
import 'package:manager_connect/core/network/api_error_handler.dart';
import 'package:manager_connect/features/auth/data/models/profile_dto.dart';

class ProfileRepository {
  ProfileRepository(this._client);

  final SupabaseClient _client;

  static const _selectColumns =
      'id, full_name, avatar_url, title, bio, interest_tags, '
      'app_role, is_active, is_system_account, onboarding_completed';

  Future<ProfileDto?> getProfile(String userId) async {
    try {
      final response = await _client
          .from(Table.profiles)
          .select(_selectColumns)
          .eq('id', userId)
          .maybeSingle();

      if (response == null) return null;
      return ProfileDto.fromJson(response);
    } catch (e) {
      throw mapSupabaseError(e);
    }
  }

  Future<String> createProfile({
    required String token,
    required String fullName,
    String? title,
    String? bio,
    String? avatarStoragePath,
    List<String> interestTags = const [],
  }) async {
    try {
      final response = await _client.functions.invoke(
        'create-profile',
        body: {
          'token': token,
          'full_name': fullName,
          if (title != null) 'title': title,
          if (bio != null) 'bio': bio,
          if (avatarStoragePath != null)
            'avatar_storage_path': avatarStoragePath,
          'interest_tags': interestTags,
        },
      );
      if (response.status >= 400) {
        final data = response.data;
        if (data is Map<String, dynamic> && data['error'] != null) {
          final error = data['error'] as Map<String, dynamic>;
          throw AppException(
            error['message'] as String? ?? 'Failed to create profile',
            response.status,
          );
        }
        throw AppException('Failed to create profile', response.status);
      }
      final data = response.data as Map<String, dynamic>;
      return data['profile_id'] as String;
    } on AppException {
      rethrow;
    } catch (e) {
      throw mapSupabaseError(e);
    }
  }
}
