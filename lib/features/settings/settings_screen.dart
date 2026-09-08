import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kvman/app/theme_provider.dart';
import 'package:kvman/app/biometric_settings_provider.dart';
import 'package:kvman/app/router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:kvman/features/update/update_service.dart';
import 'package:kvman/features/update/update_dialog.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  String _appVersion = 'Loading...';
  bool _isCheckingUpdate = false;

  @override
  void initState() {
    super.initState();
    _loadVersion();
  }

  Future<void> _loadVersion() async {
    final info = await PackageInfo.fromPlatform();
    setState(() {
      _appVersion = 'v${info.version}';
    });
  }

  Future<void> _checkForUpdates() async {
    setState(() {
      _isCheckingUpdate = true;
    });

    final updateService = UpdateService();
    final updateInfo = await updateService.checkForUpdate();

    if (!mounted) return;

    setState(() {
      _isCheckingUpdate = false;
    });

    if (updateInfo.isUpdateAvailable) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => UpdateDialog(
          latestVersion: updateInfo.latestVersion,
          downloadUrl: updateInfo.downloadUrl,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You are on the latest version!')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
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
            final Uri url = Uri.parse('https://github.com/arunpt/kvman');
            if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Could not open the link.')),
                );
              }
            }
          },
        ),
        ListTile(
          leading: const Icon(Icons.info_outline),
          title: const Text('App Version'),
          trailing: Text(
            _appVersion,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        ListTile(
          leading: const Icon(Icons.system_update_alt),
          title: const Text('Check for Updates'),
          trailing: _isCheckingUpdate
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.chevron_right),
          onTap: _isCheckingUpdate ? null : _checkForUpdates,
        ),
        ListTile(
          leading: const Icon(Icons.gavel_outlined),
          title: const Text('Disclaimer & Privacy'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () {
            showAboutDialog(
              context: context,
              applicationName: 'KVMan',
              applicationVersion: _appVersion.split(' ').first,
              applicationLegalese: '© 2026 KVMan App.\n\nDISCLAIMER: This is an unofficial, third-party application built strictly for educational purposes. It utilizes read-only functionalities to improve ease of use. KVMan is NOT affiliated with, endorsed by, sponsored by, or in any way officially connected to the original service provider. All product and company names, logos, and brands are the property of their respective owners.\n\nThis software is provided "as is", without warranty of any kind. Use of this application is entirely at your own risk. The developers assume no legal liability or responsibility for any data loss, account issues, or damages arising from its use.',
              applicationIcon: const Icon(Icons.router, size: 48),
            );
          },
        ),
      ],
    );
  }
}
