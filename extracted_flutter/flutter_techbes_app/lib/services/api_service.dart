import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();

  factory ApiService() {
    return _instance;
  }

  ApiService._internal();

  String? _authToken;
  late SharedPreferences _prefs;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    _authToken = _prefs.getString('auth_token');
  }

  Future<void> setAuthToken(String token) async {
    _authToken = token;
    await _prefs.setString('auth_token', token);
  }

  String? getAuthToken() => _authToken;

  Future<void> clearAuthToken() async {
    _authToken = null;
    await _prefs.remove('auth_token');
  }

  Map<String, String> _getHeaders({bool includeAuth = true}) {
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    if (includeAuth && _authToken != null) {
      headers['Authorization'] = 'Bearer $_authToken';
    }

    return headers;
  }

  Future<Map<String, dynamic>> get(
    String endpoint, {
    bool includeAuth = true,
  }) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}$endpoint'),
        headers: _getHeaders(includeAuth: includeAuth),
      ).timeout(
        const Duration(milliseconds: ApiConfig.receiveTimeout),
      );

      return _handleResponse(response);
    } catch (e) {
      return _handleError(e);
    }
  }

  Future<Map<String, dynamic>> post(
    String endpoint,
    Map<String, dynamic> body, {
    bool includeAuth = true,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}$endpoint'),
        headers: _getHeaders(includeAuth: includeAuth),
        body: jsonEncode(body),
      ).timeout(
        const Duration(milliseconds: ApiConfig.receiveTimeout),
      );

      return _handleResponse(response);
    } catch (e) {
      return _handleError(e);
    }
  }

  Future<Map<String, dynamic>> put(
    String endpoint,
    Map<String, dynamic> body, {
    bool includeAuth = true,
  }) async {
    try {
      final response = await http.put(
        Uri.parse('${ApiConfig.baseUrl}$endpoint'),
        headers: _getHeaders(includeAuth: includeAuth),
        body: jsonEncode(body),
      ).timeout(
        const Duration(milliseconds: ApiConfig.receiveTimeout),
      );

      return _handleResponse(response);
    } catch (e) {
      return _handleError(e);
    }
  }

  Future<Map<String, dynamic>> delete(
    String endpoint, {
    bool includeAuth = true,
  }) async {
    try {
      final response = await http.delete(
        Uri.parse('${ApiConfig.baseUrl}$endpoint'),
        headers: _getHeaders(includeAuth: includeAuth),
      ).timeout(
        const Duration(milliseconds: ApiConfig.receiveTimeout),
      );

      return _handleResponse(response);
    } catch (e) {
      return _handleError(e);
    }
  }

  Map<String, dynamic> _handleResponse(http.Response response) {
    try {
      final body = jsonDecode(response.body);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return {
          'success': true,
          'status': response.statusCode,
          'data': body,
        };
      } else if (response.statusCode == 401) {
        // Unauthorized - clear token
        clearAuthToken();
        return {
          'success': false,
          'status': response.statusCode,
          'message': body['message'] ?? 'Unauthorized. Please login again.',
          'data': null,
        };
      } else {
        return {
          'success': false,
          'status': response.statusCode,
          'message': body['message'] ?? 'An error occurred',
          'data': body,
        };
      }
    } catch (e) {
      return {
        'success': false,
        'status': response.statusCode,
        'message': 'Failed to parse response',
        'error': e.toString(),
      };
    }
  }

  Map<String, dynamic> _handleError(dynamic error) {
    return {
      'success': false,
      'status': 0,
      'message': error.toString().contains('TimeoutException')
          ? 'Request timeout. Please check your internet connection.'
          : 'Network error. Please try again.',
      'error': error.toString(),
    };
  }
}
