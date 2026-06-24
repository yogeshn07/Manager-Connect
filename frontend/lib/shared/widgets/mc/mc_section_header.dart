import 'package:flutter/material.dart';
import 'package:manager_connect/shared/widgets/mc/mc_colors.dart';
import 'package:manager_connect/shared/widgets/mc/mc_spacing.dart';
import 'package:manager_connect/shared/widgets/mc/mc_typography.dart';

/// Section Header — module-level content groupings.
/// Icon 12px + label 11px/500 uppercase + right action link.
class McSectionHeader extends StatelessWidget {
  const McSectionHeader({
    required this.label,
    this.icon,
    this.iconColor,
    this.rightLabel,
    this.onRightTap,
    super.key,
  });

  final String label;
  final IconData? icon;
  final Color? iconColor;
  final String? rightLabel;
  final VoidCallback? onRightTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        McSpacing.cardPadH, McSpacing.sectionGap, McSpacing.cardPadH, 6,
      ),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: iconColor ?? McColors.textSecondary),
            const SizedBox(width: 5),
          ],
          Text(
            label.toUpperCase(),
            style: McTypography.label,
          ),
          const Spacer(),
          if (rightLabel != null)
            GestureDetector(
              onTap: onRightTap,
              child: Text(
                rightLabel!,
                style: McTypography.bodySm.copyWith(
                  fontWeight: FontWeight.w500,
                  color: McColors.textLink,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
