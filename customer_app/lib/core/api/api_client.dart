import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import 'package:customer_app/core/config/env_config.dart';
import 'package:customer_app/core/storage/secure_storage.dart';
import 'package:customer_app/core/api/api_exceptions.dart';

/// Singleton Dio-based API client with JWT interceptor.
///
/// Mirrors the web app's `apiClient` + `authHeaders()` pattern from
/// `core/api/api-client.ts` and `lib/cctv-api.ts`.
class ApiClient {
  static ApiClient? _instance;
  late final Dio _dio;

  ApiClient._() {
    _dio = Dio(
      BaseOptions(
        baseUrl: EnvConfig.apiBaseUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    // ── JWT Interceptor ────────────────────────────────────────────────
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await SecureStorage.getToken();
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
        onError: (error, handler) async {
          if (error.response?.statusCode == 401) {
            await SecureStorage.clearAll();
            // The auth provider will listen and redirect to login
          }
          return handler.next(error);
        },
      ),
    );

    // ── Logging (debug only) ───────────────────────────────────────────
    if (kDebugMode) {
      _dio.interceptors.add(
        LogInterceptor(
          requestBody: true,
          responseBody: true,
          logPrint: (obj) => debugPrint(obj.toString()),
        ),
      );
    }
  }

  static ApiClient get instance {
    _instance ??= ApiClient._();
    return _instance!;
  }

  Dio get dio => _dio;

  // ── Convenience methods ──────────────────────────────────────────────

  Future<T> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      final response = await _dio.get<T>(
        path,
        queryParameters: queryParameters,
      );
      return response.data as T;
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<T> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      final response = await _dio.post<T>(
        path,
        data: data,
        queryParameters: queryParameters,
      );
      return response.data as T;
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<T> put<T>(
    String path, {
    dynamic data,
  }) async {
    try {
      final response = await _dio.put<T>(path, data: data);
      return response.data as T;
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<T> delete<T>(String path) async {
    try {
      final response = await _dio.delete<T>(path);
      return response.data as T;
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  // ── Error mapping ───────────────────────────────────────────────────

  ApiException _handleDioError(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.connectionError:
        return const NetworkException();

      case DioExceptionType.badResponse:
        final statusCode = e.response?.statusCode ?? 0;
        final data = e.response?.data;
        final message = data is Map
            ? (data['message'] as String? ?? 'Request failed.')
            : 'Request failed.';

        if (statusCode == 401) {
          return UnauthorizedException(message: message);
        }
        if (statusCode >= 500) {
          return ServerException(message: message, data: data);
        }
        return ApiException(
          message: message,
          statusCode: statusCode,
          data: data,
        );

      default:
        return ApiException(
          message: e.message ?? 'Something went wrong.',
          statusCode: 0,
        );
    }
  }
}
