import '../../core/network/api_config.dart';
import '../../core/network/dio_client.dart';
import '../../models.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../services/secure_storage_service.dart';
import '../models/user_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AuthRepositoryImpl implements AuthRepository {
  final DioClient _apiService;
  final SecureStorageService _storage;

  AuthRepositoryImpl(this._apiService, this._storage);

  @override
  Future<User> login(String mobileNumber, String password) async {
    final response = await _apiService.post(ApiConfig.login, data: {
      'mobileNumber': mobileNumber,
      'password': password,
    });
    
    final userModel = UserModel.fromJson(response.data);
    final token = userModel.token;
    if (token != null && token.isNotEmpty) {
      await _storage.saveToken(token);
      await _storage.saveRole(userModel.role.name);
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
    ref.watch(dioClientProvider),
    ref.watch(secureStorageProvider),
  );
});
