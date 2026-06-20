import 'package:go_router/go_router.dart';
import 'package:manager_connect/core/constants/route_names.dart';
import 'package:manager_connect/features/auth/presentation/providers/auth_notifier.dart';

String? guardRedirect({
  required AppAuthState authState,
  required GoRouterState routerState,
}) {
  final location = routerState.matchedLocation;
  final isAuthRoute = location == RouteNames.welcome ||
      location == RouteNames.verifyOtp ||
      location == RouteNames.createProfile;
  final isAdminRoute = location.startsWith('/admin');

  return switch (authState) {
    AppAuthStateInitial() => null,
    AppAuthStateUnauthenticated() => isAuthRoute ? null : RouteNames.welcome,
    AppAuthStateDeactivated() => isAuthRoute ? null : RouteNames.welcome,
    AppAuthStateAuthenticated(:final session) => () {
        if (!session.onboardingCompleted) {
          return location == RouteNames.createProfile
              ? null
              : RouteNames.createProfile;
        }
        if (isAuthRoute) return RouteNames.feed;
        if (isAdminRoute && session.role != AppRole.admin) {
          return RouteNames.feed;
        }
        return null;
      }(),
  };
}
