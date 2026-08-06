import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manager_connect/core/router/router_provider.dart';
import 'package:manager_connect/shared/services/notification_service.dart';
import 'package:manager_connect/shared/widgets/mc/mc_theme.dart';

class App extends ConsumerWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    // Hand the live router to NotificationService so tapping a push
    // notification can deep-link into the correct screen.
    NotificationService.setRouter(router);

    return MaterialApp.router(
      title: 'The Catalysts',
      debugShowCheckedModeBanner: false,
      theme: MCTheme.light,
      themeMode: ThemeMode.light,
      routerConfig: router,
      builder: (context, child) {
        final mq = MediaQuery.of(context);
        // On mobile widths, render full-screen as normal
        if (mq.size.width <= 480) return child!;

        // On wide screens (web/desktop), wrap every screen in a 430px phone frame
        return Scaffold(
          backgroundColor: const Color(0xFFDDE1E8),
          body: Center(
            child: Container(
              width: 430,
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                color: const Color(0xFFF4F5F7),
                borderRadius: BorderRadius.circular(44),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.20),
                    blurRadius: 56,
                    offset: const Offset(0, 24),
                  ),
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 16,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              // Override MediaQuery so inner widgets see 430px width
              child: MediaQuery(
                data: mq.copyWith(size: Size(430, mq.size.height)),
                child: child!,
              ),
            ),
          ),
        );
      },
    );
  }
}
