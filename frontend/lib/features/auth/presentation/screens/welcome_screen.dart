import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:manager_connect/core/constants/route_names.dart';
import 'package:manager_connect/core/errors/app_exception.dart';
import 'package:manager_connect/features/auth/data/repositories/auth_repository.dart';
import 'package:manager_connect/features/auth/presentation/providers/auth_notifier.dart';
import 'package:manager_connect/shared/providers/supabase_provider.dart';
import 'package:manager_connect/shared/widgets/toast.dart';

class WelcomeScreen extends ConsumerStatefulWidget {
  const WelcomeScreen({super.key});

  @override
  ConsumerState<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends ConsumerState<WelcomeScreen> {
  final _emailController = TextEditingController();
  final _tokenController = TextEditingController();
  bool _showInviteField = false;
  bool _sendingOtp = false;
  bool _validatingToken = false;
  String? _inviteeEmail;

  @override
  void dispose() {
    _emailController.dispose();
    _tokenController.dispose();
    super.dispose();
  }

  Future<void> _validateToken() async {
    final token = _tokenController.text.trim();
    if (token.isEmpty) return;

    setState(() => _validatingToken = true);
    try {
      final client = ref.read(supabaseClientProvider);
      final repo = AuthRepository(client);
      final result = await repo.validateInviteToken(token);

      final email = result['invitee_email'] as String?;
      final phone = result['invitee_phone'] as String?;

      ref.read(authProvider.notifier).setInviteToken(token);

      setState(() {
        _inviteeEmail = email ?? phone;
        if (email != null && email.isNotEmpty) {
          _emailController.text = email;
        }
      });

      if (mounted) {
        showSuccessToast(
          context,
          'Invitation verified for ${result['invitee_name']}',
        );
      }
    } on AppException catch (e) {
      if (mounted) showErrorToast(context, e.message);
    } catch (e) {
      if (mounted) showErrorToast(context, 'Failed to validate invitation');
    } finally {
      if (mounted) setState(() => _validatingToken = false);
    }
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
    } catch (e) {
      if (mounted) showErrorToast(context, 'Failed to send OTP');
    } finally {
      if (mounted) setState(() => _sendingOtp = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 60),
              Icon(
                Icons.people_alt_rounded,
                size: 80,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 24),
              Text(
                'Manager Connect',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 8),
              Text(
                'Your private manager community',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
              const SizedBox(height: 48),
              if (_showInviteField) ...[
                TextField(
                  controller: _tokenController,
                  decoration: InputDecoration(
                    labelText: 'Invitation Code',
                    hintText: 'Paste your invitation code',
                    border: const OutlineInputBorder(),
                    suffixIcon: _validatingToken
                        ? const Padding(
                            padding: EdgeInsets.all(12),
                            child: SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          )
                        : IconButton(
                            icon: const Icon(Icons.check_circle_outline),
                            onPressed: _validateToken,
                          ),
                  ),
                  enabled: !_validatingToken,
                  onSubmitted: (_) => _validateToken(),
                ),
                const SizedBox(height: 16),
              ],
              TextField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  hintText: 'Enter your email address',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.email_outlined),
                ),
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.done,
                enabled: !_sendingOtp,
                onSubmitted: (_) => _sendOtp(),
              ),
              const SizedBox(height: 24),
              SizedBox(
                height: 48,
                child: FilledButton(
                  onPressed: _sendingOtp ? null : _sendOtp,
                  child: _sendingOtp
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Send OTP'),
                ),
              ),
              const SizedBox(height: 16),
              if (!_showInviteField)
                TextButton(
                  onPressed: () =>
                      setState(() => _showInviteField = true),
                  child: const Text('I have an invitation code'),
                ),
              if (_inviteeEmail != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    'Invitation verified',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.primary,
                        ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
