import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kvman/core/api/api_client.dart';
import 'package:kvman/features/auth/auth_notifier.dart';
import 'package:kvman/features/network/network_model.dart';

final networkRepositoryProvider = Provider<NetworkRepository>((ref) {
  return NetworkRepository(ref.watch(dioProvider), ref);
});

final opticalParameterProvider = FutureProvider.autoDispose<OpticalParameter?>((
  ref,
) async {
  return ref.watch(networkRepositoryProvider).fetchOpticalParameters();
});

final wanDetailsProvider = FutureProvider.autoDispose<WanDetails?>((ref) async {
  return ref.watch(networkRepositoryProvider).fetchWanDetails();
});

final deviceInfoProvider = FutureProvider.autoDispose<DeviceInfo?>((ref) async {
  return ref.watch(networkRepositoryProvider).fetchDeviceInfo();
});

final wifiParameterProvider = FutureProvider.autoDispose<List<WifiParameter>>((
  ref,
) async {
  return ref.watch(networkRepositoryProvider).fetchWifiParameters();
});

class NetworkRepository {
  final Dio _dio;
  final Ref _ref;

  NetworkRepository(this._dio, this._ref);

  Future<OpticalParameter?> fetchOpticalParameters() async {
    final username = _ref.read(authNotifierProvider).activeUser?.userName;
    if (username == null) throw Exception("User not logged in");

    final response = await _dio.post(
      '/GetOpticalParameter',
      data: {'UserName': username},
    );

    final data = response.data;
    if (data is Map<String, dynamic> && data['data'] != null) {
      final innerData = data['data'];
      if (innerData is Map<String, dynamic>) {
        if (innerData['status'] == false) return null; // Or throw error
        return OpticalParameter.fromJson(innerData);
      }
    }
    return null;
  }

  Future<WanDetails?> fetchWanDetails() async {
    final username = _ref.read(authNotifierProvider).activeUser?.userName;
    if (username == null) throw Exception("User not logged in");

    final response = await _dio.post(
      '/GetWANDetails',
      data: {'UserName': username},
    );

    final data = response.data;
    if (data is Map<String, dynamic> && data['data'] != null) {
      final innerData = data['data'];
      if (innerData is Map<String, dynamic>) {
        return WanDetails.fromJson(innerData);
      }
    }
    return null;
  }

  Future<DeviceInfo?> fetchDeviceInfo() async {
    final username = _ref.read(authNotifierProvider).activeUser?.userName;
    if (username == null) throw Exception("User not logged in");

    final response = await _dio.post(
      '/GetDeviceInfo',
      data: {'UserName': username},
    );

    final data = response.data;
    if (data is Map<String, dynamic> && data['data'] != null) {
      final innerData = data['data'];
      if (innerData is Map<String, dynamic>) {
        return DeviceInfo.fromJson(innerData);
      }
    }
    return null;
  }

  Future<List<WifiParameter>> fetchWifiParameters() async {
    final username = _ref.read(authNotifierProvider).activeUser?.userName;
    if (username == null) throw Exception("User not logged in");

    final response = await _dio.post(
      '/GetWifiParameter',
      data: {'UserName': username},
    );

    final data = response.data;
    List<WifiParameter> parameters = [];

    if (data is Map<String, dynamic> && data['data'] != null) {
      final innerData = data['data'];
      if (innerData is Map<String, dynamic>) {
        innerData.forEach((key, value) {
          if (value is Map<String, dynamic>) {
            parameters.add(WifiParameter.fromJson(key, value));
          }
        });
      }
    }
    return parameters;
  }
}
