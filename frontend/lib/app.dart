import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manager_connect/core/router/router_provider.dart';
import 'package:manager_connect/shared/widgets/mc/mc_theme.dart';

class App extends ConsumerWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);

    return MaterialApp.router(
      title: 'Manager Connect',
      debugShowCheckedModeBanner: false,
      theme: McTheme.light,
      themeMode: ThemeMode.light,
      routerConfig: router,
    );
  }
}
