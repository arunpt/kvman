import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kvman/app/theme_provider.dart';
import 'package:kvman/app/router.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);

    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 16),
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: Text(
            'Appearance',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: SizedBox(
            width: double.infinity,
            child: SegmentedButton<ThemeMode>(
              segments: const [
                ButtonSegment(
                  value: ThemeMode.system,
                  icon: Icon(Icons.brightness_auto),
                  label: Text('Auto'),
                ),
                ButtonSegment(
                  value: ThemeMode.light,
                  icon: Icon(Icons.light_mode),
                  label: Text('Light'),
                ),
                ButtonSegment(
                  value: ThemeMode.dark,
                  icon: Icon(Icons.dark_mode),
                  label: Text('Dark'),
                ),
              ],
              selected: {themeMode},
              onSelectionChanged: (Set<ThemeMode> newSelection) {
                ref
                    .read(themeModeProvider.notifier)
                    .setThemeMode(newSelection.first);
              },
            ),
          ),
        ),
        const SizedBox(height: 16),
        ListTile(
          leading: const Icon(Icons.devices_outlined),
          title: const Text('Active Sessions'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () {
            context.push(AppRoutes.activeSessions);
          },
        ),
        const ListTile(
          leading: Icon(Icons.info_outline),
          title: Text('App Version'),
          trailing: Text(
            'v1.0.0 (Build 1)',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        ListTile(
          leading: const Icon(Icons.gavel_outlined),
          title: const Text('Disclaimer & Privacy'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () {
            showAboutDialog(
              context: context,
              applicationName: 'KvMan',
              applicationVersion: '1.0.0',
              applicationLegalese: '© 2026 KvMan App.\n\nThis application is provided "as is", without warranty of any kind. Use of this application is at your own risk. The developers are not responsible for any data loss, damages, or issues arising from the use of this software.',
              applicationIcon: const Icon(Icons.router, size: 48),
            );
          },
        ),
      ],
    );
  }
}
