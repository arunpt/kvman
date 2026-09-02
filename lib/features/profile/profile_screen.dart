import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kvman/features/auth/auth_notifier.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Center(
      child: FilledButton.tonalIcon(
        onPressed: () => ref.read(authNotifierProvider.notifier).logout(),
        icon: const Icon(Icons.logout),
        label: const Text('Logout'),
      ),
    );
  }
}