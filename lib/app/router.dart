import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kvman/features/auth/auth_notifier.dart';
import 'package:kvman/features/auth/phone_entry_screen.dart';
import 'package:kvman/features/auth/pin_entry_screen.dart';
import 'package:kvman/features/auth/forgot_password_screen.dart';
import 'package:kvman/features/home/home_screen.dart';
import 'package:kvman/features/profile/profile_screen.dart';
import 'package:kvman/features/usage/usage_screen.dart';
import 'package:kvman/features/notifications/notifications_screen.dart';
import 'package:kvman/features/settings/settings_screen.dart';
import 'package:kvman/features/network/network_screen.dart';
import 'package:kvman/features/settings/active_sessions_screen.dart';
import 'package:kvman/core/widgets/double_tap_to_exit.dart';

class AppRoutes {
  AppRoutes._();
  static const home = '/';
  static const usage = '/usage';
  static const phoneEntry = '/auth/phone';
  static const pinEntry = '/auth/pin';
  static const forgotPassword = '/auth/forgot-password';
  static const profile = '/profile';
  static const notifications = '/notifications';
  static const settings = '/settings';
  static const diagnostics = '/diagnostics';
  static const activeSessions = '/active-sessions';
}

final titles = {0: 'KVMAN', 1: 'Usage', 2: 'Profile', 3: 'Settings'};

final appRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authNotifierProvider);

  return GoRouter(
    initialLocation: AppRoutes.home,
    redirect: (context, state) {
      if (authState.isLoading) return null;

      final isAuthenticated = authState.isAuthenticated;
      final goingToAuth = state.matchedLocation.startsWith('/auth');

      if (!isAuthenticated) {
        if (!goingToAuth) return AppRoutes.phoneEntry;
        return null;
      }

      if (isAuthenticated && goingToAuth) {
        return AppRoutes.home;
      }

      return null;
    },
    routes: [
      GoRoute(
        path: AppRoutes.phoneEntry,
        builder: (context, state) => const PhoneEntryScreen(),
      ),
      GoRoute(
        path: AppRoutes.pinEntry,
        builder: (context, state) {
          final phoneNumber = state.extra as String;
          return PinEntryScreen(phoneNumber: phoneNumber);
        },
      ),
      GoRoute(
        path: AppRoutes.forgotPassword,
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: AppRoutes.notifications,
        builder: (context, state) => const NotificationsScreen(),
      ),
      GoRoute(
        path: AppRoutes.diagnostics,
        builder: (context, state) => const NetworkScreen(),
      ),
      GoRoute(
        path: AppRoutes.activeSessions,
        builder: (context, state) => const ActiveSessionsScreen(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) => DoubleTapToExit(
          child: Scaffold(
            appBar: AppBar(
              title: Text(
                titles[navigationShell.currentIndex]!,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              actions: [
                if (navigationShell.currentIndex == 2)
                  IconButton(
                    icon: const Icon(Icons.logout, color: Colors.red),
                    onPressed: () async {
                      final shouldLogout = await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Log Out?'),
                          content: const Text(
                            'Are you sure you want to log out of KvMan?',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(false),
                              child: const Text('Cancel'),
                            ),
                            FilledButton.tonal(
                              onPressed: () => Navigator.of(context).pop(true),
                              style: FilledButton.styleFrom(
                                foregroundColor: Colors.red,
                              ),
                              child: const Text('Log Out'),
                            ),
                          ],
                        ),
                      );

                      if (shouldLogout == true) {
                        ref.read(authNotifierProvider.notifier).logout();
                      }
                    },
                  ),
                IconButton(
                  icon: const Icon(Icons.notifications_outlined),
                  onPressed: () => context.push(AppRoutes.notifications),
                ),
              ],
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
                NavigationDestination(
                  icon: Icon(Icons.person_outline),
                  selectedIcon: Icon(Icons.person),
                  label: 'Profile',
                ),
                NavigationDestination(
                  icon: Icon(Icons.settings_outlined),
                  selectedIcon: Icon(Icons.settings),
                  label: 'Settings',
                ),
              ],
            ),
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
                path: AppRoutes.usage,
                builder: (context, state) => const UsageScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.profile,
                builder: (context, state) => const ProfileScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.settings,
                builder: (context, state) => const SettingsScreen(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
});
