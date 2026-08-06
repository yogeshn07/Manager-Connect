import 'package:flutter/material.dart';
import 'package:manager_connect/shared/widgets/mc/mc_colors.dart';
import 'package:manager_connect/shared/widgets/mc/mc_spacing.dart';
import 'package:manager_connect/shared/widgets/mc/mc_typography.dart';

/// Primary CTA — navy gradient, 52–56px, radius 12–16.
class MCPrimaryButton extends StatelessWidget {
  const MCPrimaryButton({
    required this.label,
    this.onPressed,
    this.loading = false,
    this.icon,
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool loading;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final disabled = onPressed == null || loading;
    return GestureDetector(
      onTap: disabled ? null : onPressed,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        height: 54,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(MCSpacing.radiusButton),
          gradient: disabled
              ? null
              : const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: MCColors.primaryButtonGradient,
                ),
          color: disabled ? const Color(0xFFCBD5E1) : null,
          boxShadow: disabled ? null : MCColors.primaryButtonShadow,
        ),
        child: Center(
          child: loading
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    valueColor: AlwaysStoppedAnimation(Colors.white),
                  ),
                )
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (icon != null) ...[
                      Icon(icon, size: 18, color: Colors.white),
                      const SizedBox(width: 8),
                    ],
                    Text(
                      label,
                      style: MCTypography.labelLg.copyWith(color: Colors.white),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

/// Amber recognition CTA.
class MCAmberButton extends StatelessWidget {
  const MCAmberButton({
    required this.label,
    this.onPressed,
    this.loading = false,
    this.icon,
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool loading;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final disabled = onPressed == null || loading;
    return GestureDetector(
      onTap: disabled ? null : onPressed,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        height: 54,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(MCSpacing.radiusButton),
          gradient: disabled
              ? null
              : const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: MCColors.amberButtonGradient,
                ),
          color: disabled ? const Color(0xFFCBD5E1) : null,
          boxShadow: disabled ? null : MCColors.amberButtonShadow,
        ),
        child: Center(
          child: loading
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    valueColor: AlwaysStoppedAnimation(Colors.white),
                  ),
                )
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (icon != null) ...[
                      Icon(icon, size: 18, color: MCColors.textPrimary),
                      const SizedBox(width: 8),
                    ],
                    Text(
                      label,
                      style: MCTypography.labelLg.copyWith(color: MCColors.textPrimary),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

/// Ghost / secondary — white bg, 1.5px border.
class MCGhostButton extends StatelessWidget {
  const MCGhostButton({
    required this.label,
    this.onPressed,
    this.loading = false,
    this.icon,
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool loading;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final disabled = onPressed == null || loading;
    return GestureDetector(
      onTap: disabled ? null : onPressed,
      child: Container(
        height: 54,
        decoration: BoxDecoration(
          color: MCColors.card,
          borderRadius: BorderRadius.circular(MCSpacing.radiusButton),
          border: Border.all(
            color: disabled ? MCColors.border : const Color(0xFFDDE3EC),
            width: MCSpacing.borderMed,
          ),
        ),
        child: Center(
          child: loading
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2.5),
                )
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (icon != null) ...[
                      Icon(icon, size: 18, color: MCColors.textSecondary),
                      const SizedBox(width: 8),
                    ],
                    Text(label, style: MCTypography.labelLg),
                  ],
                ),
        ),
      ),
    );
  }
}

/// Pill button — compact, radius 999 (post / publish / follow).
class MCPillButton extends StatelessWidget {
  const MCPillButton({
    required this.label,
    this.onPressed,
    this.loading = false,
    this.primary = true,
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool loading;
  final bool primary;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: (onPressed == null || loading) ? null : onPressed,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
        decoration: BoxDecoration(
          color: primary ? MCColors.primaryMid : MCColors.primaryPale,
          borderRadius: BorderRadius.circular(MCSpacing.radiusPill),
        ),
        child: loading
            ? SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation(
                    primary ? Colors.white : MCColors.primaryMid,
                  ),
                ),
              )
            : Text(
                label,
                style: MCTypography.labelSm.copyWith(
                  color: primary ? Colors.white : MCColors.primaryMid,
                ),
              ),
      ),
    );
  }
}

/// Icon-only circle button (36–44px).
class MCIconButton extends StatelessWidget {
  const MCIconButton({
    required this.icon,
    this.onTap,
    this.size = 40,
    this.color,
    this.bgColor,
    super.key,
  });

  final IconData icon;
  final VoidCallback? onTap;
  final double size;
  final Color? color;
  final Color? bgColor;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: bgColor ?? MCColors.primaryPale,
        ),
        child: Icon(icon, size: size * 0.5, color: color ?? MCColors.textSecondary),
      ),
    );
  }
}
