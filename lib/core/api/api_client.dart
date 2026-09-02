import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

final dioProvider = Provider<Dio>((ref) {
  final options = BaseOptions(
    baseUrl: dotenv.get('KV_PORTAL_API_BASE_URI'),
    connectTimeout: Duration(seconds: 10),
    receiveTimeout: Duration(seconds: 10),
  );

  final dio = Dio(options);

  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) async {
        handler.next(options);
      },
      onError: (DioException e, handler) async {},
    ),
  );

  return dio;
});
