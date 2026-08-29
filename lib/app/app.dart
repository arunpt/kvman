import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/material.dart';
import 'package:kvman/app/router.dart';
import 'package:kvman/app/theme.dart';

class KvManApp extends StatelessWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    return DynamicColorBuilder(
      builder: (lightDynamic, darkDynamic) => MaterialApp.router(
        darkTheme: AppTheme.dark(),
        theme: AppTheme.light(),
        themeMode: ThemeMode.system,
        title: 'KvMan',
        debugShowCheckedModeBanner: false,
        routerConfig: appRouter,
      ),
    );
  }
}
