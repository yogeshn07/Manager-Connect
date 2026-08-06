import 'package:flutter/material.dart';
import 'package:manager_connect/shared/widgets/mc/mc_colors.dart';
import 'package:manager_connect/shared/widgets/mc/mc_spacing.dart';

/// Animated shimmer skeleton for loading states.
class MCShimmer extends StatefulWidget {
  const MCShimmer({required this.child, super.key});

  final Widget child;

  @override
  State<MCShimmer> createState() => _MCShimmerState();
}

class _MCShimmerState extends State<MCShimmer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
    _anim = Tween<double>(begin: -1, end: 2).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOutSine),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (context, child) {
        return ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (bounds) => LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: const [
              Color(0xFFE5E7EB),
              Color(0xFFF3F4F6),
              Color(0xFFE5E7EB),
            ],
            stops: [
              (_anim.value - 0.3).clamp(0.0, 1.0),
              _anim.value.clamp(0.0, 1.0),
              (_anim.value + 0.3).clamp(0.0, 1.0),
            ],
          ).createShader(bounds),
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

/// Shimmer placeholder box — use inside MCShimmer.
class MCShimmerBox extends StatelessWidget {
  const MCShimmerBox({
    this.width,
    this.height = 14,
    this.radius,
    this.color,
    super.key,
  });

  final double? width;
  final double height;
  final double? radius;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width ?? double.infinity,
      height: height,
      decoration: BoxDecoration(
        color: color ?? const Color(0xFFE5E7EB),
        borderRadius:
            BorderRadius.circular(radius ?? MCSpacing.radiusXs),
      ),
    );
  }
}

/// Shimmer placeholder circle — avatars, icons.
class MCShimmerCircle extends StatelessWidget {
  const MCShimmerCircle({this.size = 44, super.key});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: Color(0xFFE5E7EB),
      ),
    );
  }
}

/// Full feed-card skeleton.
class MCFeedCardSkeleton extends StatelessWidget {
  const MCFeedCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return MCShimmer(
      child: Container(
        margin: const EdgeInsets.symmetric(
            horizontal: MCSpacing.pageH, vertical: 6),
        padding: const EdgeInsets.all(MCSpacing.cardPadH),
        decoration: BoxDecoration(
          color: MCColors.card,
          borderRadius: BorderRadius.circular(MCSpacing.radiusMd),
          border: Border.all(color: MCColors.border),
        ),
        child: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                MCShimmerCircle(size: 40),
                SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      MCShimmerBox(width: 140, height: 13),
                      SizedBox(height: 5),
                      MCShimmerBox(width: 80, height: 11),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 14),
            MCShimmerBox(height: 13),
            SizedBox(height: 6),
            MCShimmerBox(height: 13),
            SizedBox(height: 6),
            MCShimmerBox(width: 200, height: 13),
            SizedBox(height: 16),
            Row(
              children: [
                MCShimmerBox(width: 56, height: 28, radius: 999),
                SizedBox(width: 8),
                MCShimmerBox(width: 56, height: 28, radius: 999),
                SizedBox(width: 8),
                MCShimmerBox(width: 56, height: 28, radius: 999),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Profile header skeleton.
class MCProfileSkeleton extends StatelessWidget {
  const MCProfileSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return const MCShimmer(
      child: Padding(
        padding: EdgeInsets.all(MCSpacing.pageH),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            MCShimmerCircle(size: 88),
            SizedBox(height: 14),
            MCShimmerBox(width: 160, height: 18),
            SizedBox(height: 8),
            MCShimmerBox(width: 120, height: 13),
            SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                MCShimmerBox(width: 72, height: 36, radius: 12),
                SizedBox(width: 12),
                MCShimmerBox(width: 72, height: 36, radius: 12),
                SizedBox(width: 12),
                MCShimmerBox(width: 72, height: 36, radius: 12),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
