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

  Future<String?> regenerateToken(String baseUrl) async {
    final authState = ref.read(authNotifierProvider);
    final username = authState.activeUser?.userName;
    final currentToken = authState.token;

    if (username == null || currentToken == null) return null;

    try {
      final refreshDio = Dio(
        BaseOptions(
          baseUrl: baseUrl,
          connectTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 10),
        ),
      );

      final refreshRes = await refreshDio.post(
        '/ReGenarateToken',
        data: {'Username': username},
        options: Options(headers: {'Authorization': 'Bearer $currentToken'}),
      );

      if (refreshRes.statusCode == 200 && refreshRes.data != null) {
        final resData = refreshRes.data;
        if (resData is Map<String, dynamic> && resData.containsKey('Token')) {
          String newToken = resData['Token'] as String;
          newToken = newToken.substring(0, newToken.length - 2);
          if (newToken.isNotEmpty && !newToken.contains('Invalid')) {
            await ref.read(authNotifierProvider.notifier).updateToken(newToken);
            return newToken;
          }
        }
      }
    } catch (e) {
      logger.e('Token refresh failed: $e');
    }
    return null;
  }

  Future<void> handleInvalidToken(
    RequestOptions requestOptions,
    dynamic originalErrorOrResponse,
    ErrorInterceptorHandler? errorHandler,
    ResponseInterceptorHandler? responseHandler,
  ) async {
    // 1. Prevent infinite refresh loop on the regenerate endpoint itself
    if (requestOptions.path.contains('/ReGenarateToken') ||
        requestOptions.extra['isRetry'] == true) {
      rootScaffoldMessengerKey.currentState?.showSnackBar(
        const SnackBar(content: Text('Session expired. Please login again.')),
      );
      ref.read(authNotifierProvider.notifier).logout();
      if (errorHandler != null) {
        errorHandler.next(originalErrorOrResponse as DioException);
      }
      if (responseHandler != null) {
        responseHandler.next(originalErrorOrResponse as Response);
      }
      return;
    }

    // 2. Try regeneration
    bool refreshSuccess = false;
    final newToken = await regenerateToken(requestOptions.baseUrl);

    if (newToken != null) {
      // 3. Retry original request with new token
      final newHeaders = Map<String, dynamic>.from(requestOptions.headers);
      newHeaders['Authorization'] = 'Bearer $newToken';

      final newExtra = Map<String, dynamic>.from(requestOptions.extra);
      newExtra['isRetry'] = true;

      final cloneReq = requestOptions.copyWith(
        headers: newHeaders,
        extra: newExtra,
      );

      final retryDio = Dio(BaseOptions(baseUrl: requestOptions.baseUrl));
      try {
        final retryRes = await retryDio.fetch(cloneReq);

        // If the retry STILL returns Invalid token, it's a hard failure
        final retryDataStr = retryRes.data?.toString() ?? '';
        if (!retryDataStr.contains('Invalid token')) {
          refreshSuccess = true;
          if (responseHandler != null) return responseHandler.resolve(retryRes);
          if (errorHandler != null) return errorHandler.resolve(retryRes);
        }
      } catch (retryErr) {
        logger.e('Retry request failed: $retryErr');
      }
    }

    // 4. If refresh failed or retry failed, logout
    if (!refreshSuccess) {
      rootScaffoldMessengerKey.currentState?.showSnackBar(
        const SnackBar(content: Text('Session expired. Please login again.')),
      );
      ref.read(authNotifierProvider.notifier).logout();
      if (errorHandler != null) {
        errorHandler.next(originalErrorOrResponse as DioException);
      }
      if (responseHandler != null) {
        responseHandler.next(originalErrorOrResponse as Response);
      }
    }
  }

  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) async {
        // Pre-emptive explicit refresh if token is older than 15 minutes
        if (!options.path.contains('/ReGenarateToken')) {
          final authState = ref.read(authNotifierProvider);
          final genTime = authState.tokenGeneratedTime;
          if (genTime != null &&
              DateTime.now().difference(genTime).inMinutes >= 15) {
            final newToken = await regenerateToken(options.baseUrl);
            if (newToken != null) {
              // Update headers to use the freshly generated token
              options.headers['Authorization'] = 'Bearer $newToken';
              return handler.next(options);
            }
          }
        }

        final prefs = await SharedPreferences.getInstance();
        final token = prefs.getString('auth_token');
        if (token != null && token.isNotEmpty) {
          // Only set if not already set by pre-emptive refresh
          options.headers['Authorization'] ??= 'Bearer $token';
        }
        handler.next(options);
      },
      onError: (DioException e, handler) async {
        final dataStr = e.response?.data?.toString() ?? '';
        if (dataStr.contains('Invalid token')) {
          await handleInvalidToken(e.requestOptions, e, handler, null);
          return;
        } else if (dataStr.contains('no rights')) {
          await ref.read(authNotifierProvider.notifier).revertToken();
        }
        handler.next(e);
      },
      onResponse: (response, handler) async {
        logger.d('Response [${response.statusCode}]: ${response.data}');

        final dataStr = response.data?.toString() ?? '';

        if (dataStr.contains('Invalid token')) {
          await handleInvalidToken(
            response.requestOptions,
            response,
            null,
            handler,
          );
          return;
        }

        if (dataStr.contains('no rights')) {
          await ref.read(authNotifierProvider.notifier).revertToken();
        }

        handler.next(response);
      },
    ),
  );

  return dio;
});
