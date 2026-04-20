import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SecureStorageService {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  static const String _tokenKey = 'auth_token';
  static const String _userRoleKey = 'user_role';

  Future<void> saveToken(String token) async {
    await _storage.write(key: _tokenKey, value: token);
  }

  Future<String?> getToken() async {
    return await _storage.read(key: _tokenKey);
  }

  Future<void> saveRole(String role) async {
    await _storage.write(key: _userRoleKey, value: role);
  }

  Future<String?> getRole() async {
    return await _storage.read(key: _userRoleKey);
  }

  Future<void> saveLoginDate(String date) async {
    await _storage.write(key: 'last_login_date', value: date);
  }

  Future<String?> getLoginDate() async {
    return await _storage.read(key: 'last_login_date');
  }

  Future<void> clearAll() async {
    await _storage.deleteAll();
  }
}

final secureStorageProvider = Provider((ref) => SecureStorageService());
