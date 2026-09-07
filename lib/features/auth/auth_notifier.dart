import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kvman/features/auth/kv_user.dart';
import 'package:local_auth/local_auth.dart';

const _tokenKey = 'auth_token';
const _phoneKey = 'auth_phone';
const _usersKey = 'auth_users';
const _activeUserIdKey = 'auth_active_user_id';
const _tokenGenTimeKey = 'auth_token_gen_time';
const _prevTokenKey = 'auth_prev_token';

final authNotifierProvider = NotifierProvider<AuthNotifier, AuthState>(
  AuthNotifier.new,
);

class AuthState {
  final bool isAuthenticated;
  final bool isBiometricVerified;
  final bool isLoading;
  final String? token;
  final String? phoneNumber;
  final List<KvUser> users;
  final KvUser? activeUser;
  final DateTime? tokenGeneratedTime;
  final String? prevToken;

  const AuthState({
    this.isAuthenticated = false,
    this.isBiometricVerified = true,
    this.isLoading = true,
    this.token,
    this.phoneNumber,
    this.users = const [],
    this.activeUser,
    this.tokenGeneratedTime,
    this.prevToken,
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
    final usersStr = prefs.getString(_usersKey);
    final activeUserId = prefs.getString(_activeUserIdKey);

    final genTimeMs = prefs.getInt(_tokenGenTimeKey);
    final prevToken = prefs.getString(_prevTokenKey);
    DateTime? genTime;
    if (genTimeMs != null) {
      genTime = DateTime.fromMillisecondsSinceEpoch(genTimeMs);
    }

    List<KvUser> users = [];
    KvUser? activeUser;

    if (usersStr != null) {
      try {
        final List<dynamic> decoded = jsonDecode(usersStr);
        users = decoded.map((e) => KvUser.fromJson(e)).toList();
      } catch (_) {}
    }

    if (users.isNotEmpty) {
      activeUser = users.firstWhere(
        (u) => u.id == activeUserId,
        orElse: () => users.first,
      );
    }

    final isAuthenticated = token != null && users.isNotEmpty;
    final isBiometricEnabled = prefs.getBool('biometric_enabled') ?? false;
    bool isBiometricVerified = true;

    if (isAuthenticated && isBiometricEnabled) {
      try {
        final localAuth = LocalAuthentication();
        final canCheckBiometrics = await localAuth.canCheckBiometrics;
        final isDeviceSupported = await localAuth.isDeviceSupported();

        if (canCheckBiometrics || isDeviceSupported) {
          final availableBiometrics = await localAuth.getAvailableBiometrics();
          // We only require biometric verification if there is actually a biometric method enrolled
          if (availableBiometrics.isNotEmpty) {
            isBiometricVerified = false;
          }
        }
      } catch (e) {
        // If biometrics fail to check, default to true so we don't lock out the user
        isBiometricVerified = true;
      }
    }

    state = AuthState(
      isAuthenticated: isAuthenticated,
      isBiometricVerified: isBiometricVerified,
      isLoading: false,
      token: token,
      phoneNumber: phone,
      users: users,
      activeUser: activeUser,
      tokenGeneratedTime: genTime,
      prevToken: prevToken,
    );
  }

  Future<void> verifyBiometric() async {
    try {
      final localAuth = LocalAuthentication();
      final didAuthenticate = await localAuth.authenticate(
        localizedReason: 'Please authenticate to access KVMan',
        biometricOnly: false,
        persistAcrossBackgrounding: true,
      );
      if (didAuthenticate) {
        state = AuthState(
          isAuthenticated: state.isAuthenticated,
          isBiometricVerified: true,
          isLoading: state.isLoading,
          token: state.token,
          phoneNumber: state.phoneNumber,
          users: state.users,
          activeUser: state.activeUser,
          tokenGeneratedTime: state.tokenGeneratedTime,
          prevToken: state.prevToken,
        );
      }
    } catch (e) {
      // Handle error
    }
  }

  Future<void> login({
    required String token,
    required String phoneNumber,
    required List<KvUser> users,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
    await prefs.setString(_phoneKey, phoneNumber);

    final now = DateTime.now();
    await prefs.setInt(_tokenGenTimeKey, now.millisecondsSinceEpoch);
    await prefs.remove(_prevTokenKey);

    final usersStr = jsonEncode(users.map((u) => u.toJson()).toList());
    await prefs.setString(_usersKey, usersStr);

    final existingActiveId = prefs.getString(_activeUserIdKey);
    KvUser? active;
    if (users.isNotEmpty) {
      active = users.firstWhere(
        (u) => u.id == existingActiveId,
        orElse: () => users.first,
      );
      await prefs.setString(_activeUserIdKey, active.id);
    }

    state = AuthState(
      isAuthenticated: true,
      isBiometricVerified: true,
      isLoading: false,
      token: token,
      phoneNumber: phoneNumber,
      users: users,
      activeUser: active,
      tokenGeneratedTime: now,
      prevToken: null,
    );
  }

  Future<void> updateToken(String newToken) async {
    final prefs = await SharedPreferences.getInstance();
    final prev = state.token;
    final now = DateTime.now();

    if (prev != null) {
      await prefs.setString(_prevTokenKey, prev);
    }
    await prefs.setString(_tokenKey, newToken);
    await prefs.setInt(_tokenGenTimeKey, now.millisecondsSinceEpoch);

    state = AuthState(
      isAuthenticated: state.isAuthenticated,
      isBiometricVerified: state.isBiometricVerified,
      isLoading: state.isLoading,
      token: newToken,
      phoneNumber: state.phoneNumber,
      users: state.users,
      activeUser: state.activeUser,
      tokenGeneratedTime: now,
      prevToken: prev,
    );
  }

  Future<void> revertToken() async {
    final prev = state.prevToken;
    if (prev != null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_tokenKey, prev);
      await prefs.remove(_prevTokenKey);

      state = AuthState(
        isAuthenticated: state.isAuthenticated,
        isBiometricVerified: state.isBiometricVerified,
        isLoading: state.isLoading,
        token: prev,
        phoneNumber: state.phoneNumber,
        users: state.users,
        activeUser: state.activeUser,
        tokenGeneratedTime: state.tokenGeneratedTime,
        prevToken: null,
      );
    }
  }

  Future<void> switchUser(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final user = state.users.firstWhere((u) => u.id == userId);
    await prefs.setString(_activeUserIdKey, userId);
    state = AuthState(
      isAuthenticated: state.isAuthenticated,
      isBiometricVerified: state.isBiometricVerified,
      isLoading: state.isLoading,
      token: state.token,
      phoneNumber: state.phoneNumber,
      users: state.users,
      activeUser: user,
      tokenGeneratedTime: state.tokenGeneratedTime,
      prevToken: state.prevToken,
    );
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_phoneKey);
    await prefs.remove(_usersKey);
    await prefs.remove(_activeUserIdKey);
    await prefs.remove(_tokenGenTimeKey);
    await prefs.remove(_prevTokenKey);
    state = const AuthState(isAuthenticated: false, isLoading: false);
  }
}
