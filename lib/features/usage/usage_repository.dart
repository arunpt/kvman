import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kvman/core/api/api_client.dart';
import 'package:kvman/features/usage/usage_model.dart';

final usageRepositoryProvider = Provider<UsageRepository>((ref) {
  return UsageRepository(ref.watch(dioProvider));
});

class UsageFilterNotifier extends Notifier<DateTime> {
  @override
  DateTime build() {
    final now = DateTime.now();
    return DateTime(now.year, now.month);
  }

  void updateDate(DateTime date) {
    state = date;
  }
}

final usageFilterProvider = NotifierProvider<UsageFilterNotifier, DateTime>(
  UsageFilterNotifier.new,
);

final usageDataProvider = FutureProvider.autoDispose<UsageData>((ref) async {
  final repository = ref.watch(usageRepositoryProvider);
  final filter = ref.watch(usageFilterProvider);
  return repository.fetchUsageData(month: filter.month, year: filter.year);
});

class UsageRepository {
  final Dio _dio;

  UsageRepository(this._dio);

  Future<UsageData> fetchUsageData({required int month, required int year}) async {
    final response = await _dio.post(
      '/SessionList',
      data: {'month': month, 'year': year},
    );
    
    final data = response.data;
    if (data is! Map<String, dynamic>) {
      throw Exception('Invalid response format');
    }

    final returnCode = data['ReturnCode'] ?? data['returnCode'];
    if (returnCode != null && returnCode != 0) {
      throw Exception(data['ReturnMessage']?.toString() ?? 'Failed to load usage data');
    }

    final summary = UsageSummary.fromJson(data);
    
    final list = data['AccountSessionList'] as List<dynamic>?;
    final sessions = list != null 
        ? list.map((e) => SessionItem.fromJson(e as Map<String, dynamic>)).toList()
        : <SessionItem>[];

    return UsageData(summary: summary, sessions: sessions);
  }
}


