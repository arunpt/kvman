import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kvman/features/auth/auth_notifier.dart';

class AppLockOverlay extends ConsumerStatefulWidget {
  final Widget child;
  const AppLockOverlay({super.key, required this.child});

  @override
  ConsumerState<AppLockOverlay> createState() => _AppLockOverlayState();
}

class _AppLockOverlayState extends ConsumerState<AppLockOverlay> {
  bool _hasPrompted = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final authState = ref.watch(authNotifierProvider);

    if (authState.isAuthenticated &&
        !authState.isBiometricVerified &&
        !_hasPrompted) {
      _hasPrompted = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(authNotifierProvider.notifier).verifyBiometric();
      });
    } else if (authState.isBiometricVerified) {
      _hasPrompted = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);
    final isLocked =
        authState.isAuthenticated && !authState.isBiometricVerified;

    return Stack(
      children: [
        widget.child,
        if (isLocked)
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
              child: Container(
                color: Theme.of(context).colorScheme.surface.withAlpha(150),
                child: Center(
                  child: Card(
                    margin: const EdgeInsets.symmetric(horizontal: 32),
                    elevation: 16,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.lock_outline,
                            size: 64,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          const SizedBox(height: 24),
                          Text(
                            'App is Locked',
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Please authenticate to continue.',
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurfaceVariant,
                                ),
                          ),
                          const SizedBox(height: 32),
                          FilledButton.icon(
                            onPressed: () {
                              ref
                                  .read(authNotifierProvider.notifier)
                                  .verifyBiometric();
                            },
                            icon: const Icon(Icons.fingerprint),
                            label: const Text('Unlock'),
                            style: FilledButton.styleFrom(
                              minimumSize: const Size(double.infinity, 50),
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextButton(
                            onPressed: () {
                              ref.read(authNotifierProvider.notifier).logout();
                            },
                            style: TextButton.styleFrom(
                              foregroundColor: Theme.of(context)
                                  .colorScheme
                                  .error,
                              minimumSize: const Size(double.infinity, 50),
                            ),
                            child: const Text('Log out instead'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
