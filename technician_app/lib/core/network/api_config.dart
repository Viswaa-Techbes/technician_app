import 'package:flutter/foundation.dart';

class ApiConfig {
  const ApiConfig._();

  static const String _dartDefineBaseUrl =
      String.fromEnvironment('API_BASE_URL', defaultValue: '');

  static String get baseUrl {
    if (_dartDefineBaseUrl.isNotEmpty) {
      return _dartDefineBaseUrl;
    }

    if (kIsWeb) {
      return 'http://localhost:5000';
    }

    // New base URL provided by user
    return 'http://10.246.194.196:5000';
  }
}

