import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:manager_connect/features/auth/presentation/providers/auth_notifier.dart';
import 'package:manager_connect/features/notifications/data/models/notification_dto.dart';
import 'package:manager_connect/features/notifications/presentation/providers/notification_provider.dart';
import 'package:manager_connect/shared/widgets/loading_state.dart';
import 'package:manager_connect/shared/widgets/error_state.dart';
import 'package:manager_connect/shared/widgets/mc/mc_colors.dart';
import 'package:manager_connect/shared/widgets/mc/mc_spacing.dart';
import 'package:manager_connect/shared/widgets/mc/mc_grid_identity.dart';
import 'package:manager_connect/shared/widgets/mc/mc_typography.dart';

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

  // ── Type icon/color maps ───────────────────────────────────────────────────

  IconData _typeIcon(String type) {
    return switch (type) {
      'recognition_received'                                          => Icons.star,
      'mention'                                                       => Icons.alternate_email,
      'comment_on_post'                                               => Icons.comment,
      'poll_reminder' || 'poll_created'                               => Icons.poll,
      'activity_created' || 'activity_updated' ||
          'activity_reminder_24h' || 'activity_reminder_1h'          => Icons.event,
      'activity_cancelled'                                            => Icons.event_busy,
      'challenge_created' || 'challenge_ending'                       => Icons.fitness_center,
      'challenge_ended'                                               => Icons.emoji_events,
      'connect_buddy_update'                                          => Icons.person,
      'admin_flag' || 'admin_member_registered'                       => Icons.admin_panel_settings,
      _                                                               => Icons.notifications,
    };
  }

  Color _typeIconColor(String type) {
    return switch (type) {
      'recognition_received'                                          => MCColors.amberDark,
      'mention' || 'poll_reminder' || 'poll_created'                  => MCColors.violet,
      'activity_created' || 'activity_updated' ||
          'activity_reminder_24h' || 'activity_reminder_1h' ||
          'activity_cancelled'                                        => MCColors.primaryMid,
      'challenge_created' || 'challenge_ending' || 'challenge_ended'  => MCColors.success,
      'comment_on_post'                                               => MCColors.primaryMid,
      'connect_buddy_update'                                          => MCColors.success,
      'admin_flag' || 'admin_member_registered'                       => MCColors.amberDark,
      _                                                               => MCColors.textMuted,
    };
  }

  Color _typeIconBg(String type) {
    return switch (type) {
      'recognition_received'                                          => MCColors.amberLight,
      'mention' || 'poll_reminder' || 'poll_created'                  => MCColors.violetLight,
      'activity_created' || 'activity_updated' ||
          'activity_reminder_24h' || 'activity_reminder_1h' ||
          'activity_cancelled'                                        => MCColors.primaryPale,
      'challenge_created' || 'challenge_ending' || 'challenge_ended'  => MCColors.successBg,
      'comment_on_post'                                               => MCColors.primaryPale,
      'connect_buddy_update'                                          => MCColors.successBg,
      'admin_flag' || 'admin_member_registered'                       => MCColors.amberLight,
      _                                                               => MCColors.borderLight,
    };
  }

  // ── Navigation / tap handling ──────────────────────────────────────────────

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
      'post'       => '/feed/post/$referenceId',
      'activity'   => '/events/event/$referenceId',
      'challenge'  => '/growth/challenge/$referenceId',
      'poll'       => '/events/poll/$referenceId',
      'recognition'=> '/feed',
      _            => null,
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

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(notificationProvider);

    return Scaffold(
      backgroundColor: MCColors.background,
      body: MCAmbientIdentityBackground(
        child: SafeArea(
          child: Column(
            children: [
              _buildTopBar(state),
              Expanded(child: _buildBody(state)),
            ],
          ),
        ),
      ),
    );
  }

  // ── Top bar ────────────────────────────────────────────────────────────────

  Widget _buildTopBar(NotificationState state) {
    return Container(
      height: MCSpacing.topBarHeight,
      decoration: const BoxDecoration(
        color: MCColors.card,
        border: Border(
          bottom: BorderSide(color: MCColors.borderLight),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: MCSpacing.pageH),
      child: Row(
        children: [
          // Back arrow
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: const Padding(
              padding: EdgeInsets.only(right: 8),
              child: Icon(
                Icons.arrow_back_ios_new,
                size: 20,
                color: MCColors.textPrimary,
              ),
            ),
          ),
          Expanded(
            child: Text('Notifications', style: MCTypography.h3),
          ),
          // Mark all read
          if (state.unreadCount > 0)
            GestureDetector(
              onTap: () =>
                  ref.read(notificationProvider.notifier).markAllRead(),
              child: Text(
                'Mark all read',
                style: MCTypography.labelSm.copyWith(
                  color: MCColors.primaryMid,
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ── Body ───────────────────────────────────────────────────────────────────

  Widget _buildBody(NotificationState state) {
    if (state.isLoading && state.items.isEmpty) {
      return const LoadingState();
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
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: () => ref.read(notificationProvider.notifier).refresh(),
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(
          MCSpacing.pageH,
          MCSpacing.sm,
          MCSpacing.pageH,
          MCSpacing.xl4,
        ),
        itemCount: 1, // wrap all items in a single card
        itemBuilder: (_, __) => _buildNotificationCard(state.items),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.notifications_none_outlined,
            size: 48,
            color: MCColors.textMuted,
          ),
          const SizedBox(height: 12),
          Text('No notifications', style: MCTypography.h4),
          const SizedBox(height: 4),
          Text("You're all caught up!", style: MCTypography.caption),
        ],
      ),
    );
  }

  // ── Notification card (grouped) ────────────────────────────────────────────

  Widget _buildNotificationCard(List<NotificationItemDto> items) {
    return Container(
      decoration: BoxDecoration(
        color: MCColors.card,
        borderRadius: BorderRadius.circular(MCSpacing.radiusMd),
        border: Border.all(color: MCColors.border),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F000000),
            blurRadius: 3,
            offset: Offset(0, 1),
          ),
        ],
      ),
      clipBehavior: Clip.hardEdge,
      child: Column(
        children: List.generate(items.length, (index) {
          final item = items[index];
          final isLast = index == items.length - 1;
          return Column(
            children: [
              _buildNotificationRow(item),
              if (!isLast)
                const Divider(
                  height: 1,
                  thickness: 1,
                  color: MCColors.borderLight,
                  indent: 0,
                  endIndent: 0,
                ),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildNotificationRow(NotificationItemDto item) {
    final icon = _typeIcon(item.type);
    final iconColor = _typeIconColor(item.type);
    final iconBg = _typeIconBg(item.type);

    return GestureDetector(
      onTap: () => _onNotificationTap(item),
      child: Container(
        color: item.isRead ? MCColors.card : MCColors.primaryPale,
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Left unread accent bar
              if (!item.isRead)
                Container(
                  width: 4,
                  color: MCColors.primaryMid,
                ),
              if (item.isRead) const SizedBox(width: 4),
              // Content
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: MCSpacing.cardPadH,
                    vertical: MCSpacing.sm,
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Type icon
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: iconBg,
                          borderRadius: BorderRadius.circular(MCSpacing.radiusSm),
                        ),
                        child: Icon(icon, size: 20, color: iconColor),
                      ),
                      const SizedBox(width: 12),
                      // Text content
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              item.title,
                              style: MCTypography.label.copyWith(
                                fontWeight: item.isRead
                                    ? FontWeight.w500
                                    : FontWeight.w700,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              item.body,
                              style: MCTypography.bodySm,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 3),
                            Text(
                              _formatRelativeTime(item.createdAt),
                              style: MCTypography.caption,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Unread dot
                      if (!item.isRead)
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: MCColors.primaryMid,
                            shape: BoxShape.circle,
                          ),
                        )
                      else
                        const SizedBox(width: 8),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
