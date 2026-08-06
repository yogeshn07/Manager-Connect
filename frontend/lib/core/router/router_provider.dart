import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:manager_connect/core/router/app_router.dart';
import 'package:manager_connect/core/router/route_guards.dart';
import 'package:manager_connect/features/auth/presentation/providers/auth_notifier.dart';
import 'package:manager_connect/shared/providers/splash_timer_provider.dart';

part 'router_provider.g.dart';

@riverpod
GoRouter appRouter(Ref ref) {
  final authState = ref.watch(authProvider);
  final splashTimerElapsed = ref.watch(splashTimerProvider);

  // While the minimum 2800ms splash window has not elapsed, present the
  // auth state as InitialState so the route guard keeps the user on the
  // splash screen. Auth initializes concurrently — this only delays the
  // navigation trigger, not the network call itself.
  final effectiveAuth = (!splashTimerElapsed && authState is! AppAuthStateInitial)
      ? const AppAuthStateInitial()
      : authState;

  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: '/',
    debugLogDiagnostics: true,
    redirect: (context, state) => guardRedirect(
      authState: effectiveAuth,
      routerState: state,
    ),
    routes: appRoutes,
  );
}
