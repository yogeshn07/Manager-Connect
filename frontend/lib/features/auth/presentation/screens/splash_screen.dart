import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manager_connect/features/auth/presentation/providers/auth_notifier.dart';
import 'package:manager_connect/shared/providers/splash_timer_provider.dart';
import 'package:manager_connect/shared/widgets/mc/mc_colors.dart';
import 'package:manager_connect/shared/widgets/mc/mc_grid_identity.dart';
import 'package:manager_connect/shared/widgets/mc/mc_typography.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _progress;
  late final Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    );
    _progress = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.1, 0.9, curve: Curves.easeInOut)),
    );
    _fade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.0, 0.5, curve: Curves.easeOut)),
    );
    _controller.forward();
    // Auth init and minimum-splash timer run concurrently.
    // Router gates navigation until both resolve (see router_provider.dart).
    Future.microtask(() => ref.read(authProvider.notifier).initialize());
    Future.delayed(const Duration(milliseconds: 2800), () {
      if (mounted) ref.read(splashTimerProvider.notifier).elapsed();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: MCColors.splashGradient,
          ),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Subtle grid topology — static, zero-cost after first paint
            const MCGridOverlay(),
            SafeArea(
              child: FadeTransition(
                opacity: _fade,
                child: Column(
              children: [
                const Spacer(flex: 3),
                // ── Logomark ──────────────────────────────────────────
                _Logomark(),
                const SizedBox(height: 28),
                // ── Wordmark ──────────────────────────────────────────
                Text('The Catalysts', style: MCTypography.displayLg),
                const SizedBox(height: 8),
                Text(
                  'BUILT FOR LEADERS',
                  style: MCTypography.taglineDark,
                ),
                const SizedBox(height: 10),
                // ── Contextual identity ───────────────────────────────
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 4,
                      height: 4,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: MCColors.energyRed,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'GI LEADERS NETWORK',
                      style: MCTypography.taglineDark.copyWith(
                        fontSize: 10,
                        letterSpacing: 1.6,
                        color: Colors.white.withValues(alpha: 0.40),
                      ),
                    ),
                  ],
                ),
                const Spacer(flex: 3),
                // ── Progress bar ──────────────────────────────────────
                AnimatedBuilder(
                  animation: _progress,
                  builder: (context, _) => _ProgressBar(value: _progress.value),
                ),
                const SizedBox(height: 16),
                Text('v1.0.0', style: MCTypography.hint),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
          ],
        ),
      ),
    );
  }
}

class _Logomark extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 96,
      height: 96,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.white.withValues(alpha: 0.18), width: 1.5),
      ),
      child: CustomPaint(painter: _LogomarkPainter()),
    );
  }
}

class _LogomarkPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;

    final mPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 3.2
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    // M shape
    final mPath = Path()
      ..moveTo(cx - 22, cy + 14)
      ..lineTo(cx - 22, cy - 14)
      ..lineTo(cx,      cy + 8)
      ..lineTo(cx + 22, cy - 14)
      ..lineTo(cx + 22, cy + 14);
    canvas.drawPath(mPath, mPaint);

    // C arc in amber
    final cPaint = Paint()
      ..color = MCColors.amber
      ..strokeWidth = 3.2
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final rect = Rect.fromCenter(center: Offset(cx, cy), width: 28, height: 28);
    canvas.drawArc(rect, 0.5, 4.8, false, cPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _ProgressBar extends StatelessWidget {
  const _ProgressBar({required this.value});
  final double value;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 200,
      height: 3,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(999),
      ),
      clipBehavior: Clip.antiAlias,
      child: FractionallySizedBox(
        widthFactor: value,
        alignment: Alignment.centerLeft,
        child: Container(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [MCColors.amber, Color(0xFFFCD34D)],
            ),
            borderRadius: BorderRadius.circular(999),
            boxShadow: [
              BoxShadow(
                color: MCColors.amber.withValues(alpha: 0.5),
                blurRadius: 6,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
