import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:manager_connect/core/constants/supabase_constants.dart';
import 'package:manager_connect/features/notifications/data/models/notification_dto.dart';
import 'package:manager_connect/features/notifications/data/repositories/notification_repository.dart';
import 'package:manager_connect/shared/providers/supabase_provider.dart';

part 'notification_provider.g.dart';

class NotificationState {
  const NotificationState({
    this.items = const [],
    this.unreadCount = 0,
    this.isLoading = false,
    this.error,
  });

  final List<NotificationItemDto> items;
  final int unreadCount;
  final bool isLoading;
  final String? error;

  NotificationState copyWith({
    List<NotificationItemDto>? items,
    int? unreadCount,
    bool? isLoading,
    String? Function()? error,
  }) {
    return NotificationState(
      items: items ?? this.items,
      unreadCount: unreadCount ?? this.unreadCount,
      isLoading: isLoading ?? this.isLoading,
      error: error != null ? error() : this.error,
    );
  }
}

@Riverpod(keepAlive: true)
class NotificationNotifier extends _$NotificationNotifier {
  NotificationRepository? _repo;
  RealtimeChannel? _channel;
  String? _userId;

  @override
  NotificationState build() {
    final client = ref.watch(supabaseClientProvider);
    _repo = NotificationRepository(client);
    ref.onDispose(_disposeRealtime);
    return const NotificationState();
  }

  Future<void> load(String userId) async {
    _userId = userId;
    state = state.copyWith(isLoading: true, error: () => null);
    try {
      final results = await Future.wait([
        _repo!.getInbox(userId),
        _repo!.getUnreadCount(userId),
      ]);
      state = state.copyWith(
        items: results[0] as List<NotificationItemDto>,
        unreadCount: results[1] as int,
        isLoading: false,
      );
      _subscribeRealtime(userId);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString);
    }
  }

  Future<void> refresh() async {
    if (_userId == null) return;
    try {
      final results = await Future.wait([
        _repo!.getInbox(_userId!),
        _repo!.getUnreadCount(_userId!),
      ]);
      state = state.copyWith(
        items: results[0] as List<NotificationItemDto>,
        unreadCount: results[1] as int,
        error: () => null,
      );
    } catch (_) {}
  }

  Future<void> markRead(String notificationId) async {
    try {
      await _repo!.markRead(notificationId);
      state = state.copyWith(
        items: state.items.map((n) {
          if (n.id == notificationId) {
            return NotificationItemDto(
              id: n.id,
              recipientId: n.recipientId,
              actorId: n.actorId,
              type: n.type,
              title: n.title,
              body: n.body,
              referenceType: n.referenceType,
              referenceId: n.referenceId,
              isRead: true,
              readAt: DateTime.now(),
              createdAt: n.createdAt,
            );
          }
          return n;
        }).toList(),
        unreadCount: (state.unreadCount - 1).clamp(0, state.unreadCount),
      );
    } catch (_) {}
  }

  Future<void> markAllRead() async {
    if (_userId == null) return;
    try {
      await _repo!.markAllRead(_userId!);
      state = state.copyWith(
        items: state.items.map((n) {
          if (!n.isRead) {
            return NotificationItemDto(
              id: n.id,
              recipientId: n.recipientId,
              actorId: n.actorId,
              type: n.type,
              title: n.title,
              body: n.body,
              referenceType: n.referenceType,
              referenceId: n.referenceId,
              isRead: true,
              readAt: DateTime.now(),
              createdAt: n.createdAt,
            );
          }
          return n;
        }).toList(),
        unreadCount: 0,
      );
    } catch (_) {}
  }

  void _subscribeRealtime(String userId) {
    _disposeRealtime();
    final client = Supabase.instance.client;
    _channel = client
        .channel('notifications:inbox:$userId')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: Table.notificationInbox,
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'recipient_id',
            value: userId,
          ),
          callback: (_) {
            state = state.copyWith(unreadCount: state.unreadCount + 1);
            refresh();
          },
        )
        .subscribe();
  }

  void _disposeRealtime() {
    _channel?.unsubscribe();
    _channel = null;
  }
}
