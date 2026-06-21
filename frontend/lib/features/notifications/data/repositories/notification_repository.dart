import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:manager_connect/core/constants/supabase_constants.dart';
import 'package:manager_connect/core/network/api_error_handler.dart';
import 'package:manager_connect/features/notifications/data/models/notification_dto.dart';

class NotificationRepository {
  NotificationRepository(this._client);

  final SupabaseClient _client;

  Future<List<NotificationItemDto>> getInbox(String userId) async {
    try {
      final response = await _client
          .from(Table.notificationInbox)
          .select()
          .eq('recipient_id', userId)
          .order('created_at', ascending: false)
          .limit(50);
      return response.map(NotificationItemDto.fromJson).toList();
    } catch (e) {
      throw mapSupabaseError(e);
    }
  }

  Future<int> getUnreadCount(String userId) async {
    try {
      final response = await _client
          .from(Table.notificationInbox)
          .select('id')
          .eq('recipient_id', userId)
          .eq('is_read', false);
      return (response as List).length;
    } catch (e) {
      throw mapSupabaseError(e);
    }
  }

  Future<void> markRead(String notificationId) async {
    try {
      await _client.from(Table.notificationInbox).update({
        'is_read': true,
        'read_at': DateTime.now().toUtc().toIso8601String(),
      }).eq('id', notificationId);
    } catch (e) {
      throw mapSupabaseError(e);
    }
  }

  Future<void> markAllRead(String userId) async {
    try {
      await _client
          .from(Table.notificationInbox)
          .update({
            'is_read': true,
            'read_at': DateTime.now().toUtc().toIso8601String(),
          })
          .eq('recipient_id', userId)
          .eq('is_read', false);
    } catch (e) {
      throw mapSupabaseError(e);
    }
  }
}
