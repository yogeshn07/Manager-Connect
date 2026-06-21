import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:manager_connect/core/constants/supabase_constants.dart';
import 'package:manager_connect/core/errors/app_exception.dart';
import 'package:manager_connect/core/network/api_error_handler.dart';
import 'package:manager_connect/features/events/data/models/activity_dto.dart';

class ActivityRepository {
  ActivityRepository(this._client);

  final SupabaseClient _client;

  static const _activitySelect =
      'id, created_by, title, description, event_category, event_type, '
      'location, event_date, cost_note, status, created_at, '
      'profiles(full_name, avatar_url)';

  static const _rsvpSelect =
      'id, activity_id, user_id, status, '
      'profiles(full_name, avatar_url)';

  Future<List<ActivityDto>> getUpcoming({String? category}) async {
    try {
      var query = _client
          .from(Table.activities)
          .select(_activitySelect)
          .eq('status', 'active')
          .gte('event_date', DateTime.now().toUtc().toIso8601String());

      if (category != null) {
        query = query.eq('event_category', category);
      }

      final response =
          await query.order('event_date', ascending: true);
      return response.map(ActivityDto.fromJson).toList();
    } catch (e) {
      throw mapSupabaseError(e);
    }
  }

  Future<List<ActivityDto>> getPast() async {
    try {
      final response = await _client
          .from(Table.activities)
          .select(_activitySelect)
          .lt('event_date', DateTime.now().toUtc().toIso8601String())
          .order('event_date', ascending: false)
          .limit(50);
      return response.map(ActivityDto.fromJson).toList();
    } catch (e) {
      throw mapSupabaseError(e);
    }
  }

  Future<ActivityDto> getActivity(String activityId) async {
    try {
      final response = await _client
          .from(Table.activities)
          .select(_activitySelect)
          .eq('id', activityId)
          .single();
      return ActivityDto.fromJson(response);
    } catch (e) {
      throw mapSupabaseError(e);
    }
  }

  Future<ActivityDto> createActivity({
    required String createdBy,
    required String title,
    String? description,
    required String eventCategory,
    String? eventType,
    String? location,
    required DateTime eventDate,
    String? costNote,
  }) async {
    try {
      final response = await _client
          .from(Table.activities)
          .insert({
            'created_by': createdBy,
            'title': title,
            if (description != null) 'description': description,
            'event_category': eventCategory,
            if (eventType != null) 'event_type': eventType,
            if (location != null) 'location': location,
            'event_date': eventDate.toUtc().toIso8601String(),
            if (costNote != null) 'cost_note': costNote,
          })
          .select(_activitySelect)
          .single();
      return ActivityDto.fromJson(response);
    } catch (e) {
      throw mapSupabaseError(e);
    }
  }

  Future<void> cancelActivity(String activityId) async {
    try {
      final response = await _client.functions.invoke(
        'cancel-activity',
        body: {'activity_id': activityId},
      );
      if (response.status >= 400) {
        final data = response.data;
        if (data is Map<String, dynamic> && data['error'] != null) {
          final error = data['error'] as Map<String, dynamic>;
          throw AppException(
            error['message'] as String? ?? 'Failed to cancel',
            response.status,
          );
        }
        throw AppException('Failed to cancel activity', response.status);
      }
    } on AppException {
      rethrow;
    } catch (e) {
      throw mapSupabaseError(e);
    }
  }

  // --- RSVPs ---

  Future<List<RsvpDto>> getRsvps(String activityId) async {
    try {
      final response = await _client
          .from(Table.activityRsvps)
          .select(_rsvpSelect)
          .eq('activity_id', activityId);
      return response.map(RsvpDto.fromJson).toList();
    } catch (e) {
      throw mapSupabaseError(e);
    }
  }

  Future<void> upsertRsvp({
    required String activityId,
    required String userId,
    required String status,
  }) async {
    try {
      await _client.from(Table.activityRsvps).upsert(
        {
          'activity_id': activityId,
          'user_id': userId,
          'status': status,
        },
        onConflict: 'activity_id,user_id',
      );
    } catch (e) {
      throw mapSupabaseError(e);
    }
  }

  Future<void> withdrawRsvp({
    required String activityId,
    required String userId,
  }) async {
    try {
      await _client
          .from(Table.activityRsvps)
          .delete()
          .eq('activity_id', activityId)
          .eq('user_id', userId);
    } catch (e) {
      throw mapSupabaseError(e);
    }
  }

  // --- Updates ---

  Future<List<ActivityUpdateDto>> getUpdates(String activityId) async {
    try {
      final response = await _client
          .from(Table.activityUpdates)
          .select('id, activity_id, author_id, content, created_at')
          .eq('activity_id', activityId)
          .order('created_at');
      return response.map(ActivityUpdateDto.fromJson).toList();
    } catch (e) {
      throw mapSupabaseError(e);
    }
  }

  Future<void> postUpdate({
    required String activityId,
    required String content,
  }) async {
    try {
      final response = await _client.functions.invoke(
        'post-activity-update',
        body: {'activity_id': activityId, 'content': content},
      );
      if (response.status >= 400) {
        final data = response.data;
        if (data is Map<String, dynamic> && data['error'] != null) {
          final error = data['error'] as Map<String, dynamic>;
          throw AppException(
            error['message'] as String? ?? 'Failed to post update',
            response.status,
          );
        }
        throw AppException('Failed to post update', response.status);
      }
    } on AppException {
      rethrow;
    } catch (e) {
      throw mapSupabaseError(e);
    }
  }
}
