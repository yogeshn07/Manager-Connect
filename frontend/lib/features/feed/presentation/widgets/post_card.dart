import 'package:flutter/material.dart';
import 'package:manager_connect/core/constants/app_constants.dart';
import 'package:manager_connect/core/theme/app_colors.dart';
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
    final ext = Theme.of(context).extension<AppThemeExtension>();

    return Card(
      color: _cardColor(ext),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context),
              const SizedBox(height: 12),
              Text(
                post.content,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      height: 1.5,
                      color: AppColors.textPrimary,
                    ),
              ),
              if (post.isPinned) ...[
                const SizedBox(height: 12),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.accentLight,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.push_pin, size: 14, color: AppColors.accent),
                      const SizedBox(width: 4),
                      Text(
                        'Pinned',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.accent,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 8),
              _buildActions(context),
            ],
          ),
        ),
      ),
    );
  }

  Color? _cardColor(AppThemeExtension? ext) {
    if (post.isPinned) return AppColors.pinnedPostBg;
    if (_isConnectBuddy) return AppColors.connectBuddyPostBg;
    return null;
  }

  Widget _buildHeader(BuildContext context) {
    final name = post.author?.fullName ?? 'Unknown';
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: _isConnectBuddy
                ? const LinearGradient(
                    colors: [Color(0xFF7C4DFF), Color(0xFFB388FF)])
                : AppColors.primaryGradient,
          ),
          child: Center(
            child: _isConnectBuddy
                ? const Icon(Icons.smart_toy, size: 24, color: Colors.white)
                : Text(
                    initial,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
          ),
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
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (_isConnectBuddy) ...[
                    const SizedBox(width: 4),
                    Icon(
                      Icons.verified,
                      size: 16,
                      color: AppColors.connectBuddyBadge,
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 2),
              Text(
                _formatTime(post.createdAt),
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textTertiary,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
        Icon(Icons.more_horiz, size: 20, color: AppColors.textTertiary),
      ],
    );
  }

  Widget _buildActions(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _actionButton(Icons.thumb_up_outlined, 'Like'),
        _actionButton(Icons.chat_bubble_outline, 'Comment'),
        _actionButton(Icons.repeat, 'Repost'),
        _actionButton(Icons.send_outlined, 'Send'),
      ],
    );
  }

  Widget _actionButton(IconData icon, String label) {
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: () {},
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: AppColors.textSecondary),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return '${diff.inHours}h';
    if (diff.inDays < 7) return '${diff.inDays}d';
    return '${dt.day}/${dt.month}/${dt.year}';
  }
}
