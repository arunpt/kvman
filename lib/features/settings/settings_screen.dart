import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kvman/app/theme_provider.dart';
import 'package:kvman/app/biometric_settings_provider.dart';
import 'package:kvman/app/router.dart';
import 'package:url_launcher/url_launcher.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final isBiometricEnabled = ref.watch(biometricSettingsProvider);
    final primaryColor = Theme.of(context).colorScheme.primary;

    Widget buildSectionHeader(String title) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
        child: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
            color: primaryColor,
          ),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.only(bottom: 24),
      children: [
        buildSectionHeader('Appearance'),
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

        buildSectionHeader('Security'),
        SwitchListTile(
          secondary: const Icon(Icons.fingerprint),
          title: const Text('Biometric Lock'),
          subtitle: const Text('Require fingerprint when opening app'),
          value: isBiometricEnabled,
          onChanged: (val) {
            ref.read(biometricSettingsProvider.notifier).setEnabled(val);
          },
        ),
        ListTile(
          leading: const Icon(Icons.devices_outlined),
          title: const Text('Active Sessions'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () {
            context.push(AppRoutes.activeSessions);
          },
        ),

        buildSectionHeader('About'),
        ListTile(
          leading: const Icon(Icons.code),
          title: const Text('Source Code'),
          subtitle: const Text('View on GitHub'),
          trailing: const Icon(Icons.open_in_new, size: 20),
          onTap: () async {
            final Uri url = Uri.parse('https://github.com/your-username/kvman');
            if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Could not open the link.')),
                );
              }
            }
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
