import 'package:customer_app/core/api/api_client.dart';
import 'package:customer_app/core/api/api_endpoints.dart';
import 'package:customer_app/core/auth/auth_models.dart';
import 'package:customer_app/core/storage/secure_storage.dart';

/// Auth repository mirroring `features/auth/services/auth-service.ts`.
///
/// Calls the backend directly (no BFF proxy). Persists the backend JWT
/// token in secure storage for subsequent API calls.
class AuthRepository {
  final ApiClient _api = ApiClient.instance;

  Future<LoginResponse> login(LoginPayload payload) async {
    final response = await _api.post<Map<String, dynamic>>(
      ApiEndpoints.login,
      data: payload.toJson(),
    );
    final loginResponse = LoginResponse.fromJson(response);
    await SecureStorage.saveToken(loginResponse.token);
    return loginResponse;
  }

  Future<OtpResponse> sendOtp(String email) async {
    final response = await _api.post<Map<String, dynamic>>(
      ApiEndpoints.sendOtp,
      data: {'email': email.trim().toLowerCase()},
    );
    return OtpResponse.fromJson(response);
  }

  Future<OtpVerifyResponse> verifyOtp(String email, String otp) async {
    final response = await _api.post<Map<String, dynamic>>(
      ApiEndpoints.verifyOtp,
      data: {
        'email': email.trim().toLowerCase(),
        'otp': otp.trim(),
      },
    );
    return OtpVerifyResponse.fromJson(response);
  }

  Future<LoginResponse> register(SignupPayload payload) async {
    final response = await _api.post<Map<String, dynamic>>(
      ApiEndpoints.register,
      data: payload.toJson(),
    );
    final loginResponse = LoginResponse.fromJson(response);
    await SecureStorage.saveToken(loginResponse.token);
    return loginResponse;
  }

  Future<void> logout() async {
    try {
      await _api.post(ApiEndpoints.logout, data: {});
    } catch (_) {
      // Best-effort server logout; always clear local state
    }
    await SecureStorage.clearAll();
  }

  Future<SessionResponse> getSession() async {
    final response = await _api.get<Map<String, dynamic>>(ApiEndpoints.session);
    final session = SessionResponse.fromJson(response);
    if (session.user?.token != null) {
      await SecureStorage.saveToken(session.user!.token!);
    }
    return session;
  }

  Future<bool> hasToken() async {
    final token = await SecureStorage.getToken();
    return token != null && token.isNotEmpty;
  }
}
