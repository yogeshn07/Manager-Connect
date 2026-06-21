import 'package:flutter/material.dart';
import 'package:manager_connect/core/constants/app_constants.dart';
import 'package:manager_connect/core/theme/app_theme_extensions.dart';
import 'package:manager_connect/features/feed/data/models/post_dto.dart';

class PostCard extends StatelessWidget {
  const PostCard({required this.post, this.onTap, super.key});

  final PostDto post;
  final VoidCallback? onTap;

  bool get _isConnectBuddy =>
      post.author?.isSystemAccount == true ||
      post.authorId == AppConstants.connectBuddySystemAccountId;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ext = theme.extension<AppThemeExtension>();

    Color? cardColor;
    if (post.isPinned && ext != null) {
      cardColor = ext.pinnedPostBackground;
    } else if (_isConnectBuddy && ext != null) {
      cardColor = ext.connectBuddyPostBackground;
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      color: cardColor,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context),
              const SizedBox(height: 12),
              Text(post.content, style: theme.textTheme.bodyLarge),
              if (post.isPinned) ...[
                const SizedBox(height: 8),
                const Chip(
                  avatar: Icon(Icons.push_pin, size: 16),
                  label: Text('Pinned'),
                  visualDensity: VisualDensity.compact,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final theme = Theme.of(context);
    final ext = theme.extension<AppThemeExtension>();
    final name = post.author?.fullName ?? 'Unknown';
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';

    return Row(
      children: [
        CircleAvatar(
          radius: 20,
          backgroundColor: _isConnectBuddy
              ? ext?.connectBuddyBadgeColor
              : theme.colorScheme.primaryContainer,
          child: _isConnectBuddy
              ? const Icon(Icons.smart_toy, size: 20)
              : Text(initial,
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: theme.colorScheme.onPrimaryContainer,
                  )),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Flexible(
                    child: Text(
                      name,
                      style: theme.textTheme.titleSmall,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (_isConnectBuddy) ...[
                    const SizedBox(width: 4),
                    Icon(
                      Icons.verified,
                      size: 16,
                      color: ext?.connectBuddyBadgeColor ??
                          theme.colorScheme.primary,
                    ),
                  ],
                ],
              ),
              Text(
                _formatTime(post.createdAt),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _formatTime(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${dt.day}/${dt.month}/${dt.year}';
  }
}
