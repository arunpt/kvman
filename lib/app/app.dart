import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kvman/app/router.dart';
import 'package:kvman/app/theme.dart';
import 'package:kvman/app/theme_provider.dart';
import 'package:kvman/core/widgets/app_lock_overlay.dart';

final GlobalKey<ScaffoldMessengerState> rootScaffoldMessengerKey =
    GlobalKey<ScaffoldMessengerState>();

class KvManApp extends ConsumerWidget {
  const KvManApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    final themeMode = ref.watch(themeModeProvider);
    return DynamicColorBuilder(
      builder: (lightDynamic, darkDynamic) => MaterialApp.router(
        scaffoldMessengerKey: rootScaffoldMessengerKey,
        darkTheme: AppTheme.dark(darkDynamic),
        theme: AppTheme.light(lightDynamic),
        themeMode: themeMode,
        title: 'KVMan',
        debugShowCheckedModeBanner: false,
        routerConfig: router,
        builder: (context, child) {
          if (child == null) return const SizedBox.shrink();
          return AppLockOverlay(child: child);
        },
      ),
    );
  }
}
