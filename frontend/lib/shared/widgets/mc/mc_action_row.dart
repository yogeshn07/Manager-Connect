import 'package:flutter/material.dart';
import 'package:manager_connect/shared/widgets/mc/mc_colors.dart';
import 'package:manager_connect/shared/widgets/mc/mc_spacing.dart';
import 'package:manager_connect/shared/widgets/mc/mc_typography.dart';

/// Action Row — 4-button engagement row (React, Comment, Repost, Share).
/// Border-top divider. Each item flex:1 with left-border dividers.
class McActionRow extends StatelessWidget {
  const McActionRow({
    this.onReact,
    this.onComment,
    this.onRepost,
    this.onShare,
    this.reacted = false,
    super.key,
  });

  final VoidCallback? onReact;
  final VoidCallback? onComment;
  final VoidCallback? onRepost;
  final VoidCallback? onShare;
  final bool reacted;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: McColors.borderDefault, width: McSpacing.borderThin),
        ),
      ),
      child: Row(
        children: [
          _item(Icons.thumb_up_outlined, 'React', onReact,
              active: reacted, isFirst: true),
          _item(Icons.chat_bubble_outline, 'Comment', onComment),
          _item(Icons.repeat, 'Repost', onRepost),
          _item(Icons.send_outlined, 'Share', onShare),
        ],
      ),
    );
  }

  Widget _item(IconData icon, String label, VoidCallback? onTap,
      {bool active = false, bool isFirst = false}) {
    final color = active ? McColors.brand700 : McColors.textSecondary;
    return Expanded(
      child: Container(
        decoration: isFirst
            ? null
            : BoxDecoration(
                border: Border(
                  left: BorderSide(
                      color: McColors.borderDefault, width: McSpacing.borderThin),
                ),
              ),
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 14, color: color),
                const SizedBox(width: 4),
                Text(label, style: McTypography.actionRow.copyWith(color: color)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
