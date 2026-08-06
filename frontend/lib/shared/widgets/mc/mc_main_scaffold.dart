import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:manager_connect/core/constants/route_names.dart';
import 'package:manager_connect/features/notifications/presentation/providers/notification_provider.dart';
import 'package:manager_connect/shared/widgets/mc/mc_bottom_nav.dart';

/// Moonchild shell — GoRouter ShellRoute wrapper with MCBottomNav.
/// Phone frame is applied globally by App.builder; this widget just
/// handles tab routing and the persistent bottom nav.
class MCMainScaffold extends ConsumerWidget {
  const MCMainScaffold({required this.child, super.key});

  final Widget child;

  static const _routes = [
    RouteNames.feed,
    RouteNames.events,
    RouteNames.growth,
    RouteNames.analytics,
    RouteNames.profile,
    RouteNames.insights,
  ];

  int _index(BuildContext context) {
    final loc = GoRouterState.of(context).uri.path;
    for (var i = 0; i < _routes.length; i++) {
      if (loc.startsWith(_routes[i])) return i;
    }
    return 0;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final idx = _index(context);
    final unreadCount = ref.watch(notificationProvider.select((s) => s.unreadCount));

    return Scaffold(
      backgroundColor: const Color(0xFFF4F5F7),
      body: Column(
        children: [
          Expanded(child: child),
          MCBottomNav(
            currentIndex: idx,
            onTap: (i) => context.go(_routes[i]),
            unreadAlerts: unreadCount > 0,
          ),
        ],
      ),
    );
  }
}
