import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:manager_connect/features/auth/presentation/providers/auth_notifier.dart';
import 'package:manager_connect/features/notifications/data/models/notification_dto.dart';
import 'package:manager_connect/features/notifications/presentation/providers/notification_provider.dart';
import 'package:manager_connect/shared/widgets/error_state.dart';
import 'package:manager_connect/shared/widgets/loading_state.dart';

class NotificationCenterScreen extends ConsumerStatefulWidget {
  const NotificationCenterScreen({super.key});

  @override
  ConsumerState<NotificationCenterScreen> createState() =>
      _NotificationCenterScreenState();
}

class _NotificationCenterScreenState
    extends ConsumerState<NotificationCenterScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      final userId = _currentUserId;
      if (userId != null) {
        ref.read(notificationProvider.notifier).load(userId);
      }
    });
  }

  String? get _currentUserId {
    final authState = ref.read(authProvider);
    if (authState is AppAuthStateAuthenticated) {
      return authState.session.userId;
    }
    return null;
  }

  static const _typeIcons = {
    'event_rsvp': Icons.event,
    'event_update': Icons.update,
    'event_cancelled': Icons.event_busy,
    'challenge_joined': Icons.fitness_center,
    'challenge_progress': Icons.trending_up,
    'recognition_received': Icons.star,
    'poll_created': Icons.poll,
    'post_comment': Icons.comment,
    'post_reaction': Icons.thumb_up,
  };

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(notificationProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          if (state.unreadCount > 0)
            TextButton(
              onPressed: () =>
                  ref.read(notificationProvider.notifier).markAllRead(),
              child: const Text('Mark all read'),
            ),
        ],
      ),
      body: _buildBody(state),
    );
  }

  Widget _buildBody(NotificationState state) {
    if (state.isLoading && state.items.isEmpty) {
      return const LoadingState(message: 'Loading notifications...');
    }

    if (state.error != null && state.items.isEmpty) {
      return ErrorState(
        message: 'Failed to load notifications',
        onRetry: () {
          final userId = _currentUserId;
          if (userId != null) {
            ref.read(notificationProvider.notifier).load(userId);
          }
        },
      );
    }

    if (state.items.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.notifications_none,
              size: 64,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              'No notifications',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'You\'re all caught up',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => ref.read(notificationProvider.notifier).refresh(),
      child: ListView.builder(
        itemCount: state.items.length,
        itemBuilder: (context, index) =>
            _buildNotificationTile(state.items[index]),
      ),
    );
  }

  Widget _buildNotificationTile(NotificationItemDto item) {
    final theme = Theme.of(context);
    final icon = _typeIcons[item.type] ?? Icons.notifications;

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: item.isRead
            ? theme.colorScheme.surfaceContainerHighest
            : theme.colorScheme.primaryContainer,
        child: Icon(
          icon,
          size: 20,
          color: item.isRead
              ? theme.colorScheme.onSurfaceVariant
              : theme.colorScheme.primary,
        ),
      ),
      title: Text(
        item.title,
        style: theme.textTheme.bodyMedium?.copyWith(
          fontWeight: item.isRead ? FontWeight.normal : FontWeight.bold,
        ),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            item.body,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            _formatRelativeTime(item.createdAt),
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.outline,
              fontSize: 11,
            ),
          ),
        ],
      ),
      trailing: item.isRead
          ? null
          : Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: theme.colorScheme.primary,
                shape: BoxShape.circle,
              ),
            ),
      onTap: () => _onNotificationTap(item),
    );
  }

  void _onNotificationTap(NotificationItemDto item) {
    if (!item.isRead) {
      ref.read(notificationProvider.notifier).markRead(item.id);
    }

    final route = _resolveRoute(item.referenceType, item.referenceId);
    if (route != null) {
      context.push(route);
    }
  }

  String? _resolveRoute(String? referenceType, String? referenceId) {
    if (referenceType == null || referenceId == null) return null;

    return switch (referenceType) {
      'post' => '/feed/post/$referenceId',
      'activity' => '/events/event/$referenceId',
      'challenge' => '/growth/challenge/$referenceId',
      'poll' => '/events/poll/$referenceId',
      'recognition' => '/feed',
      _ => null,
    };
  }

  String _formatRelativeTime(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    if (diff.inDays < 30) return '${(diff.inDays / 7).floor()}w ago';
    return '${dt.day}/${dt.month}/${dt.year}';
  }
}
