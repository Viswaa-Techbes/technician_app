import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';
import '../models/models.dart';
import 'api_service.dart';

class AuthService {
  final ApiService _apiService = ApiService();

  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await _apiService.post(
        ApiConfig.login,
        {
          'email': email,
          'password': password,
        },
        includeAuth: false,
      );

      if (response['success']) {
        final data = response['data'];
        final token = data['token'] ?? data['data']?['token'];
        if (token != null) {
          await _apiService.setAuthToken(token);
          return {
            'success': true,
            'message': 'Login successful',
            'user': data['user'] ?? data['data']?['user'],
            'token': token,
          };
        }
      }

      return {
        'success': false,
        'message': response['message'] ?? 'Login failed',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'An error occurred during login: ${e.toString()}',
      };
    }
  }

  Future<Map<String, dynamic>> register(
    String name,
    String email,
    String password,
    String phone,
  ) async {
    try {
      final response = await _apiService.post(
        ApiConfig.register,
        {
          'name': name,
          'email': email,
          'password': password,
          'phone': phone,
        },
        includeAuth: false,
      );

      if (response['success']) {
        final token = response['data']['token'] ?? response['data']['data']?['token'];
        if (token != null) {
          await _apiService.setAuthToken(token);
          return {
            'success': true,
            'message': 'Registration successful',
            'user': response['data']['user'] ?? response['data']['data']?['user'],
            'token': token,
          };
        }
      }

      return {
        'success': false,
        'message': response['message'] ?? 'Registration failed',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'An error occurred during registration: ${e.toString()}',
      };
    }
  }

  Future<Map<String, dynamic>> logout() async {
    try {
      await _apiService.post(ApiConfig.logout, {});
      await _apiService.clearAuthToken();
      return {
        'success': true,
        'message': 'Logged out successfully',
      };
    } catch (e) {
      // Even if logout fails, clear local token
      await _apiService.clearAuthToken();
      return {
        'success': true,
        'message': 'Logged out',
      };
    }
  }

  Future<Map<String, dynamic>> getSession() async {
    try {
      final response = await _apiService.get(
        ApiConfig.session,
        includeAuth: true,
      );

      if (response['success']) {
        return {
          'success': true,
          'user': response['data']['user'] ?? response['data']['data']?['user'],
        };
      }

      return {
        'success': false,
        'message': response['message'] ?? 'Failed to get session',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'An error occurred: ${e.toString()}',
      };
    }
  }

  String? getStoredToken() {
    return _apiService.getAuthToken();
  }

  bool isLoggedIn() {
    return _apiService.getAuthToken() != null;
  }
}
