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
              applicationName: 'KVMan',
              applicationVersion: '1.0.0',
              applicationLegalese: '© 2026 KVMan App.\n\nDISCLAIMER: This is an unofficial, third-party application built strictly for educational purposes. It utilizes read-only functionalities to improve ease of use. KVMan is NOT affiliated with, endorsed by, sponsored by, or in any way officially connected to the original service provider. All product and company names, logos, and brands are the property of their respective owners.\n\nThis software is provided "as is", without warranty of any kind. Use of this application is entirely at your own risk. The developers assume no legal liability or responsibility for any data loss, account issues, or damages arising from its use.',
              applicationIcon: const Icon(Icons.router, size: 48),
            );
          },
        ),
      ],
    );
  }
}
