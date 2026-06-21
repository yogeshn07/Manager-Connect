import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:manager_connect/core/constants/supabase_constants.dart';
import 'package:manager_connect/core/network/api_error_handler.dart';
import 'package:manager_connect/features/growth/data/models/challenge_dto.dart';

class ChallengeRepository {
  ChallengeRepository(this._client);

  final SupabaseClient _client;

  static const _challengeSelect =
      'id, created_by, title, description, challenge_type, goal_type, '
      'goal_description, start_date, end_date, status, created_at, '
      'profiles(full_name)';

  static const _participantSelect =
      'id, challenge_id, user_id, joined_at, profiles(full_name, avatar_url)';

  Future<List<ChallengeDto>> getActive() async {
    try {
      final response = await _client
          .from(Table.challenges)
          .select(_challengeSelect)
          .eq('status', 'active')
          .order('end_date', ascending: true);
      return response.map(ChallengeDto.fromJson).toList();
    } catch (e) {
      throw mapSupabaseError(e);
    }
  }

  Future<List<ChallengeDto>> getCompleted() async {
    try {
      final response = await _client
          .from(Table.challenges)
          .select(_challengeSelect)
          .eq('status', 'ended')
          .order('end_date', ascending: false)
          .limit(30);
      return response.map(ChallengeDto.fromJson).toList();
    } catch (e) {
      throw mapSupabaseError(e);
    }
  }

  Future<ChallengeDto> getChallenge(String challengeId) async {
    try {
      final response = await _client
          .from(Table.challenges)
          .select(_challengeSelect)
          .eq('id', challengeId)
          .single();
      return ChallengeDto.fromJson(response);
    } catch (e) {
      throw mapSupabaseError(e);
    }
  }

  Future<ChallengeDto> createChallenge({
    required String createdBy,
    required String title,
    String? description,
    required String challengeType,
    required String goalType,
    String? goalDescription,
    required String startDate,
    required String endDate,
  }) async {
    try {
      final response = await _client
          .from(Table.challenges)
          .insert({
            'created_by': createdBy,
            'title': title,
            if (description != null) 'description': description,
            'challenge_type': challengeType,
            'goal_type': goalType,
            if (goalDescription != null) 'goal_description': goalDescription,
            'start_date': startDate,
            'end_date': endDate,
          })
          .select(_challengeSelect)
          .single();
      return ChallengeDto.fromJson(response);
    } catch (e) {
      throw mapSupabaseError(e);
    }
  }

  Future<List<ParticipantDto>> getParticipants(String challengeId) async {
    try {
      final response = await _client
          .from(Table.challengeParticipants)
          .select(_participantSelect)
          .eq('challenge_id', challengeId);
      return response.map(ParticipantDto.fromJson).toList();
    } catch (e) {
      throw mapSupabaseError(e);
    }
  }

  Future<void> join({
    required String challengeId,
    required String userId,
  }) async {
    try {
      await _client.from(Table.challengeParticipants).insert({
        'challenge_id': challengeId,
        'user_id': userId,
      });
    } catch (e) {
      throw mapSupabaseError(e);
    }
  }

  Future<void> leave({
    required String challengeId,
    required String userId,
  }) async {
    try {
      await _client
          .from(Table.challengeParticipants)
          .delete()
          .eq('challenge_id', challengeId)
          .eq('user_id', userId);
    } catch (e) {
      throw mapSupabaseError(e);
    }
  }

  Future<List<ProgressLogDto>> getProgressLogs(String challengeId) async {
    try {
      final response = await _client
          .from(Table.progressLogs)
          .select('id, challenge_id, user_id, log_date, value, note')
          .eq('challenge_id', challengeId)
          .order('log_date', ascending: false);
      return response.map(ProgressLogDto.fromJson).toList();
    } catch (e) {
      throw mapSupabaseError(e);
    }
  }

  Future<void> logProgress({
    required String challengeId,
    required String userId,
    required String challengeParticipantId,
    required String logDate,
    required double value,
    String? note,
  }) async {
    try {
      await _client.from(Table.progressLogs).upsert(
        {
          'challenge_id': challengeId,
          'user_id': userId,
          'challenge_participant_id': challengeParticipantId,
          'log_date': logDate,
          'value': value,
          if (note != null) 'note': note,
        },
        onConflict: 'challenge_id,user_id,log_date',
      );
    } catch (e) {
      throw mapSupabaseError(e);
    }
  }
}
