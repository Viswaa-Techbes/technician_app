import 'package:flutter/foundation.dart';
import '../common/logger.dart';

class GlobalErrorHandler {
  static void initialize() {
    // Catch Flutter errors
    FlutterError.onError = (details) {
      FlutterError.presentError(details);
      AppLogger.e('Flutter Error', details.exception, details.stack);
    };

    // Catch errors not caught by Flutter
    PlatformDispatcher.instance.onError = (error, stack) {
      AppLogger.e('Platform Error', error, stack);
      return true;
    };
  }
}
