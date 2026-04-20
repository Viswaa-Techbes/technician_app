import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/secure_storage_service.dart';
import '../common/logger.dart';
import 'api_config.dart';

final dioProvider = Provider<Dio>((ref) {
  final dio = Dio(
    BaseOptions(
      baseUrl: ApiConfig.baseUrl,
      connectTimeout: const Duration(milliseconds: AppConstants.connectTimeout),
      receiveTimeout: const Duration(milliseconds: AppConstants.receiveTimeout),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ),
  );

  dio.interceptors.add(InterceptorsWrapper(
    onRequest: (options, handler) async {
      final token = await ref.read(secureStorageProvider).getToken();
      if (token != null) {
        options.headers['Authorization'] = 'Bearer $token';
      }
      AppLogger.d('REQUEST[${options.method}] => PATH: ${options.path}');
      return handler.next(options);
    },
    onResponse: (response, handler) {
      AppLogger.d('RESPONSE[${response.statusCode}] => PATH: ${response.requestOptions.path}');
      return handler.next(response);
    },
    onError: (DioException e, handler) async {
      AppLogger.e('ERROR[${e.response?.statusCode}] => PATH: ${e.requestOptions.path}', e.error, e.stackTrace);
      
      // Retry logic for connection errors
      if (e.type == DioExceptionType.connectionError && e.requestOptions.extra['retry'] != true) {
        e.requestOptions.extra['retry'] = true;
        return handler.resolve(await dio.fetch(e.requestOptions));
      }
      
      return handler.next(e);
    },
  ));

  return dio;
});

class ApiService {
  final Dio _dio;

  ApiService(this._dio);

  Future<Response> get(String path, {Map<String, dynamic>? queryParameters}) async {
    try {
      return await _dio.get(path, queryParameters: queryParameters);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Response> post(String path, {dynamic data}) async {
    try {
      return await _dio.post(path, data: data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Response> patch(String path, {dynamic data}) async {
    try {
      return await _dio.patch(path, data: data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Exception _handleError(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return Exception('Connection timed out. Please check your internet.');
      case DioExceptionType.badResponse:
        final message = e.response?.data?['message'] ?? 'Server error occurred.';
        return Exception(message);
      case DioExceptionType.connectionError:
        return Exception('No internet connection.');
      default:
        return Exception('Something went wrong. Please try again.');
    }
  }
}

final apiServiceProvider = Provider((ref) => ApiService(ref.watch(dioProvider)));
