/// Typed API exceptions for consistent error handling across the app.
class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final dynamic data;

  const ApiException({
    required this.message,
    this.statusCode,
    this.data,
  });

  bool get isUnauthorized => statusCode == 401;
  bool get isForbidden => statusCode == 403;
  bool get isNotFound => statusCode == 404;
  bool get isServerError => (statusCode ?? 0) >= 500;

  @override
  String toString() => 'ApiException($statusCode): $message';
}

class NetworkException extends ApiException {
  const NetworkException({
    super.message = 'Network error. Please check your connection.',
    super.statusCode = 0,
  });
}

class UnauthorizedException extends ApiException {
  const UnauthorizedException({
    super.message = 'Session expired. Please log in again.',
    super.statusCode = 401,
  });
}

class ServerException extends ApiException {
  const ServerException({
    super.message = 'Something went wrong on our end. Please try again.',
    super.statusCode = 500,
    super.data,
  });
}
