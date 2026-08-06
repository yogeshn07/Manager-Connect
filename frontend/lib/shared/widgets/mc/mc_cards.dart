import 'package:flutter/material.dart';
import 'package:manager_connect/shared/widgets/mc/mc_colors.dart';
import 'package:manager_connect/shared/widgets/mc/mc_spacing.dart';

/// Standard white card — radius 16, 1px border, shadow-sm.
class MCCard extends StatelessWidget {
  const MCCard({
    required this.child,
    this.padding,
    this.radius,
    this.color,
    this.borderColor,
    this.shadow = true,
    this.onTap,
    super.key,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final double? radius;
  final Color? color;
  final Color? borderColor;
  final bool shadow;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final r = radius ?? MCSpacing.radiusMd;
    Widget card = Container(
      padding: padding ?? const EdgeInsets.all(MCSpacing.cardPadH),
      decoration: BoxDecoration(
        color: color ?? MCColors.card,
        borderRadius: BorderRadius.circular(r),
        border: Border.all(
          color: borderColor ?? MCColors.border,
          width: MCSpacing.borderThin,
        ),
        boxShadow: shadow ? MCColors.cardShadow : null,
      ),
      child: child,
    );

    if (onTap != null) {
      return GestureDetector(
        onTap: onTap,
        child: card,
      );
    }
    return card;
  }
}

/// Announcement card — colored 4px left border, category tag + footer.
class MCAnnouncementCard extends StatelessWidget {
  const MCAnnouncementCard({
    required this.title,
    required this.body,
    required this.category,
    this.accentColor = MCColors.primary,
    this.onReadMore,
    super.key,
  });

  final String title;
  final String body;
  final String category;
  final Color accentColor;
  final VoidCallback? onReadMore;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: MCColors.card,
        borderRadius: BorderRadius.circular(MCSpacing.radiusMd),
        border: Border.all(color: MCColors.border, width: MCSpacing.borderThin),
        boxShadow: MCColors.cardShadow,
      ),
      clipBehavior: Clip.antiAlias,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(width: 4, color: accentColor),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(MCSpacing.cardPadH),
                child: child,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget get child => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(category),
          const SizedBox(height: 4),
          Text(title),
          const SizedBox(height: 4),
          Text(body),
          if (onReadMore != null) ...[
            const SizedBox(height: 8),
            GestureDetector(
              onTap: onReadMore,
              child: const Text('Read more'),
            ),
          ],
        ],
      );
}

/// Recognition card — amber shimmer top strip.
class MCRecognitionCardShimmer extends StatelessWidget {
  const MCRecognitionCardShimmer({required this.child, super.key});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: MCColors.card,
        borderRadius: BorderRadius.circular(MCSpacing.radiusLg),
        border: Border.all(color: MCColors.border, width: MCSpacing.borderThin),
        boxShadow: MCColors.cardShadow,
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            height: 6,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFFFFB840), Color(0xFFFCD34D), Color(0xFFFFB840)],
                stops: [0.0, 0.5, 1.0],
              ),
            ),
          ),
          child,
        ],
      ),
    );
  }
}

/// Poll card — 4px violet left border.
class MCPollCard extends StatelessWidget {
  const MCPollCard({required this.child, super.key});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: MCColors.card,
        borderRadius: BorderRadius.circular(MCSpacing.radiusMd),
        border: Border.all(color: MCColors.border, width: MCSpacing.borderThin),
        boxShadow: MCColors.cardShadow,
      ),
      clipBehavior: Clip.antiAlias,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(width: 4, color: MCColors.violet),
            Expanded(child: child),
          ],
        ),
      ),
    );
  }
}
