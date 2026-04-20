import 'package:logger/logger.dart';
import 'package:flutter/foundation.dart';

class AppLogger {
  static final Logger _logger = Logger(
    printer: PrettyPrinter(
      methodCount: 0,
      errorMethodCount: 5,
      lineLength: 80,
      colors: true,
      printEmojis: true,
      dateTimeFormat: DateTimeFormat.none,
    ),
  );

  static void d(String message) {
    if (kDebugMode) _logger.d(message);
  }

  static void i(String message) {
    if (kDebugMode) _logger.i(message);
  }

  static void w(String message) {
    if (kDebugMode) _logger.w(message);
  }

  static void e(String message, [dynamic error, StackTrace? stackTrace]) {
    _logger.e(message, error: error, stackTrace: stackTrace);
  }
}
