import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import '../../../../core/security/rbac_constants.dart';
import '../../../../core/network/api_config.dart';
import '../../../../models.dart';

class AuthNotifier extends StateNotifier<User?> {
  final _storage = const FlutterSecureStorage();
  static const String _sessionKey = 'user_session';
  final String _baseUrl = ApiConfig.baseUrl;

  AuthNotifier() : super(null) {
    _tryAutoLogin();
  }

  Future<void> _tryAutoLogin() async {
    try {
      final saved = await _storage.read(key: _sessionKey);
      if (saved != null) {
        // Daily Session Reset Check
        final today = DateTime.now().toIso8601String().split('T')[0];
        final lastLoginDate = await _storage.read(key: 'last_login_date');
        
        if (lastLoginDate != today) {
          debugPrint("Session expired (new day). Logging out.");
          await logout();
          return;
        }

        final Map<String, dynamic> map = jsonDecode(saved);
        state = User.fromMap(map);
      }
    } catch (e) {
      debugPrint("Auto-login error: $e");
    }
  }

  Future<User> login({
    required String mobileNumber,
    required String password,
  }) async {
    final res = await http.post(
      Uri.parse("$_baseUrl/auth/login"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"mobileNumber": mobileNumber.trim(), "password": password}),
    );
    
    final apiResponse = jsonDecode(res.body);
    
    if (apiResponse['success'] != true) {
      throw Exception(apiResponse['message'] ?? 'Login failed');
    }
    
    final backendData = apiResponse['data'] ?? {};
    final backendUser = backendData['user'] ?? {};
    final token = backendData['token'] ?? '';

    // Save Today's Date
    final today = DateTime.now().toIso8601String().split('T')[0];
    await _storage.write(key: 'last_login_date', value: today);

    final session = User(
      id: backendUser['id'] ?? backendUser['_id'] ?? '',
      name: backendUser['name'] ?? 'User',
      mobileNumber: backendUser['mobileNumber'] ?? mobileNumber.trim(),
      email: backendUser['email'] ?? '',
      role: Role.values.firstWhere(
        (e) => e.name == (backendUser['role'] ?? 'technician'),
        orElse: () => Role.technician,
      ),
      token: token,
    );

    await _persistSession(session);
    state = session;
    
    // Auto-mark attendance
    try {
      if (session.role == Role.technician) {
        await http.post(
          Uri.parse("$_baseUrl/api/v2/attendance/mark-login"),
          headers: {"Content-Type": "application/json", "Authorization": "Bearer $token"},
        );
      }
    } catch (e) {
      debugPrint("Failed to mark attendance on login: $e");
    }
    
    return session;
  }

  Future<User> register({
    String name = '',
    required String mobileNumber,
    required String password,
    required Role role,
  }) async {
    final res = await http.post(
      Uri.parse("$_baseUrl/auth/register"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        'name': name.trim(),
        'mobileNumber': mobileNumber.trim(),
        'password': password,
        'role': role.name,
      }),
    );

    final apiResponse = jsonDecode(res.body);

    if (apiResponse['success'] != true) {
      throw Exception(apiResponse['message'] ?? 'Registration failed');
    }

    final backendData = apiResponse['data'] ?? {};
    final backendUser = backendData['user'] ?? {};
    final token = backendData['token'] ?? '';

    final session = User(
      id: backendUser['id'] ?? backendUser['_id'] ?? '',
      name: (backendUser['name'] ?? name).toString(),
      mobileNumber: backendUser['mobileNumber'] ?? mobileNumber.trim(),
      email: backendUser['email'] ?? '',
      role: role,
      token: token,
    );

    await _persistSession(session);
    state = session;
    return session;
  }

  Future<void> _persistSession(User session) async {
    await _storage.write(key: _sessionKey, value: jsonEncode(session.toMap()));
  }

  Future<void> logout() async {
    try {
      if (state != null && state!.role == Role.technician) {
        await http.post(
          Uri.parse("$_baseUrl/api/v2/attendance/mark-logout"),
          headers: {"Content-Type": "application/json", "Authorization": "Bearer ${state!.token}"},
        );
      }
    } catch (e) {
      debugPrint("Failed to mark logout: $e");
    }
    await _storage.delete(key: _sessionKey);
    state = null;
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, User?>((ref) {
  return AuthNotifier();
});
