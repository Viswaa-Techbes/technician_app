import '../../core/network/api_config.dart';
import '../../core/network/dio_client.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../services/secure_storage_service.dart';
import '../models/user_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AuthRepositoryImpl implements AuthRepository {
  final ApiService _apiService;
  final SecureStorageService _storage;

  AuthRepositoryImpl(this._apiService, this._storage);

  @override
  Future<User> login(String mobileNumber, String password) async {
    final response = await _apiService.post(ApiConfig.login, data: {
      'mobileNumber': mobileNumber,
      'password': password,
    });
    
    final userModel = UserModel.fromJson(response.data);
    if (userModel.token != null) {
      await _storage.saveToken(userModel.token!);
      await _storage.saveRole(userModel.role);
    }
    return userModel;
  }

  @override
  Future<User> signup(Map<String, dynamic> userData) async {
    final response = await _apiService.post(ApiConfig.signup, data: userData);
    return UserModel.fromJson(response.data);
  }

  @override
  Future<User> getCurrentUser() async {
    final response = await _apiService.get(ApiConfig.me);
    return UserModel.fromJson(response.data);
  }

  @override
  Future<void> logout() async {
    await _storage.clearAll();
  }

  @override
  Future<void> updateFcmToken(String fcmToken) async {
    await _apiService.post(ApiConfig.fcmToken, data: {'fcmToken': fcmToken});
  }
}

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepositoryImpl(
    ref.watch(apiServiceProvider),
    ref.watch(secureStorageProvider),
  );
});
