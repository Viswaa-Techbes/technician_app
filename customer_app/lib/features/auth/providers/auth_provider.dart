import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../repositories/auth_repository.dart';
import '../../../core/utils/logger.dart';
import '../../../core/utils/jwt_decoder.dart';
import '../../../core/network/dio_client.dart';

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
    appLogger.i("Startup: Initiating session check.");
    state = AuthState.loading();

    try {
      appLogger.i("Startup Step 1: Reading token from secure storage.");
      final token = await _repository.storage.getToken();
      
      if (token != null && token.isNotEmpty) {
        appLogger.i("Startup Step 2: Validating token locally.");
        if (!JwtDecoder.isExpired(token)) {
          appLogger.i("Startup Step 3: Loading cached user details.");
          final cachedUser = await _repository.storage.getUser();
          
          appLogger.i("Startup Step 4: Setting local authenticated state immediately.");
          state = AuthState.authenticated(cachedUser ?? {'email': 'User'});
          
          appLogger.i("Startup Step 5: Triggering background session verification.");
          _verifySessionInBackground();
          return;
        } else {
          appLogger.w("Startup: Stored token is expired.");
        }
      } else {
        appLogger.i("Startup: No token found in storage.");
      }
    } catch (e) {
      appLogger.e("Startup Error: Exception during local validation: $e");
    }

    appLogger.i("Startup: Finalizing unauthenticated state.");
    state = AuthState.unauthenticated();
  }

  Future<void> _verifySessionInBackground() async {
    try {
      final session = await _repository.getSession();
      if (session != null && session['success'] == true && session['user'] != null) {
        appLogger.i("Background Session Check: Session is valid. Updating cached user.");
        await _repository.storage.saveUser(session['user']);
        state = AuthState.authenticated(session['user']);
      } else {
        appLogger.w("Background Session Check: Invalid response. Logging out.");
        await logout();
      }
    } on UnauthorizedException catch (e) {
      appLogger.w("Background Session Check: Unauthorized (401/403). Logging out. Error: $e");
      await logout();
    } on NetworkException catch (e) {
      appLogger.w("Background Session Check: Network offline/error. Keeping cached session. Error: $e");
      // Maintain authenticated state
    } catch (e) {
      appLogger.e("Background Session Check: Unexpected error. Keeping cached session. Error: $e");
      // Maintain authenticated state
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
