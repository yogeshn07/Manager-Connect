import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:manager_connect/core/constants/route_names.dart';
import 'package:manager_connect/core/errors/app_exception.dart';
import 'package:manager_connect/features/auth/data/repositories/auth_repository.dart';
import 'package:manager_connect/shared/providers/supabase_provider.dart';
import 'package:manager_connect/shared/widgets/mc/mc_buttons.dart';
import 'package:manager_connect/shared/widgets/mc/mc_colors.dart';
import 'package:manager_connect/shared/widgets/mc/mc_grid_identity.dart';
import 'package:manager_connect/shared/widgets/mc/mc_inputs.dart';
import 'package:manager_connect/shared/widgets/mc/mc_spacing.dart';
import 'package:manager_connect/shared/widgets/mc/mc_typography.dart';
import 'package:manager_connect/shared/widgets/toast.dart';

class WelcomeScreen extends ConsumerStatefulWidget {
  const WelcomeScreen({super.key});

  @override
  ConsumerState<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends ConsumerState<WelcomeScreen> {
  final _emailController = TextEditingController();
  bool _sendingOtp = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _sendOtp() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      showErrorToast(context, 'Please enter your email');
      return;
    }
    setState(() => _sendingOtp = true);
    try {
      final client = ref.read(supabaseClientProvider);
      final repo = AuthRepository(client);
      await repo.sendOtp(email: email);
      if (mounted) {
        unawaited(context.push(RouteNames.verifyOtp, extra: email));
      }
    } on AppException catch (e) {
      if (mounted) showErrorToast(context, e.message);
    } catch (_) {
      if (mounted) showErrorToast(context, 'Failed to send OTP');
    } finally {
      if (mounted) setState(() => _sendingOtp = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenH = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: MCColors.background,
      body: Column(
        children: [
          // ── Hero navy panel ────────────────────────────────────────
          Container(
            height: screenH * 0.38,
            width: double.infinity,
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
                const MCGridOverlay(),
                SafeArea(
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _CompactLogo(),
                        const SizedBox(height: 20),
                        Text('The Catalysts', style: MCTypography.displayMd),
                        const SizedBox(height: 6),
                        Text('Built for leaders', style: MCTypography.taglineDark),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 3,
                              height: 3,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: MCColors.energyRed,
                              ),
                            ),
                            const SizedBox(width: 5),
                            Text(
                              'GI LEADERS NETWORK',
                              style: MCTypography.taglineDark.copyWith(
                                fontSize: 9,
                                letterSpacing: 1.5,
                                color: Colors.white.withValues(alpha: 0.38),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── White bottom sheet ────────────────────────────────────
          Expanded(
            child: Container(
              decoration: const BoxDecoration(
                color: MCColors.card,
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(MCSpacing.radiusXl),
                ),
              ),
              margin: const EdgeInsets.only(top: -24),
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(
                  MCSpacing.pageH, MCSpacing.xl, MCSpacing.pageH, MCSpacing.xl4,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Drag handle
                    Center(
                      child: Container(
                        width: 36,
                        height: 4,
                        margin: const EdgeInsets.only(bottom: 24),
                        decoration: BoxDecoration(
                          color: MCColors.border,
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                    ),

                    Text('Sign in', style: MCTypography.h1),
                    const SizedBox(height: 4),
                    Text(
                      'Your private manager community',
                      style: MCTypography.body.copyWith(color: MCColors.textSecondary),
                    ),
                    const SizedBox(height: MCSpacing.xl),

                    // Email
                    MCInput(
                      controller: _emailController,
                      hint: 'Enter your email address',
                      label: 'Work Email',
                      prefixIcon: Icons.email_outlined,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.done,
                      enabled: !_sendingOtp,
                      onSubmitted: (_) => _sendOtp(),
                    ),
                    const SizedBox(height: 20),

                    // CTA
                    MCPrimaryButton(
                      label: 'Continue with Email',
                      loading: _sendingOtp,
                      icon: Icons.arrow_forward,
                      onPressed: _sendOtp,
                    ),
                    const SizedBox(height: 12),

                    // Microsoft SSO ghost
                    MCGhostButton(
                      label: 'Continue with Microsoft',
                      icon: Icons.corporate_fare,
                      onPressed: () {},
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CompactLogo extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 72,
      height: 72,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withValues(alpha: 0.18), width: 1.5),
      ),
      child: CustomPaint(painter: _MiniLogoPainter()),
    );
  }
}

class _MiniLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;

    final mPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 2.8
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    final mPath = Path()
      ..moveTo(cx - 16, cy + 10)
      ..lineTo(cx - 16, cy - 10)
      ..lineTo(cx,      cy + 6)
      ..lineTo(cx + 16, cy - 10)
      ..lineTo(cx + 16, cy + 10);
    canvas.drawPath(mPath, mPaint);

    final cPaint = Paint()
      ..color = MCColors.amber
      ..strokeWidth = 2.8
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final rect = Rect.fromCenter(center: Offset(cx, cy), width: 22, height: 22);
    canvas.drawArc(rect, 0.5, 4.8, false, cPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
