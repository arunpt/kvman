import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _tokenKey = 'auth_token';
const _phoneKey = 'auth_phone';

final authNotifierProvider =
    NotifierProvider<AuthNotifier, AuthState>(AuthNotifier.new);

class AuthState {
  final bool isAuthenticated;
  final bool isLoading;
  final String? token;
  final String? phoneNumber;

  const AuthState({
    this.isAuthenticated = false,
    this.isLoading = true,
    this.token,
    this.phoneNumber,
  });
}

class AuthNotifier extends Notifier<AuthState> {
  @override
  AuthState build() {
    _loadToken();
    return const AuthState(); // isLoading: true by default
  }

  Future<void> _loadToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_tokenKey);
    final phone = prefs.getString(_phoneKey);

    state = AuthState(
      isAuthenticated: token != null,
      isLoading: false,
      token: token,
      phoneNumber: phone,
    );
  }

  Future<void> login({
    required String token,
    required String phoneNumber,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
    await prefs.setString(_phoneKey, phoneNumber);
    state = AuthState(
      isAuthenticated: true,
      isLoading: false,
      token: token,
      phoneNumber: phoneNumber,
    );
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_phoneKey);
    state = const AuthState(isAuthenticated: false, isLoading: false);
  }
}
