import 'dart:async';
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../core/utils/logger.dart';

final secureStorageProvider = Provider((ref) => SecureStorageService());

class SecureStorageService {
  final _storage = const FlutterSecureStorage();
  static const _tokenKey = "techbes_backend_token";
  static const _userKey = "techbes_backend_user";

  Future<void> saveToken(String token) async {
    try {
      appLogger.d("SecureStorage: Saving token.");
      await _storage.write(key: _tokenKey, value: token).timeout(
        const Duration(seconds: 2),
        onTimeout: () => throw TimeoutException('Secure storage write token timed out'),
      );
    } catch (e) {
      appLogger.e("SecureStorage: Error saving token: $e");
      if (e.toString().contains("Keystore") || e.toString().contains("decryption")) {
        appLogger.w("SecureStorage: Keystore corruption suspected. Clearing storage to reset keys.");
        await _handleKeystoreError();
      }
    }
  }

  Future<String?> getToken() async {
    try {
      appLogger.d("SecureStorage: Reading token.");
      return await _storage.read(key: _tokenKey).timeout(
        const Duration(seconds: 2),
        onTimeout: () => throw TimeoutException('Secure storage read token timed out'),
      );
    } catch (e) {
      appLogger.e("SecureStorage: Error reading token: $e");
      if (e.toString().contains("Keystore") || e.toString().contains("decryption")) {
        appLogger.w("SecureStorage: Keystore corruption suspected. Clearing storage to reset keys.");
        await _handleKeystoreError();
      }
      return null;
    }
  }

  Future<void> deleteToken() async {
    try {
      appLogger.d("SecureStorage: Deleting token.");
      await _storage.delete(key: _tokenKey).timeout(
        const Duration(seconds: 2),
        onTimeout: () => throw TimeoutException('Secure storage delete token timed out'),
      );
    } catch (e) {
      appLogger.e("SecureStorage: Error deleting token: $e");
    }
  }

  Future<void> saveUser(Map<String, dynamic> user) async {
    try {
      appLogger.d("SecureStorage: Saving user info.");
      final userStr = json.encode(user);
      await _storage.write(key: _userKey, value: userStr).timeout(
        const Duration(seconds: 2),
        onTimeout: () => throw TimeoutException('Secure storage write user timed out'),
      );
    } catch (e) {
      appLogger.e("SecureStorage: Error saving user: $e");
      if (e.toString().contains("Keystore") || e.toString().contains("decryption")) {
        appLogger.w("SecureStorage: Keystore corruption suspected. Clearing storage to reset keys.");
        await _handleKeystoreError();
      }
    }
  }

  Future<Map<String, dynamic>?> getUser() async {
    try {
      appLogger.d("SecureStorage: Reading user info.");
      final userStr = await _storage.read(key: _userKey).timeout(
        const Duration(seconds: 2),
        onTimeout: () => throw TimeoutException('Secure storage read user timed out'),
      );
      if (userStr != null) {
        return json.decode(userStr) as Map<String, dynamic>;
      }
    } catch (e) {
      appLogger.e("SecureStorage: Error reading user: $e");
      if (e.toString().contains("Keystore") || e.toString().contains("decryption")) {
        appLogger.w("SecureStorage: Keystore corruption suspected. Clearing storage to reset keys.");
        await _handleKeystoreError();
      }
    }
    return null;
  }

  Future<void> deleteUser() async {
    try {
      appLogger.d("SecureStorage: Deleting user info.");
      await _storage.delete(key: _userKey).timeout(
        const Duration(seconds: 2),
        onTimeout: () => throw TimeoutException('Secure storage delete user timed out'),
      );
    } catch (e) {
      appLogger.e("SecureStorage: Error deleting user: $e");
    }
  }

  Future<void> _handleKeystoreError() async {
    try {
      await _storage.deleteAll().timeout(
        const Duration(seconds: 2),
        onTimeout: () => throw TimeoutException('Secure storage deleteAll timed out'),
      );
      appLogger.i("SecureStorage: Successfully reset secure storage after keystore error.");
    } catch (e) {
      appLogger.e("SecureStorage: Critical error clearing storage: $e");
    }
  }
}
