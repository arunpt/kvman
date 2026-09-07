import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kvman/core/api/api_client.dart';
import 'package:kvman/features/auth/auth_notifier.dart';
import 'package:kvman/features/settings/active_session_model.dart';

final activeSessionsRepositoryProvider = Provider<ActiveSessionsRepository>((
  ref,
) {
  return ActiveSessionsRepository(ref.watch(dioProvider));
});

class ActiveSessionsRepository {
  final Dio _dio;

  ActiveSessionsRepository(this._dio);

  Future<List<ActiveSession>> getSessions(String username) async {
    final response = await _dio.post(
      '/getLoginSession',
      data: {"UserId": username, "LoginType": "1"},
      options: Options(extra: {'useSubscriberApi': true}),
    );

    final data = response.data;
    if (data is Map<String, dynamic>) {
      final returnCode = data['returnCode'];
      if (returnCode != 0) {
        throw Exception(
          data['returnMessage']?.toString() ?? 'Failed to fetch sessions',
        );
      }

      final list = data['loginSessionResponseList'] as List<dynamic>? ?? [];
      return list
          .map((e) => ActiveSession.fromJson(e as Map<String, dynamic>))
          .toList();
    }

    throw Exception('Invalid response format');
  }

  Future<void> logoutSession(String sessionId) async {
    final response = await _dio.post(
      '/LogoutSession',
      data: {"SessionId": sessionId},
      options: Options(extra: {'useSubscriberApi': true}),
    );

    final data = response.data;
    if (data is Map<String, dynamic>) {
      final returnCode = data['returnCode'];
      if (returnCode != 0) {
        throw Exception(
          data['returnMessage']?.toString() ?? 'Failed to logout session',
        );
      }
      return;
    }

    throw Exception('Invalid response format');
  }
}

final activeSessionsProvider = FutureProvider.autoDispose<List<ActiveSession>>((
  ref,
) async {
  final authState = ref.watch(authNotifierProvider);
  final username = authState.activeUser?.userName;

  if (username == null) throw Exception('No active user');

  return ref.watch(activeSessionsRepositoryProvider).getSessions(username);
});
