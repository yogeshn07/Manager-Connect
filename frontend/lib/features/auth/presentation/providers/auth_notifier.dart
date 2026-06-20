import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'auth_notifier.g.dart';

enum AppRole { member, admin, system }

class AppSession {
  const AppSession({
    required this.userId,
    required this.email,
    required this.role,
    required this.isActive,
    required this.onboardingCompleted,
  });

  final String userId;
  final String? email;
  final AppRole role;
  final bool isActive;
  final bool onboardingCompleted;
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

@Riverpod(keepAlive: true)
class AuthNotifier extends _$AuthNotifier {
  @override
  AppAuthState build() {
    return const AppAuthStateInitial();
  }

  void setAuthenticated(AppSession session) {
    state = AppAuthStateAuthenticated(session);
  }

  void setUnauthenticated() {
    state = const AppAuthStateUnauthenticated();
  }

  void setDeactivated() {
    state = const AppAuthStateDeactivated();
  }
}
