import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:kvman/app/app.dart';
import 'package:kvman/features/auth/auth_notifier.dart';
import 'package:kvman/core/utils/logging.dart';
import 'package:shared_preferences/shared_preferences.dart';

final dioProvider = Provider<Dio>((ref) {
  final options = BaseOptions(
    baseUrl: dotenv.get('KV_PORTAL_API_BASE_URI'),
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 10),
  );

  final dio = Dio(options);

  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) async {
        final prefs = await SharedPreferences.getInstance();
        final token = prefs.getString('auth_token');
        if (token != null && token.isNotEmpty) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
      onError: (DioException e, handler) async {
        final dataStr = e.response?.data?.toString() ?? '';
        if (dataStr.contains('Invalid token')) {
          rootScaffoldMessengerKey.currentState?.showSnackBar(
            const SnackBar(content: Text('Session expired. Please login again.')),
          );
          ref.read(authNotifierProvider.notifier).logout();
        } else if (dataStr.contains('no rights')) {
          await ref.read(authNotifierProvider.notifier).revertToken();
        }
        handler.next(e);
      },
      onResponse: (response, handler) async {
        logger.d('Response [${response.statusCode}]: ${response.data}');
        
        final dataStr = response.data?.toString() ?? '';
        
        // 1. Session Invalidation
        if (dataStr.contains('Invalid token')) {
          rootScaffoldMessengerKey.currentState?.showSnackBar(
            const SnackBar(content: Text('Session expired. Please login again.')),
          );
          ref.read(authNotifierProvider.notifier).logout();
          return handler.next(response);
        }

        if (dataStr.contains('no rights')) {
          await ref.read(authNotifierProvider.notifier).revertToken();
        }

        // 2. Token Refreshing
        if (!response.requestOptions.path.contains('/ReGenarateToken')) {
          final authState = ref.read(authNotifierProvider);
          final genTime = authState.tokenGeneratedTime;
          
          if (genTime != null) {
            final ageMinutes = DateTime.now().difference(genTime).inMinutes;
            if (ageMinutes >= 15 && ageMinutes <= 30) {
              final username = authState.activeUser?.userName;
              final currentToken = authState.token;
              
              if (username != null && currentToken != null) {
                try {
                  final refreshDio = Dio(BaseOptions(
                    baseUrl: response.requestOptions.baseUrl,
                    connectTimeout: const Duration(seconds: 10),
                    receiveTimeout: const Duration(seconds: 10),
                  ));
                  
                  final refreshRes = await refreshDio.post(
                    '/ReGenarateToken',
                    data: { 'Username': username },
                    options: Options(
                      headers: { 'Authorization': 'Bearer $currentToken' }
                    ),
                  );
                  
                  if (refreshRes.statusCode == 200 && refreshRes.data != null) {
                    final resData = refreshRes.data;
                    if (resData is Map<String, dynamic> && resData.containsKey('Token')) {
                      String newToken = resData['Token'] as String;
                      if (newToken.endsWith('~0')) {
                        newToken = newToken.substring(0, newToken.length - 2);
                      }
                      if (newToken.isNotEmpty) {
                        await ref.read(authNotifierProvider.notifier).updateToken(newToken);
                      }
                    }
                  }
                } catch (e) {
                  logger.e('Token refresh failed: $e');
                }
              }
            }
          }
        }
        
        handler.next(response);
      },
    ),
  );

  return dio;
});
