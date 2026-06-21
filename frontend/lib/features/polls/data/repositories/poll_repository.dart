import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:manager_connect/core/constants/supabase_constants.dart';
import 'package:manager_connect/core/errors/app_exception.dart';
import 'package:manager_connect/core/network/api_error_handler.dart';
import 'package:manager_connect/features/polls/data/models/poll_dto.dart';

class PollRepository {
  PollRepository(this._client);

  final SupabaseClient _client;

  static const _pollSelect =
      'id, activity_id, created_by, question, closes_at, is_closed, created_at, '
      'poll_options(id, poll_id, option_text, display_order, poll_votes(id))';

  Future<List<PollDto>> getPolls({bool openOnly = false}) async {
    try {
      var query = _client.from(Table.polls).select(_pollSelect);
      if (openOnly) {
        query = query.eq('is_closed', false);
      }
      final response = await query.order('created_at', ascending: false);
      return response.map(PollDto.fromJson).toList();
    } catch (e) {
      throw mapSupabaseError(e);
    }
  }

  Future<List<PollDto>> getPollsForActivity(String activityId) async {
    try {
      final response = await _client
          .from(Table.polls)
          .select(_pollSelect)
          .eq('activity_id', activityId)
          .order('created_at', ascending: false);
      return response.map(PollDto.fromJson).toList();
    } catch (e) {
      throw mapSupabaseError(e);
    }
  }

  Future<PollDto> getPoll(String pollId) async {
    try {
      final response = await _client
          .from(Table.polls)
          .select(_pollSelect)
          .eq('id', pollId)
          .single();
      return PollDto.fromJson(response);
    } catch (e) {
      throw mapSupabaseError(e);
    }
  }

  Future<Map<String, dynamic>> createPoll({
    required String question,
    required List<String> options,
    required DateTime closesAt,
    String? activityId,
  }) async {
    try {
      final response = await _client.functions.invoke(
        'create-poll',
        body: {
          'question': question,
          'options': options,
          'closes_at': closesAt.toUtc().toIso8601String(),
          if (activityId != null) 'activity_id': activityId,
        },
      );
      if (response.status >= 400) {
        final data = response.data;
        if (data is Map<String, dynamic> && data['error'] != null) {
          final error = data['error'] as Map<String, dynamic>;
          throw AppException(
            error['message'] as String? ?? 'Failed to create poll',
            response.status,
          );
        }
        throw AppException('Failed to create poll', response.status);
      }
      return response.data as Map<String, dynamic>;
    } on AppException {
      rethrow;
    } catch (e) {
      throw mapSupabaseError(e);
    }
  }

  Future<void> vote({
    required String pollId,
    required String pollOptionId,
    required String userId,
  }) async {
    try {
      await _client.from(Table.pollVotes).insert({
        'poll_id': pollId,
        'poll_option_id': pollOptionId,
        'user_id': userId,
      });
    } catch (e) {
      throw mapSupabaseError(e);
    }
  }

  Future<String?> getUserVoteOptionId({
    required String pollId,
    required String userId,
  }) async {
    try {
      final response = await _client
          .from(Table.pollVotes)
          .select('poll_option_id')
          .eq('poll_id', pollId)
          .eq('user_id', userId)
          .maybeSingle();
      if (response == null) return null;
      return response['poll_option_id'] as String;
    } catch (e) {
      throw mapSupabaseError(e);
    }
  }
}
