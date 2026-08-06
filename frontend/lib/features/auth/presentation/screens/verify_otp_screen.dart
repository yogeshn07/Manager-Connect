import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manager_connect/core/constants/app_constants.dart';
import 'package:manager_connect/core/errors/app_exception.dart';
import 'package:manager_connect/features/auth/data/repositories/auth_repository.dart';
import 'package:manager_connect/features/auth/presentation/providers/auth_notifier.dart';
import 'package:manager_connect/shared/providers/supabase_provider.dart';
import 'package:manager_connect/shared/widgets/mc/mc_buttons.dart';
import 'package:manager_connect/shared/widgets/mc/mc_colors.dart';
import 'package:manager_connect/shared/widgets/mc/mc_inputs.dart';
import 'package:manager_connect/shared/widgets/mc/mc_spacing.dart';
import 'package:manager_connect/shared/widgets/mc/mc_typography.dart';
import 'package:manager_connect/shared/widgets/toast.dart';

class VerifyOtpScreen extends ConsumerStatefulWidget {
  const VerifyOtpScreen({required this.email, super.key});
  final String email;

  @override
  ConsumerState<VerifyOtpScreen> createState() => _VerifyOtpScreenState();
}

class _VerifyOtpScreenState extends ConsumerState<VerifyOtpScreen> {
  String _otp = '';
  bool _verifying = false;
  bool _resending = false;
  bool _verified = false;
  int _secondsLeft = 120;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _timer?.cancel();
    _secondsLeft = 120;
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      setState(() {
        if (_secondsLeft > 0) {
          _secondsLeft--;
        } else {
          t.cancel();
        }
      });
    });
  }

  Future<void> _verifyOtp() async {
    if (_otp.length != AppConstants.otpDigitCount) {
      showErrorToast(context, 'Please enter the full ${AppConstants.otpDigitCount}-digit code');
      return;
    }
    setState(() => _verifying = true);
    try {
      final client = ref.read(supabaseClientProvider);
      final repo = AuthRepository(client);
      await repo.verifyOtp(email: widget.email, otp: _otp);
      setState(() => _verified = true);
      await Future.delayed(const Duration(milliseconds: 600));
      await ref.read(authProvider.notifier).handleSignIn();
    } on AppException catch (e) {
      if (mounted) showErrorToast(context, e.message);
    } catch (_) {
      if (mounted) showErrorToast(context, 'Verification failed');
    } finally {
      if (mounted) setState(() => _verifying = false);
    }
  }

  Future<void> _resendOtp() async {
    setState(() => _resending = true);
    try {
      final client = ref.read(supabaseClientProvider);
      final repo = AuthRepository(client);
      await repo.sendOtp(email: widget.email);
      if (mounted) {
        showSuccessToast(context, 'New code sent to ${widget.email}');
        _startTimer();
      }
    } on AppException catch (e) {
      if (mounted) showErrorToast(context, e.message);
    } catch (_) {
      if (mounted) showErrorToast(context, 'Failed to resend code');
    } finally {
      if (mounted) setState(() => _resending = false);
    }
  }

  String get _timerLabel {
    final m = _secondsLeft ~/ 60;
    final s = _secondsLeft % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  bool get _timerExpired => _secondsLeft == 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MCColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // ── Back button header ────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios, size: 18),
                    onPressed: () => Navigator.of(context).pop(),
                    color: MCColors.textPrimary,
                  ),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(
                  MCSpacing.pageH, MCSpacing.sm, MCSpacing.pageH, MCSpacing.xl4,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // ── Shield icon ────────────────────────────────
                    Center(
                      child: Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: MCColors.primaryPale,
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: const Icon(Icons.shield_outlined, size: 40, color: MCColors.primary),
                      ),
                    ),
                    const SizedBox(height: MCSpacing.lg),

                    Text('Check your inbox', style: MCTypography.h1),
                    const SizedBox(height: 8),
                    Text(
                      'We sent a ${AppConstants.otpDigitCount}-digit code to',
                      style: MCTypography.body.copyWith(color: MCColors.textSecondary),
                    ),
                    Text(
                      widget.email,
                      style: MCTypography.body.copyWith(
                        color: MCColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: MCSpacing.xl),

                    // ── OTP boxes ──────────────────────────────────
                    MCOtpInput(
                      length: AppConstants.otpDigitCount,
                      onCompleted: (v) {
                        setState(() => _otp = v);
                        _verifyOtp();
                      },
                    ),
                    const SizedBox(height: 20),

                    // ── Timer chip ─────────────────────────────────
                    Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: _timerExpired ? MCColors.errorBg : MCColors.amberPale,
                          borderRadius: BorderRadius.circular(MCSpacing.radiusPill),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.timer_outlined,
                              size: 14,
                              color: _timerExpired ? MCColors.error : MCColors.amberDark,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              _timerExpired ? 'Code expired' : _timerLabel,
                              style: MCTypography.captionBold.copyWith(
                                color: _timerExpired ? MCColors.error : MCColors.amberDark,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // ── Verify CTA ─────────────────────────────────
                    if (_verified)
                      Container(
                        height: 54,
                        decoration: BoxDecoration(
                          color: MCColors.successBg,
                          borderRadius: BorderRadius.circular(MCSpacing.radiusButton),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.check_circle, color: MCColors.success),
                            const SizedBox(width: 8),
                            Text(
                              'Verified',
                              style: MCTypography.labelLg.copyWith(color: MCColors.success),
                            ),
                          ],
                        ),
                      )
                    else
                      MCPrimaryButton(
                        label: 'Verify & Continue',
                        loading: _verifying,
                        onPressed: _otp.length == AppConstants.otpDigitCount ? _verifyOtp : null,
                      ),

                    const SizedBox(height: 16),

                    // ── Resend ────────────────────────────────────
                    Center(
                      child: _resending
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : GestureDetector(
                              onTap: _timerExpired ? _resendOtp : null,
                              child: Text(
                                _timerExpired ? 'Resend Code' : 'Resend in $_timerLabel',
                                style: MCTypography.label.copyWith(
                                  color: _timerExpired ? MCColors.primaryMid : MCColors.textMuted,
                                ),
                              ),
                            ),
                    ),
                    const SizedBox(height: 24),

                    // ── Security note ─────────────────────────────
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: MCColors.background,
                        borderRadius: BorderRadius.circular(MCSpacing.radiusSm),
                        border: Border.all(color: MCColors.border),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.info_outline, size: 14, color: MCColors.textMuted),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Never share this code with anyone. Manager Connect will never ask for it via phone or email.',
                              style: MCTypography.caption,
                            ),
                          ),
                        ],
                      ),
                    ),
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
