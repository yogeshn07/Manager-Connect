import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:manager_connect/core/constants/route_names.dart';
import 'package:manager_connect/shared/widgets/bottom_nav/main_scaffold.dart';

// Auth screens
import 'package:manager_connect/features/auth/presentation/screens/welcome_screen.dart';
import 'package:manager_connect/features/auth/presentation/screens/verify_otp_screen.dart';
import 'package:manager_connect/features/auth/presentation/screens/create_profile_screen.dart';

// Placeholder screens for tabs not yet implemented
import 'package:manager_connect/shared/widgets/placeholders/placeholder_screen.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorKey = GlobalKey<NavigatorState>();

final List<RouteBase> appRoutes = [
  // Redirect root
  GoRoute(
    path: '/',
    redirect: (_, __) => RouteNames.feed,
  ),

  // Auth group
  GoRoute(
    path: RouteNames.welcome,
    builder: (context, state) => const WelcomeScreen(),
  ),
  GoRoute(
    path: RouteNames.verifyOtp,
    builder: (context, state) => const VerifyOtpScreen(),
  ),
  GoRoute(
    path: RouteNames.createProfile,
    builder: (context, state) => const CreateProfileScreen(),
  ),

  // App shell with bottom navigation
  ShellRoute(
    navigatorKey: _shellNavigatorKey,
    builder: (context, state, child) => MainScaffold(child: child),
    routes: [
      GoRoute(
        path: RouteNames.feed,
        pageBuilder: (context, state) => const NoTransitionPage(
          child: PlaceholderScreen(title: 'Feed'),
        ),
      ),
      GoRoute(
        path: RouteNames.events,
        pageBuilder: (context, state) => const NoTransitionPage(
          child: PlaceholderScreen(title: 'Events'),
        ),
      ),
      GoRoute(
        path: RouteNames.growth,
        pageBuilder: (context, state) => const NoTransitionPage(
          child: PlaceholderScreen(title: 'Growth'),
        ),
      ),
      GoRoute(
        path: RouteNames.analytics,
        pageBuilder: (context, state) => const NoTransitionPage(
          child: PlaceholderScreen(title: 'Analytics'),
        ),
      ),
      GoRoute(
        path: RouteNames.profile,
        pageBuilder: (context, state) => const NoTransitionPage(
          child: PlaceholderScreen(title: 'Profile'),
        ),
      ),
    ],
  ),

  // Stack routes (over tabs)
  GoRoute(
    parentNavigatorKey: _rootNavigatorKey,
    path: RouteNames.notifications,
    builder: (context, state) =>
        const PlaceholderScreen(title: 'Notifications'),
  ),

  // Admin group
  GoRoute(
    parentNavigatorKey: _rootNavigatorKey,
    path: RouteNames.admin,
    builder: (context, state) => const PlaceholderScreen(title: 'Admin'),
  ),
];
