import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/network/api_config.dart';
import '../core/network/dio_client.dart';
import '../services/secure_storage_service.dart';

final authRepositoryProvider = Provider((ref) => AuthRepository(
      ref.watch(dioClientProvider),
      ref.watch(secureStorageProvider),
    ));

class AuthRepository {
  final DioClient _dioClient;
  final SecureStorageService storage;

  AuthRepository(this._dioClient, this.storage);

  Future<Map<String, dynamic>> login(String identifier, String password) async {
    final clean = identifier.trim();
    final response = await _dioClient.post(ApiConfig.login, data: {
      'email': clean,
      'mobileNumber': clean,
      'password': password,
    });
    final data = response.data;
    if (data['token'] != null) {
      await storage.saveToken(data['token']);
    }
    if (data['user'] != null) {
      await storage.saveUser(data['user']);
    }
    return data;
  }

  Future<Map<String, dynamic>> activateResident({
    required String phone,
    required String activationCode,
    required String password,
  }) async {
    final response = await _dioClient.post(ApiConfig.residentActivate, data: {
      'phone': phone.trim(),
      'activationCode': activationCode.trim(),
      'password': password,
    });
    final data = response.data;
    final token = data['token'] ?? data['data']?['token'];
    final user = data['user'] ?? data['data']?['user'];
    if (token != null) {
      await storage.saveToken(token);
    }
    if (user != null) {
      await storage.saveUser(user);
    }
    return data;
  }

  Future<Map<String, dynamic>> sendOtp(String email) async {
    final response = await _dioClient.post(ApiConfig.sendOtp, data: {
      'email': email.trim().toLowerCase(),
    });
    return response.data;
  }

  Future<Map<String, dynamic>> verifyOtp(String email, String otp) async {
    final response = await _dioClient.post(ApiConfig.verifyOtp, data: {
      'email': email.trim().toLowerCase(),
      'otp': otp.trim(),
    });
    return response.data;
  }

  Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String password,
    required String phone,
    required String emailVerificationToken,
  }) async {
    final response = await _dioClient.post(ApiConfig.register, data: {
      'name': name.trim(),
      'email': email.trim().toLowerCase(),
      'password': password,
      'phone': phone.trim(),
      'mobileNumber': phone.trim(),
      'emailVerificationToken': emailVerificationToken,
    });
    final data = response.data;
    if (data['token'] != null) {
      await storage.saveToken(data['token']);
    }
    if (data['user'] != null) {
      await storage.saveUser(data['user']);
    }
    return data;
  }

  Future<Map<String, dynamic>?> getSession() async {
    final response = await _dioClient.get(ApiConfig.session);
    return response.data;
  }

  Future<void> logout() async {
    try {
      await _dioClient.post(ApiConfig.logout, data: {});
    } catch (_) {}
    await storage.deleteToken();
    await storage.deleteUser();
  }
}
