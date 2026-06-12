import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorage {
  static const _instance = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  static const _tokenKey = 'techbes_auth_token';
  static const _refreshTokenKey = 'techbes_refresh_token';

  static Future<void> saveToken(String token) async {
    await _instance.write(key: _tokenKey, value: token);
  }

  static Future<String?> getToken() async {
    return _instance.read(key: _tokenKey);
  }

  static Future<void> deleteToken() async {
    await _instance.delete(key: _tokenKey);
  }

  static Future<void> saveRefreshToken(String token) async {
    await _instance.write(key: _refreshTokenKey, value: token);
  }

  static Future<String?> getRefreshToken() async {
    return _instance.read(key: _refreshTokenKey);
  }

  static Future<void> clearAll() async {
    await _instance.deleteAll();
  }
}
