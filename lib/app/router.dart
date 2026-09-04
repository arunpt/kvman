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

class AppRoutes {
  AppRoutes._();
  static const home = '/';
  static const usage = '/usage';
  static const phoneEntry = '/auth/phone';
  static const pinEntry = '/auth/pin';
  static const forgotPassword = '/auth/forgot-password';
  static const profile = '/profile';
}

final titles = {0: 'KVMAN', 1: 'Usage', 2: 'Profile'};

final appRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authNotifierProvider);

  return GoRouter(
    initialLocation: AppRoutes.home,
    redirect: (context, state) {
      // While auth state is loading, don't redirect
      if (authState.isLoading) return null;

      final isAuthenticated = authState.isAuthenticated;
      final goingToAuth = state.matchedLocation.startsWith('/auth');

      if (!isAuthenticated && !goingToAuth) {
        return AppRoutes.phoneEntry;
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
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) => Scaffold(
          appBar: AppBar(title: Text(titles[navigationShell.currentIndex]!)),
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
        ],
      ),
    ],
  );
});
