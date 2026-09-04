import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kvman/core/api/api_client.dart';
import 'package:kvman/features/auth/otp_response.dart';
import 'package:kvman/features/auth/kv_user.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(ref.watch(dioProvider));
});

class AuthRepository {
  final Dio _dio;

  AuthRepository(this._dio);

  Future<OtpResponse> generateOtp(String mobileNo) async {
    final response = await _dio.post(
      '/OtpGenerate',
      data: {'MobileNo': mobileNo},
    );
    return OtpResponse.fromJson(response.data as Map<String, dynamic>);
  }

  Future<String> verifyOtp({
    required String mobileNumber,
    required String otp,
  }) async {
    final response = await _dio.post(
      '/token',
      data: {
        'LoginType': 'Customer',
        'LoginWithOTP': 'true',
        'MobileNumber': mobileNumber,
        'OTP': otp,
        'SourceType': '606',
        'IsLeaseLinePortal': 'false',
      },
    );
    final data = response.data;
    if (data is! Map<String, dynamic>) {
      throw AuthException(data.toString().replaceAll('"', ''));
    }

    String token = data['Token'] as String;
    if (token.endsWith('~0')) {
      token = token.substring(0, token.length - 2);
    }
    return token;
  }

  Future<List<KvUser>> fetchUsersList(String mobileNumber) async {
    final response = await _dio.post(
      '/UsersList',
      data: {
        'UserListParameter': {'Mobile': mobileNumber, 'Type': 'Customer'},
      },
    );

    final data = response.data;
    if (data is! Map<String, dynamic>) {
      throw const AuthException("Failed to fetch users");
    }

    final returnCode = data['returnCode'];
    if (returnCode != 0) {
      throw AuthException(
        data['returnMessage']?.toString() ?? "Failed to fetch users",
      );
    }

    final details = data['UserListDetails'] as List<dynamic>?;
    if (details == null || details.isEmpty) return [];

    return details
        .map((e) => KvUser.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> forgotPassword(String username) async {
    final response = await _dio.post(
      '/ForgotPassword',
      data: {
        'loginType': 'Customer',
        'userId': username,
        'Alias': '',
      },
    );

    final data = response.data;
    if (data is Map<String, dynamic>) {
      final returnCode = data['ReturnCode'] ?? data['returnCode'];
      if (returnCode != null && returnCode != 0) {
        throw AuthException(data['ReturnMessage']?.toString() ?? 'Failed to request password');
      }
    }
  }
}

class AuthException implements Exception {
  final String message;
  const AuthException(this.message);

  @override
  String toString() => message;
}
