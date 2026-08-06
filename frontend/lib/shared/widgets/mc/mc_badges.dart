import 'package:flutter/material.dart';
import 'package:manager_connect/shared/widgets/mc/mc_colors.dart';
import 'package:manager_connect/shared/widgets/mc/mc_spacing.dart';
import 'package:manager_connect/shared/widgets/mc/mc_typography.dart';

/// Status pill / chip — semantic colors.
class MCStatusPill extends StatelessWidget {
  const MCStatusPill({
    required this.label,
    this.color,
    this.bgColor,
    this.icon,
    this.small = false,
    super.key,
  });

  final String label;
  final Color? color;
  final Color? bgColor;
  final IconData? icon;
  final bool small;

  factory MCStatusPill.success(String label) => MCStatusPill(
        label: label,
        color: MCColors.success,
        bgColor: MCColors.successBg,
        icon: Icons.check_circle_outline,
      );

  factory MCStatusPill.error(String label) => MCStatusPill(
        label: label,
        color: MCColors.error,
        bgColor: MCColors.errorBg,
        icon: Icons.error_outline,
      );

  factory MCStatusPill.warning(String label) => MCStatusPill(
        label: label,
        color: MCColors.warning,
        bgColor: MCColors.warningBg,
      );

  factory MCStatusPill.info(String label) => MCStatusPill(
        label: label,
        color: MCColors.info,
        bgColor: MCColors.infoBg,
      );

  factory MCStatusPill.amber(String label) => MCStatusPill(
        label: label,
        color: MCColors.amberDark,
        bgColor: MCColors.amberLight,
      );

  factory MCStatusPill.violet(String label) => MCStatusPill(
        label: label,
        color: MCColors.violet,
        bgColor: MCColors.violetLight,
      );

  @override
  Widget build(BuildContext context) {
    final c  = color  ?? MCColors.primaryMid;
    final bg = bgColor ?? MCColors.primaryPale;
    final pad = small
        ? const EdgeInsets.symmetric(horizontal: 8, vertical: 3)
        : const EdgeInsets.symmetric(horizontal: 10, vertical: 4);

    return Container(
      padding: pad,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(MCSpacing.radiusPill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: c),
            const SizedBox(width: 4),
          ],
          Text(
            label.toUpperCase(),
            style: MCTypography.overline.copyWith(color: c),
          ),
        ],
      ),
    );
  }
}

/// Filter / category chip (pill, active = navy fill).
class MCFilterChip extends StatelessWidget {
  const MCFilterChip({
    required this.label,
    this.active = false,
    this.onTap,
    super.key,
  });

  final String label;
  final bool active;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: active ? MCColors.primary : MCColors.card,
          borderRadius: BorderRadius.circular(MCSpacing.radiusPill),
          border: Border.all(
            color: active ? MCColors.primary : MCColors.border,
            width: MCSpacing.borderThin,
          ),
        ),
        child: Text(
          label,
          style: MCTypography.labelSm.copyWith(
            color: active ? Colors.white : MCColors.textSecondary,
          ),
        ),
      ),
    );
  }
}

/// Notification / unread badge dot.
class MCBadgeDot extends StatelessWidget {
  const MCBadgeDot({
    this.count = 0,
    this.color = MCColors.energyRed,
    super.key,
  });

  final int count;
  final Color color;

  @override
  Widget build(BuildContext context) {
    if (count <= 0) return const SizedBox.shrink();
    return Container(
      constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
      padding: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(MCSpacing.radiusPill),
        border: Border.all(color: Colors.white, width: 1.5),
      ),
      child: Center(
        child: Text(
          count > 99 ? '99+' : '$count',
          style: MCTypography.overline.copyWith(color: Colors.white),
        ),
      ),
    );
  }
}
