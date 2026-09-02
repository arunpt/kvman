import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kvman/features/auth/auth_notifier.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authNotifierProvider);
    final activeUser = authState.activeUser;
    final users = authState.users;

    if (activeUser == null) return const SizedBox.shrink();

    return Scaffold(
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const CircleAvatar(
            radius: 40,
            child: Icon(Icons.person, size: 40),
          ),
          const SizedBox(height: 16),
          Text(
            activeUser.userName,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          Text(
            activeUser.mobileNo,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 32),
          
          if (users.length > 1) ...[
            const Text(
              'Switch Account',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Card(
              margin: EdgeInsets.zero,
              clipBehavior: Clip.antiAlias,
              child: Column(
                children: users.map((u) {
                  final isActive = u.id == activeUser.id;
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: isActive
                          ? Theme.of(context).colorScheme.primaryContainer
                          : Theme.of(context).colorScheme.surfaceContainerHighest,
                      child: Text(u.userName.substring(0, 1).toUpperCase()),
                    ),
                    title: Text(u.userName),
                    subtitle: Text(u.customerId),
                    trailing: isActive
                        ? Icon(Icons.check_circle, color: Theme.of(context).colorScheme.primary)
                        : null,
                    onTap: isActive
                        ? null
                        : () {
                            ref.read(authNotifierProvider.notifier).switchUser(u.id);
                          },
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 32),
          ],

          FilledButton.tonalIcon(
            onPressed: () => ref.read(authNotifierProvider.notifier).logout(),
            icon: const Icon(Icons.logout),
            label: const Text('Logout'),
          ),
        ],
      ),
    );
  }
}