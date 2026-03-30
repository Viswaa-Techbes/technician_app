import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/security/rbac_constants.dart';
import '../../domain/entities/user_session.dart';

class AuthNotifier extends StateNotifier<UserSession?> {
  AuthNotifier(this._apiClient) : super(null);

  final ApiClient _apiClient;

  Future<UserSession> login({
    required String email,
    required String password,
  }) async {
    final response = await _apiClient.postJson(
      '/auth/login',
      body: <String, dynamic>{
        'email': email.trim(),
        'password': password,
      },
    );

    final session = UserSession.fromApi(
      response['data'] as Map<String, dynamic>? ?? <String, dynamic>{},
    );
    state = session;
    return session;
  }

  Future<UserSession> register({
    required String name,
    required String email,
    required String password,
    required Role role,
  }) async {
    final response = await _apiClient.postJson(
      '/auth/register',
      body: <String, dynamic>{
        'name': name.trim(),
        'email': email.trim(),
        'password': password,
        'role': role.name,
      },
    );

    final session = UserSession.fromApi(
      response['data'] as Map<String, dynamic>? ?? <String, dynamic>{},
    );
    state = session;
    return session;
  }

  void logout() {
    state = null;
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, UserSession?>((ref) {
  return AuthNotifier(ref.watch(apiClientProvider));
});
