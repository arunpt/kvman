import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kvman/core/api/api_client.dart';
import 'package:kvman/features/notifications/notification_model.dart';

final notificationRepositoryProvider = Provider<NotificationRepository>((ref) {
  return NotificationRepository(ref.watch(dioProvider));
});

final notificationsProvider = FutureProvider.autoDispose<List<AppNotification>>((ref) async {
  final repository = ref.watch(notificationRepositoryProvider);
  return repository.fetchNotifications();
});

class NotificationRepository {
  final Dio _dio;

  NotificationRepository(this._dio);

  Future<List<AppNotification>> fetchNotifications() async {
    final response = await _dio.post('/CustomerNotification');
    
    final data = response.data;
    if (data is! Map<String, dynamic>) {
      throw Exception('Invalid response format');
    }

    final returnCode = data['returnCode'];
    if (returnCode != null && returnCode != 0) {
      throw Exception(data['returnMessage']?.toString() ?? 'Failed to load notifications');
    }

    final list = data['CustomerGetNotification'] as List<dynamic>?;
    if (list == null) return [];

    return list
        .map((e) => AppNotification.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}

