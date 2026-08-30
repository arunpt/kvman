import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kvman/app/router.dart';
import 'package:kvman/app/theme.dart';

class KvManApp extends ConsumerWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    return DynamicColorBuilder(
      builder: (lightDynamic, darkDynamic) => MaterialApp.router(
        darkTheme: AppTheme.dark(darkDynamic),
        theme: AppTheme.light(lightDynamic),
        themeMode: ThemeMode.system,
        title: 'KvMan',
        debugShowCheckedModeBanner: false,
        routerConfig: router,
      ),
    );
  }
}
