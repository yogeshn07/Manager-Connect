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
      'selected_tasks, profiles(full_name, avatar_url)';

  static const _participantSelect =
      'id, challenge_id, user_id, joined_at, profiles(full_name, avatar_url)';

  static const _progressSelect =
      'id, challenge_id, user_id, log_date, value, note, subtask_id';

  Future<List<ChallengeDto>> getActive() async {
    try {
      final response = await _client
          .from(Table.challenges)
          .select(_challengeSelect)
          .eq('status', 'active')
          .order('created_at', ascending: false);
      return response.map(ChallengeDto.fromJson).toList();
    } catch (e) {
      throw mapSupabaseError(e);
    }
  }

  Future<List<ChallengeDto>> getJoined(String userId) async {
    try {
      final participations = await _client
          .from(Table.challengeParticipants)
          .select('challenge_id')
          .eq('user_id', userId);
      if ((participations as List).isEmpty) return [];
      final ids = participations
          .map((p) => p['challenge_id'] as String)
          .toList();
      final response = await _client
          .from(Table.challenges)
          .select(_challengeSelect)
          .inFilter('id', ids)
          .order('created_at', ascending: false);
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
    List<Map<String, dynamic>> selectedTasks = const [],
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
            'selected_tasks': selectedTasks,
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
          .select(_progressSelect)
          .eq('challenge_id', challengeId)
          .order('log_date', ascending: false);
      return response.map(ProgressLogDto.fromJson).toList();
    } catch (e) {
      throw mapSupabaseError(e);
    }
  }

  Future<List<ProgressLogDto>> getUserProgressLogs(String userId) async {
    try {
      final response = await _client
          .from(Table.progressLogs)
          .select(_progressSelect)
          .eq('user_id', userId)
          .order('log_date', ascending: false);
      return response.map(ProgressLogDto.fromJson).toList();
    } catch (e) {
      throw mapSupabaseError(e);
    }
  }

  /// Returns subtask progress totals for one user across multiple challenges.
  /// Result: challengeId → subtaskId → cumulativeValue
  Future<Map<String, Map<String, double>>> getMyProgressForChallenges(
      String userId, List<String> challengeIds) async {
    if (challengeIds.isEmpty) return {};
    try {
      final response = await _client
          .from(Table.progressLogs)
          .select('challenge_id, subtask_id, value')
          .eq('user_id', userId)
          .inFilter('challenge_id', challengeIds);

      final result = <String, Map<String, double>>{};
      for (final row in response) {
        final cId = row['challenge_id'] as String;
        final sId = row['subtask_id'] as String? ?? '';
        final val = (row['value'] as num).toDouble();
        final cMap = result[cId] ??= {};
        cMap[sId] = (cMap[sId] ?? 0) + val;
      }
      return result;
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
    required String subtaskId,
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
          'subtask_id': subtaskId,
          if (note != null) 'note': note,
        },
        onConflict: 'challenge_id,user_id,log_date,subtask_id',
      );
    } catch (e) {
      throw mapSupabaseError(e);
    }
  }
}
