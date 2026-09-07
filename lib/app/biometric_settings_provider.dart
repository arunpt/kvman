import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kvman/app/theme_provider.dart';
import 'package:local_auth/local_auth.dart';

class BiometricSettingsNotifier extends Notifier<bool> {
  static const _key = 'biometric_enabled';

  @override
  bool build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    return prefs.getBool(_key) ?? false;
  }

  Future<void> setEnabled(bool value) async {
    final localAuth = LocalAuthentication();
    try {
      final didAuthenticate = await localAuth.authenticate(
        localizedReason: 'Authenticate to modify biometric settings',
        biometricOnly: false,
        persistAcrossBackgrounding: true,
      );
      if (!didAuthenticate) return;
    } catch (e) {
      return;
    }

    state = value;
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setBool(_key, value);
  }
}

final biometricSettingsProvider =
    NotifierProvider<BiometricSettingsNotifier, bool>(() {
      return BiometricSettingsNotifier();
    });
