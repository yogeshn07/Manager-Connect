import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:manager_connect/core/constants/route_names.dart';
import 'package:manager_connect/features/auth/presentation/providers/auth_notifier.dart';
import 'package:manager_connect/shared/widgets/mc/mc_colors.dart';
import 'package:manager_connect/shared/widgets/mc/mc_spacing.dart';
import 'package:manager_connect/shared/widgets/mc/mc_typography.dart';

class DailyGateScreen extends ConsumerStatefulWidget {
  const DailyGateScreen({super.key});

  @override
  ConsumerState<DailyGateScreen> createState() => _DailyGateScreenState();
}

class _DailyGateScreenState extends ConsumerState<DailyGateScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    );
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _slide = Tween(begin: const Offset(0, 0.07), end: Offset.zero)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    final firstName = switch (auth) {
      AppAuthStateAuthenticated(:final session) =>
        session.fullName?.split(' ').first ?? 'Manager',
      _ => 'Manager',
    };

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          // ── Network illustration ──────────────────────────────────────
          Expanded(
            flex: 55,
            child: CustomPaint(
              painter: _NetworkPainter(),
              child: const SizedBox.expand(),
            ),
          ),

          // ── Content card ─────────────────────────────────────────────
          Expanded(
            flex: 45,
            child: FadeTransition(
              opacity: _fade,
              child: SlideTransition(
                position: _slide,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(32, 28, 32, 40),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Page dots
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _dot(active: true),
                          const SizedBox(width: 6),
                          _dot(),
                          const SizedBox(width: 6),
                          _dot(),
                        ],
                      ),
                      const SizedBox(height: 24),

                      Text(
                        'Welcome back,\n$firstName! 🎯',
                        style: MCTypography.h2.copyWith(height: 1.22),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),

                      Text(
                        'Come on, let\'s get in and rock today.\nYour leadership community is live.',
                        style: MCTypography.body.copyWith(
                          color: MCColors.textSecondary,
                          height: 1.55,
                        ),
                        textAlign: TextAlign.center,
                      ),

                      const Spacer(),

                      SizedBox(
                        height: 56,
                        child: ElevatedButton.icon(
                          onPressed: () => context.go(RouteNames.feed),
                          icon: const Icon(Icons.arrow_forward_rounded,
                              size: 20),
                          label: const Text('Get In'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: MCColors.primary,
                            foregroundColor: Colors.white,
                            textStyle: MCTypography.labelLg
                                .copyWith(letterSpacing: 0.4),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                  MCSpacing.radiusPill),
                            ),
                            elevation: 0,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _dot({bool active = false}) => AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: active ? 22 : 8,
        height: 8,
        decoration: BoxDecoration(
          color: active ? MCColors.primary : MCColors.border,
          borderRadius: BorderRadius.circular(4),
        ),
      );
}

// ── Network / leadership visualization ───────────────────────────────────────

class _NetworkPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Background: soft radial gradient from light blue to near-white
    canvas.drawRect(
      Rect.fromLTWH(0, 0, w, h),
      Paint()
        ..shader = const RadialGradient(
          colors: [Color(0xFFE6EDFC), Color(0xFFF5F8FF)],
          center: Alignment.center,
          radius: 1.0,
        ).createShader(Rect.fromLTWH(0, 0, w, h)),
    );

    // Center of the illustration
    final cx = w * 0.50;
    final cy = h * 0.50;

    // ── Primary satellite positions (angle in deg from 3-o'clock clockwise) ──
    // angles[], dists[], radii[] must stay the same length
    final angles = [318.0, 32.0, 92.0, 148.0, 198.0, 252.0, 295.0, 355.0];
    final dists  = [0.330, 0.360, 0.385, 0.345, 0.375, 0.345, 0.370, 0.350];
    final radii  = [0.056, 0.048, 0.050, 0.053, 0.048, 0.058, 0.048, 0.042];

    // Pre-compute primary offsets
    final primOff = List<Offset>.generate(angles.length, (i) {
      final rad = angles[i] * math.pi / 180;
      return Offset(
        cx + math.cos(rad) * w * dists[i],
        cy + math.sin(rad) * w * dists[i],
      );
    });

    // ── Secondary satellites: [parentIndex, angleDeg, distFrac, radiusFrac] ──
    final secData = [
      [0, 308.0, 0.570, 0.030],
      [1, 28.0,  0.595, 0.026],
      [2, 95.0,  0.620, 0.026],
      [6, 290.0, 0.590, 0.028],
    ];

    final secOff = secData.map((d) {
      final rad = (d[1] as double) * math.pi / 180;
      return Offset(
        cx + math.cos(rad) * w * (d[2] as double),
        cy + math.sin(rad) * w * (d[2] as double),
      );
    }).toList();

    // ── Draw primary connection lines ─────────────────────────────────────
    final primLine = Paint()
      ..color = const Color(0xFF1A3A6B).withValues(alpha: 0.48)
      ..strokeWidth = w * 0.013
      ..strokeCap = StrokeCap.round;

    for (int i = 0; i < primOff.length; i++) {
      canvas.drawLine(Offset(cx, cy), primOff[i], primLine);
    }

    // ── Draw secondary connection lines ───────────────────────────────────
    final secLine = Paint()
      ..color = const Color(0xFF1A3A6B).withValues(alpha: 0.32)
      ..strokeWidth = w * 0.009
      ..strokeCap = StrokeCap.round;

    for (int i = 0; i < secData.length; i++) {
      final parentIdx = secData[i][0] as int;
      canvas.drawLine(primOff[parentIdx], secOff[i], secLine);
    }

    // ── Amber glow behind center node ─────────────────────────────────────
    for (final entry in [
      (w * 0.30, 0.09),
      (w * 0.20, 0.17),
      (w * 0.13, 0.26),
    ]) {
      canvas.drawCircle(
        Offset(cx, cy),
        entry.$1,
        Paint()
          ..color = const Color(0xFFFFB840).withValues(alpha: entry.$2)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 22),
      );
    }

    // ── Draw primary satellite nodes ──────────────────────────────────────
    final nodePaint = Paint()..color = const Color(0xFF1A3A6B);
    for (int i = 0; i < primOff.length; i++) {
      canvas.drawCircle(primOff[i], w * radii[i], nodePaint);
    }

    // ── Draw secondary satellite nodes ────────────────────────────────────
    for (int i = 0; i < secData.length; i++) {
      canvas.drawCircle(secOff[i], w * (secData[i][3] as double), nodePaint);
    }

    // ── Center node ───────────────────────────────────────────────────────
    // Outer amber ring
    canvas.drawCircle(
      Offset(cx, cy),
      w * 0.124,
      Paint()
        ..color = const Color(0xFFFFB840)
        ..style = PaintingStyle.stroke
        ..strokeWidth = w * 0.017,
    );
    // Dark fill
    canvas.drawCircle(Offset(cx, cy), w * 0.105, nodePaint);
    // Small amber arc inside (partial ring — the MC "C" motif)
    canvas.drawArc(
      Rect.fromCenter(
        center: Offset(cx, cy),
        width: w * 0.090,
        height: w * 0.090,
      ),
      0.45,
      4.90,
      false,
      Paint()
        ..color = const Color(0xFFFFB840)
        ..style = PaintingStyle.stroke
        ..strokeWidth = w * 0.013
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
