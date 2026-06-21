import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:manager_connect/core/constants/supabase_constants.dart';
import 'package:manager_connect/core/network/api_error_handler.dart';
import 'package:manager_connect/features/analytics/data/models/analytics_dto.dart';

class AnalyticsRepository {
  AnalyticsRepository(this._client);

  final SupabaseClient _client;

  static const _statsSelect =
      'user_id, stat_month, events_attended, attendance_rate, '
      'challenges_joined, progress_logs_count, recognitions_received, '
      'recognitions_given, posts_count, composite_score';

  static const _statsWithProfileSelect =
      '$_statsSelect, profiles(full_name, avatar_url)';

  Future<List<MemberStatsDto>> getPersonalStats(String userId) async {
    try {
      final response = await _client
          .from(Table.memberMonthlyStats)
          .select(_statsSelect)
          .eq('user_id', userId)
          .order('stat_month', ascending: false)
          .limit(12);
      return response.map(MemberStatsDto.fromJson).toList();
    } catch (e) {
      throw mapSupabaseError(e);
    }
  }

  Future<List<HealthScoreDto>> getHealthScores() async {
    try {
      final response = await _client
          .from(Table.communityHealthScores)
          .select()
          .order('score_month', ascending: false)
          .limit(12);
      return response.map(HealthScoreDto.fromJson).toList();
    } catch (e) {
      throw mapSupabaseError(e);
    }
  }

  Future<List<MemberStatsDto>> getMonthlyRankings(String statMonth) async {
    try {
      final response = await _client
          .from(Table.memberMonthlyStats)
          .select(_statsWithProfileSelect)
          .eq('stat_month', statMonth)
          .order('composite_score', ascending: false);
      return response.map(MemberStatsDto.fromJson).toList();
    } catch (e) {
      throw mapSupabaseError(e);
    }
  }

  Future<List<MemberStatsDto>> getAllStats() async {
    try {
      final response = await _client
          .from(Table.memberMonthlyStats)
          .select(_statsWithProfileSelect)
          .order('stat_month', ascending: false);
      return response.map(MemberStatsDto.fromJson).toList();
    } catch (e) {
      throw mapSupabaseError(e);
    }
  }
}
