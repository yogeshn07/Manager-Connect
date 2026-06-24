import 'package:flutter/material.dart';
import 'package:manager_connect/shared/widgets/mc/mc_colors.dart';
import 'package:manager_connect/shared/widgets/mc/mc_typography.dart';

/// Engagement Cluster — stacked reaction circles + count.
/// 3 circles: 20-22px, overlap -4px, 2px white border.
class McEngagementCluster extends StatelessWidget {
  const McEngagementCluster({
    required this.count,
    this.commentCount = 0,
    this.repostCount = 0,
    super.key,
  });

  final int count;
  final int commentCount;
  final int repostCount;

  @override
  Widget build(BuildContext context) {
    if (count == 0 && commentCount == 0 && repostCount == 0) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      child: Row(
        children: [
          if (count > 0) ...[
            _reactionCircles(),
            const SizedBox(width: 5),
            Text(
              '$count',
              style: McTypography.bodySm.copyWith(
                fontWeight: FontWeight.w500,
                color: McColors.textPrimary,
              ),
            ),
          ],
          const Spacer(),
          if (commentCount > 0)
            Text(
              '$commentCount comments',
              style: McTypography.caption.copyWith(color: McColors.textTertiary),
            ),
          if (commentCount > 0 && repostCount > 0)
            Text(
              '  ·  ',
              style: McTypography.caption.copyWith(color: McColors.textTertiary),
            ),
          if (repostCount > 0)
            Text(
              '$repostCount reposts',
              style: McTypography.caption.copyWith(color: McColors.textTertiary),
            ),
        ],
      ),
    );
  }

  Widget _reactionCircles() {
    final types = [
      (McColors.brand50, McColors.brand700, Icons.auto_awesome),
      (McColors.amber50, McColors.amber400, Icons.emoji_events_outlined),
      (McColors.coral50, McColors.coral600, Icons.local_fire_department),
    ];

    final showCount = count > 0 ? (count >= 3 ? 3 : count.clamp(1, 3)) : 0;

    return SizedBox(
      width: 22.0 + (showCount - 1) * 17,
      height: 22,
      child: Stack(
        children: List.generate(showCount, (i) {
          return Positioned(
            left: i * 17.0,
            child: Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: types[i].$1,
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: Center(
                child: Icon(types[i].$3, size: 11, color: types[i].$2),
              ),
            ),
          );
        }),
      ),
    );
  }
}
