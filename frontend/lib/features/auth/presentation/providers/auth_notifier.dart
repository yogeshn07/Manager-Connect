import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:manager_connect/core/constants/supabase_constants.dart';

part 'auth_notifier.g.dart';

enum AppRole { member, admin, system }

class AppSession {
  const AppSession({
    required this.userId,
    required this.email,
    required this.role,
    required this.isActive,
    required this.onboardingCompleted,
    this.fullName,
  });

  final String userId;
  final String? email;
  final AppRole role;
  final bool isActive;
  final bool onboardingCompleted;
  final String? fullName;
}

sealed class AppAuthState {
  const AppAuthState();
}

final class AppAuthStateInitial extends AppAuthState {
  const AppAuthStateInitial();
}

final class AppAuthStateUnauthenticated extends AppAuthState {
  const AppAuthStateUnauthenticated();
}

final class AppAuthStateAuthenticated extends AppAuthState {
  const AppAuthStateAuthenticated(this.session);
  final AppSession session;
}

final class AppAuthStateDeactivated extends AppAuthState {
  const AppAuthStateDeactivated();
}

AppRole _parseRole(String role) {
  return switch (role) {
    'admin' => AppRole.admin,
    'system' => AppRole.system,
    _ => AppRole.member,
  };
}

@Riverpod(keepAlive: true)
class AuthNotifier extends _$AuthNotifier {
  String? _pendingInviteToken;

  @override
  AppAuthState build() {
    return const AppAuthStateInitial();
  }

  void setInviteToken(String token) {
    _pendingInviteToken = token;
  }

  String? consumeInviteToken() {
    final token = _pendingInviteToken;
    _pendingInviteToken = null;
    return token;
  }

  Future<void> initialize() async {
    final client = Supabase.instance.client;
    final session = client.auth.currentSession;

    if (session == null) {
      state = const AppAuthStateUnauthenticated();
      return;
    }

    await _loadProfile(session.user.id, session.user.email);
  }

  Future<void> handleSignIn() async {
    final client = Supabase.instance.client;
    final session = client.auth.currentSession;

    if (session == null) {
      state = const AppAuthStateUnauthenticated();
      return;
    }

    await _loadProfile(session.user.id, session.user.email);
  }

  Future<void> handleProfileCreated() async {
    final client = Supabase.instance.client;
    final session = client.auth.currentSession;

    if (session == null) {
      state = const AppAuthStateUnauthenticated();
      return;
    }

    await _loadProfile(session.user.id, session.user.email);
  }

  void setUnauthenticated() {
    _pendingInviteToken = null;
    state = const AppAuthStateUnauthenticated();
  }

  void setDeactivated() {
    state = const AppAuthStateDeactivated();
  }

  Future<void> _loadProfile(String userId, String? email) async {
    try {
      final client = Supabase.instance.client;
      final response = await client
          .from(Table.profiles)
          .select(
            'id, full_name, app_role, is_active, onboarding_completed',
          )
          .eq('id', userId)
          .maybeSingle();

      if (response == null) {
        state = AppAuthStateAuthenticated(
          AppSession(
            userId: userId,
            email: email,
            role: AppRole.member,
            isActive: true,
            onboardingCompleted: false,
          ),
        );
        return;
      }

      final isActive = response['is_active'] as bool;
      if (!isActive) {
        state = const AppAuthStateDeactivated();
        return;
      }

      state = AppAuthStateAuthenticated(
        AppSession(
          userId: response['id'] as String,
          email: email,
          role: _parseRole(response['app_role'] as String),
          isActive: true,
          onboardingCompleted: response['onboarding_completed'] as bool,
          fullName: response['full_name'] as String?,
        ),
      );
    } catch (_) {
      state = const AppAuthStateUnauthenticated();
    }
  }
}
