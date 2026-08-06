import 'package:flutter/material.dart';
import 'package:manager_connect/shared/widgets/mc/mc_buttons.dart';
import 'package:manager_connect/shared/widgets/mc/mc_colors.dart';
import 'package:manager_connect/shared/widgets/mc/mc_spacing.dart';
import 'package:manager_connect/shared/widgets/mc/mc_typography.dart';

class ErrorState extends StatelessWidget {
  const ErrorState({
    required this.message,
    this.onRetry,
    super.key,
  });

  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(MCSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: MCColors.errorBg,
                borderRadius: BorderRadius.circular(MCSpacing.radiusMd),
              ),
              child: const Icon(
                Icons.error_outline_rounded,
                size: 32,
                color: MCColors.error,
              ),
            ),
            const SizedBox(height: MCSpacing.md),
            Text(
              'Something went wrong',
              style: MCTypography.h4,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              message,
              style: MCTypography.caption,
              textAlign: TextAlign.center,
            ),
            if (onRetry != null) ...[
              const SizedBox(height: MCSpacing.lg),
              MCGhostButton(
                label: 'Try Again',
                icon: Icons.refresh,
                onPressed: onRetry,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
