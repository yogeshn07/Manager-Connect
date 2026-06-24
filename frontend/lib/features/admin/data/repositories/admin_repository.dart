import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:manager_connect/core/constants/supabase_constants.dart';
import 'package:manager_connect/core/errors/app_exception.dart';
import 'package:manager_connect/core/network/api_error_handler.dart';
import 'package:manager_connect/features/admin/data/models/admin_dto.dart';
import 'package:manager_connect/features/auth/data/models/profile_dto.dart';

class AdminRepository {
  AdminRepository(this._client);

  final SupabaseClient _client;

  // --- Dashboard ---

  Future<Map<String, int>> getDashboardCounts() async {
    try {
      final results = await Future.wait([
        _client.from(Table.profiles).select('id').eq('is_system_account', false),
        _client.from(Table.profiles).select('id').eq('is_active', true).eq('is_system_account', false),
        _client.from(Table.invitations).select('id').eq('status', 'pending'),
        _client.from(Table.flaggedContent).select('id').eq('status', 'pending'),
        _client.from(Table.posts).select('id').eq('is_deleted', false),
        _client.from(Table.activities).select('id'),
        _client.from(Table.challenges).select('id'),
      ]);
      return {
        'total_members': (results[0] as List).length,
        'active_members': (results[1] as List).length,
        'pending_invitations': (results[2] as List).length,
        'pending_flags': (results[3] as List).length,
        'total_posts': (results[4] as List).length,
        'total_activities': (results[5] as List).length,
        'total_challenges': (results[6] as List).length,
      };
    } catch (e) {
      throw mapSupabaseError(e);
    }
  }

  // --- Members ---

  Future<List<ProfileDto>> getAllMembers() async {
    try {
      final response = await _client
          .from(Table.profiles)
          .select('id, full_name, avatar_url, title, bio, interest_tags, '
              'app_role, is_active, is_system_account, onboarding_completed, '
              'notification_preferences, last_active_at, created_at')
          .eq('is_system_account', false)
          .order('full_name');
      return response.map(ProfileDto.fromJson).toList();
    } catch (e) {
      throw mapSupabaseError(e);
    }
  }

  Future<void> deactivateUser(String userId) async {
    try {
      final response = await _client.functions.invoke(
        'deactivate-user',
        body: {'user_id': userId},
      );
      _checkEfResponse(response, 'deactivate user');
    } on AppException {
      rethrow;
    } catch (e) {
      throw mapSupabaseError(e);
    }
  }

  Future<void> reactivateUser(String userId) async {
    try {
      final response = await _client.functions.invoke(
        'deactivate-user',
        body: {'user_id': userId, 'reactivate': true},
      );
      _checkEfResponse(response, 'reactivate user');
    } on AppException {
      rethrow;
    } catch (e) {
      throw mapSupabaseError(e);
    }
  }

  Future<void> removeUser(String userId) async {
    try {
      final response = await _client.functions.invoke(
        'remove-user',
        body: {'user_id': userId},
      );
      _checkEfResponse(response, 'remove user');
    } on AppException {
      rethrow;
    } catch (e) {
      throw mapSupabaseError(e);
    }
  }

  // --- Invitations ---

  Future<List<InvitationDto>> getInvitations() async {
    try {
      final response = await _client
          .from(Table.invitations)
          .select('id, invitee_name, invitee_email, invitee_phone, '
              'status, invited_by, expires_at, created_at')
          .order('created_at', ascending: false)
          .limit(100);
      return response.map(InvitationDto.fromJson).toList();
    } catch (e) {
      throw mapSupabaseError(e);
    }
  }

  Future<Map<String, dynamic>> sendInvitation({
    required String inviteeName,
    String? inviteeEmail,
    String? inviteePhone,
  }) async {
    try {
      final response = await _client.functions.invoke(
        'send-invitation',
        body: {
          'invitee_name': inviteeName,
          if (inviteeEmail != null) 'invitee_email': inviteeEmail,
          if (inviteePhone != null) 'invitee_phone': inviteePhone,
        },
      );
      _checkEfResponse(response, 'send invitation');
      return response.data as Map<String, dynamic>;
    } on AppException {
      rethrow;
    } catch (e) {
      throw mapSupabaseError(e);
    }
  }

  Future<void> revokeInvitation(String invitationId) async {
    try {
      final response = await _client.functions.invoke(
        'revoke-invitation',
        body: {'invitation_id': invitationId},
      );
      _checkEfResponse(response, 'revoke invitation');
    } on AppException {
      rethrow;
    } catch (e) {
      throw mapSupabaseError(e);
    }
  }

  // --- Moderation ---

  Future<List<FlaggedContentDto>> getPendingFlags() async {
    try {
      final response = await _client
          .from(Table.flaggedContent)
          .select('id, reporter_id, content_type, content_id, reason, '
              'status, created_at, profiles(full_name)')
          .eq('status', 'pending')
          .order('created_at', ascending: false);
      return response.map(FlaggedContentDto.fromJson).toList();
    } catch (e) {
      throw mapSupabaseError(e);
    }
  }

  Future<void> resolveFlag({
    required String flagId,
    required String action,
  }) async {
    try {
      final response = await _client.functions.invoke(
        'resolve-flag',
        body: {'flag_id': flagId, 'action': action},
      );
      _checkEfResponse(response, 'resolve flag');
    } on AppException {
      rethrow;
    } catch (e) {
      throw mapSupabaseError(e);
    }
  }

  // --- Pin ---

  Future<void> pinPost(String postId) async {
    try {
      final response = await _client.functions.invoke(
        'pin-announcement',
        body: {'post_id': postId, 'action': 'pin'},
      );
      _checkEfResponse(response, 'pin announcement');
    } on AppException {
      rethrow;
    } catch (e) {
      throw mapSupabaseError(e);
    }
  }

  Future<void> unpinPost() async {
    try {
      final response = await _client.functions.invoke(
        'pin-announcement',
        body: {'action': 'unpin'},
      );
      _checkEfResponse(response, 'unpin announcement');
    } on AppException {
      rethrow;
    } catch (e) {
      throw mapSupabaseError(e);
    }
  }

  void _checkEfResponse(FunctionResponse response, String operation) {
    if (response.status >= 400) {
      final data = response.data;
      if (data is Map<String, dynamic> && data['error'] != null) {
        final error = data['error'] as Map<String, dynamic>;
        throw AppException(
          error['message'] as String? ?? 'Failed to $operation',
          response.status,
        );
      }
      throw AppException('Failed to $operation', response.status);
    }
  }
}
