import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kvman/core/api/api_client.dart';
import 'package:kvman/features/auth/otp_response.dart';

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
    return data['Token'] as String;
  }
}

class AuthException implements Exception {
  final String message;
  const AuthException(this.message);

  @override
  String toString() => message;
}
