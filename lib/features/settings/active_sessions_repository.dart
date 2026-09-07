import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kvman/core/api/api_client.dart';
import 'package:kvman/features/auth/auth_notifier.dart';
import 'package:kvman/features/settings/active_session_model.dart';

final activeSessionsProvider = FutureProvider.autoDispose<List<ActiveSession>>((
  ref,
) async {
  final dio = ref.watch(dioProvider);
  final authState = ref.watch(authNotifierProvider);
  final username = authState.activeUser?.userName;

  if (username == null) throw Exception('No active user');

  final response = await dio.post(
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
});
