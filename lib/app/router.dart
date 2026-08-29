import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:kvman/features/home/home_screen.dart';
import 'package:kvman/features/usage/usage_screen.dart';

class AppRoutes {
  AppRoutes._();
  static const home = '/';
}

final titles = {0: 'KVMAN', 1: 'Usage'};

final appRouter = GoRouter(
  initialLocation: AppRoutes.home,
  routes: [
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) => Scaffold(
        appBar: AppBar(
          title: Text(titles[navigationShell.currentIndex]!),
          // titleTextStyle: const TextStyle(fontWeight: FontWeight.w800),
        ),
        body: navigationShell,
        bottomNavigationBar: NavigationBar(
          selectedIndex: navigationShell.currentIndex,
          onDestinationSelected: (index) {
            navigationShell.goBranch(
              index,
              initialLocation: index == navigationShell.currentIndex,
            );
          },
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home),
              label: 'Home',
            ),
            NavigationDestination(
              icon: Icon(Icons.bar_chart_outlined),
              selectedIcon: Icon(Icons.bar_chart),
              label: 'Usage',
            ),
          ],
        ),
      ),
      branches: [
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRoutes.home,
              builder: (context, state) => const HomeScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/usage',
              builder: (context, state) => const UsageScreen(),
            ),
          ],
        ),
      ],
    ),
  ],
);
