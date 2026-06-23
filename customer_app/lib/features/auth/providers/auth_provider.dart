import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../repositories/auth_repository.dart';

enum AuthStatus { initial, loading, authenticated, unauthenticated, error }

class AuthState {
  final AuthStatus status;
  final Map<String, dynamic>? user;
  final String? errorMessage;

  AuthState({
    required this.status,
    this.user,
    this.errorMessage,
  });

  factory AuthState.initial() => AuthState(status: AuthStatus.initial);
  factory AuthState.loading() => AuthState(status: AuthStatus.loading);
  factory AuthState.authenticated(Map<String, dynamic> user) => AuthState(status: AuthStatus.authenticated, user: user);
  factory AuthState.unauthenticated() => AuthState(status: AuthStatus.unauthenticated);
  factory AuthState.error(String msg) => AuthState(status: AuthStatus.error, errorMessage: msg);
}

class AuthNotifier extends StateNotifier<AuthState> {
  final AuthRepository _repository;

  AuthNotifier(this._repository) : super(AuthState.initial()) {
    checkSession();
  }

  Future<void> checkSession() async {
    state = AuthState.loading();
    final session = await _repository.getSession();
    if (session != null && session['success'] == true && session['user'] != null) {
      state = AuthState.authenticated(session['user']);
    } else {
      state = AuthState.unauthenticated();
    }
  }

  Future<bool> login(String email, String password) async {
    state = AuthState.loading();
    try {
      final response = await _repository.login(email, password);
      if (response['success'] == true && response['user'] != null) {
        state = AuthState.authenticated(response['user']);
        return true;
      } else {
        state = AuthState.error(response['message'] ?? 'Failed to log in');
        return false;
      }
    } catch (e) {
      state = AuthState.error(e.toString());
      return false;
    }
  }

  Future<bool> register({
    required String name,
    required String email,
    required String password,
    required String phone,
    required String token,
  }) async {
    state = AuthState.loading();
    try {
      final response = await _repository.register(
        name: name,
        email: email,
        password: password,
        phone: phone,
        emailVerificationToken: token,
      );
      if (response['success'] == true && response['user'] != null) {
        state = AuthState.authenticated(response['user']);
        return true;
      } else {
        state = AuthState.error(response['message'] ?? 'Failed to sign up');
        return false;
      }
    } catch (e) {
      state = AuthState.error(e.toString());
      return false;
    }
  }

  Future<void> logout() async {
    await _repository.logout();
    state = AuthState.unauthenticated();
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(ref.watch(authRepositoryProvider));
});
