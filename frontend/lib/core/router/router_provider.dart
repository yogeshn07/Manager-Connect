import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:manager_connect/core/router/app_router.dart';
import 'package:manager_connect/core/router/route_guards.dart';
import 'package:manager_connect/features/auth/presentation/providers/auth_notifier.dart';

part 'router_provider.g.dart';

@riverpod
GoRouter appRouter(Ref ref) {
  final authState = ref.watch(authProvider);

  return GoRouter(
    initialLocation: '/',
    debugLogDiagnostics: true,
    redirect: (context, state) => guardRedirect(
      authState: authState,
      routerState: state,
    ),
    routes: appRoutes,
  );
}
