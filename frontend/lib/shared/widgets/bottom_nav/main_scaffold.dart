import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:manager_connect/core/constants/route_names.dart';
import 'package:manager_connect/shared/widgets/mc/mc_bottom_nav.dart';

class MainScaffold extends StatelessWidget {
  const MainScaffold({required this.child, super.key});

  final Widget child;

  static const _tabs = [
    RouteNames.feed,
    RouteNames.events,
    RouteNames.growth,
    '/notifications',
    RouteNames.profile,
  ];

  int _currentIndex(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    final index = _tabs.indexWhere(location.startsWith);
    return index >= 0 ? index : 0;
  }

  void _onTabTap(BuildContext context, int index) {
    context.go(_tabs[index]);
  }

  @override
  Widget build(BuildContext context) {
    final currentIndex = _currentIndex(context);

    return Scaffold(
      body: child,
      bottomNavigationBar: McBottomNav(
        currentIndex: currentIndex,
        onTap: (i) => _onTabTap(context, i),
      ),
    );
  }
}
