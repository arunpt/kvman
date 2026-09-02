import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kvman/core/api/api_client.dart';
import 'package:kvman/features/auth/auth_notifier.dart';
import 'package:kvman/features/profile/customer_detail.dart';

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  return ProfileRepository(ref.watch(dioProvider));
});

final customerDetailProvider = FutureProvider.autoDispose<CustomerDetail>((ref) {
  // Re-fetch if auth state (like the active user token) changes
  ref.watch(authNotifierProvider);
  return ref.read(profileRepositoryProvider).fetchCustomerDetail();
});

class ProfileRepository {
  final Dio _dio;

  ProfileRepository(this._dio);

  Future<CustomerDetail> fetchCustomerDetail() async {
    final response = await _dio.post('/CustomerDetail');
    final data = response.data;
    
    if (data is! Map<String, dynamic>) {
      throw Exception('Invalid response format');
    }

    final returnCode = data['ReturnCode'];
    if (returnCode != 0) {
      throw Exception(data['ReturnMessage']?.toString() ?? 'Failed to fetch customer details');
    }

    final customerDetailJson = data['CustomerDetail'];
    if (customerDetailJson == null || customerDetailJson is! Map<String, dynamic>) {
      throw Exception('Customer details not found in response');
    }

    return CustomerDetail.fromJson(customerDetailJson);
  }
}

