import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import '../../../../core/security/rbac_constants.dart';
import '../../../../core/network/api_config.dart';
import '../../domain/entities/user_session.dart';

class AuthNotifier extends StateNotifier<UserSession?> {
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
        final Map<String, dynamic> map = jsonDecode(saved);
        state = UserSession.fromMap(map);
      }
    } catch (e) {
      debugPrint("Auto-login error: $e");
    }
  }

  Future<UserSession> login({
    required String email,
    required String password,
  }) async {
    final res = await http.post(
      Uri.parse("$_baseUrl/auth/login"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"email": email, "password": password}),
    );
    
    final apiResponse = jsonDecode(res.body);
    
    if (apiResponse['success'] != true) {
      throw Exception(apiResponse['message'] ?? 'Login failed');
    }
    
    final backendData = apiResponse['data'] ?? {};
    final backendUser = backendData['user'] ?? {};
    final token = backendData['token'] ?? '';

    final session = UserSession(
      id: backendUser['id'] ?? backendUser['_id'] ?? '',
      name: backendUser['name'] ?? 'User',
      email: backendUser['email'] ?? email,
      role: Role.values.firstWhere(
        (e) => e.name == (backendUser['role'] ?? 'technician'),
        orElse: () => Role.technician,
      ),
      token: token,
    );

    await _persistSession(session);
    state = session;
    return session;
  }

  Future<UserSession> register({
    required String name,
    required String email,
    required String password,
    required Role role,
  }) async {
    final res = await http.post(
      Uri.parse("$_baseUrl/auth/register"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        'name': name.trim(),
        'email': email.trim(),
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

    final session = UserSession(
      id: backendUser['id'] ?? backendUser['_id'] ?? '',
      name: name.trim(),
      email: email.trim(),
      role: role,
      token: token,
    );

    await _persistSession(session);
    state = session;
    return session;
  }

  Future<void> _persistSession(UserSession session) async {
    await _storage.write(key: _sessionKey, value: jsonEncode(session.toMap()));
  }

  Future<void> logout() async {
    await _storage.delete(key: _sessionKey);
    state = null;
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, UserSession?>((ref) {
  return AuthNotifier();
});
