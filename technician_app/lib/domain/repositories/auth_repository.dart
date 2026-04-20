import '../entities/user.dart';

abstract class AuthRepository {
  Future<User> login(String mobileNumber, String password);
  Future<User> signup(Map<String, dynamic> userData);
  Future<User> getCurrentUser();
  Future<void> logout();
  Future<void> updateFcmToken(String fcmToken);
}
