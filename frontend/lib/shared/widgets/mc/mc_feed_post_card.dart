import 'package:flutter/material.dart';
import 'package:manager_connect/shared/widgets/mc/mc_action_row.dart';
import 'package:manager_connect/shared/widgets/mc/mc_avatar.dart';
import 'package:manager_connect/shared/widgets/mc/mc_colors.dart';
import 'package:manager_connect/shared/widgets/mc/mc_engagement_cluster.dart';
import 'package:manager_connect/shared/widgets/mc/mc_spacing.dart';
import 'package:manager_connect/shared/widgets/mc/mc_type_pill.dart';
import 'package:manager_connect/shared/widgets/mc/mc_typography.dart';

/// Feed Post Card — core content unit.
/// White bg, 0.5px border, 14-16px radius, overflow hidden.
/// Shared: author row, body, engagement cluster, action row.
class McFeedPostCard extends StatelessWidget {
  const McFeedPostCard({
    required this.authorName,
    required this.authorInitials,
    required this.authorRole,
    required this.timestamp,
    required this.body,
    this.avatarColor,
    this.typePill,
    this.typePillFill,
    this.typePillText,
    this.bannerColor,
    this.bannerIcon,
    this.bannerLabel,
    this.isConnectBuddy = false,
    this.isPinned = false,
    this.reactionCount = 0,
    this.commentCount = 0,
    this.repostCount = 0,
    this.onTap,
    this.onReact,
    this.onComment,
    this.child,
    super.key,
  });

  final String authorName;
  final String authorInitials;
  final String authorRole;
  final String timestamp;
  final String body;
  final Color? avatarColor;
  final String? typePill;
  final Color? typePillFill;
  final Color? typePillText;
  final Color? bannerColor;
  final IconData? bannerIcon;
  final String? bannerLabel;
  final bool isConnectBuddy;
  final bool isPinned;
  final int reactionCount;
  final int commentCount;
  final int repostCount;
  final VoidCallback? onTap;
  final VoidCallback? onReact;
  final VoidCallback? onComment;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: EdgeInsets.fromLTRB(
          McSpacing.pageMargin, 0, McSpacing.pageMargin, McSpacing.cardGap,
        ),
        decoration: BoxDecoration(
          color: McColors.bgCard,
          borderRadius: BorderRadius.circular(McSpacing.radiusCard),
          border: Border.all(
            color: isPinned ? McColors.amberBorder : McColors.borderDefault,
            width: isPinned ? McSpacing.borderAccent : McSpacing.borderThin,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (bannerColor != null) _banner(),
            Padding(
              padding: const EdgeInsets.fromLTRB(13, 12, 13, 0),
              child: _authorRow(),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(13, 8, 13, 0),
              child: Text(body, style: McTypography.bodyLg),
            ),
            if (child != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(13, 8, 13, 0),
                child: child,
              ),
            McEngagementCluster(
              count: reactionCount,
              commentCount: commentCount,
              repostCount: repostCount,
            ),
            McActionRow(
              onReact: onReact,
              onComment: onComment,
            ),
          ],
        ),
      ),
    );
  }

  Widget _banner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      color: bannerColor,
      child: Row(
        children: [
          if (bannerIcon != null)
            Icon(bannerIcon, size: 16, color: McColors.amber100),
          if (bannerIcon != null) const SizedBox(width: 6),
          if (bannerLabel != null)
            Text(
              bannerLabel!.toUpperCase(),
              style: McTypography.label.copyWith(
                color: Colors.white.withValues(alpha: 0.85),
                letterSpacing: 0.8,
              ),
            ),
        ],
      ),
    );
  }

  Widget _authorRow() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        McAvatar(
          initials: authorInitials,
          size: 38,
          backgroundColor: avatarColor ?? McColors.brand800,
          badgeIcon: isConnectBuddy ? Icons.verified : null,
          badgeColor: isConnectBuddy ? McColors.brand700 : null,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Flexible(
                    child: Text(
                      authorName,
                      style: McTypography.h4,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (typePill != null) ...[
                    const SizedBox(width: 6),
                    McTypePill(
                      text: typePill!,
                      fillColor: typePillFill ?? McColors.brand50,
                      textColor: typePillText ?? McColors.brand800,
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 1),
              Text(
                authorRole,
                style: McTypography.caption,
              ),
              Text(
                timestamp,
                style: McTypography.caption.copyWith(fontSize: 9),
              ),
            ],
          ),
        ),
        Icon(Icons.more_horiz, size: 18, color: McColors.textTertiary),
      ],
    );
  }
}
