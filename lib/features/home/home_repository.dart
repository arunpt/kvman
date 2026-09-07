import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kvman/core/api/api_client.dart';
import 'package:kvman/features/home/subscriber_plan.dart';
import 'package:kvman/features/home/session_model.dart';

final homeRepositoryProvider = Provider<HomeRepository>((ref) {
  return HomeRepository(ref.watch(dioProvider));
});

final currentPlanProvider = FutureProvider.autoDispose<SubscriberPlanResponse>((
  ref,
) async {
  return ref.watch(homeRepositoryProvider).fetchPlanList();
});

final sessionListProvider = FutureProvider.autoDispose<SessionListResponse>((
  ref,
) async {
  return ref.watch(homeRepositoryProvider).fetchSessionList();
});

class HomeRepository {
  final Dio _dio;

  HomeRepository(this._dio);

  Future<SubscriberPlanResponse> fetchPlanList() async {
    final response = await _dio.post('/SubscriberPlanListV4');

    final data = response.data;
    if (data is Map<String, dynamic>) {
      final returnCode = data['returnCode'] ?? data['ReturnCode'];
      if (returnCode != null && returnCode != 0) {
        throw Exception(
          data['returnMessage']?.toString() ?? 'Failed to load plans',
        );
      }
      return SubscriberPlanResponse.fromJson(data);
    }

    throw Exception('Invalid response format');
  }

  Future<SessionListResponse> fetchSessionList() async {
    final response = await _dio.post('/SessionList');

    final data = response.data;
    if (data is Map<String, dynamic>) {
      final returnCode = data['ReturnCode'];
      if (returnCode != null && returnCode != 0) {
        throw Exception(
          data['ReturnMessage']?.toString() ?? 'Failed to load session data',
        );
      }
      return SessionListResponse.fromJson(data);
    }

    throw Exception('Invalid response format');
  }
}
