import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:customer_app/core/auth/auth_models.dart';
import 'package:customer_app/core/auth/auth_repository.dart';
import 'package:customer_app/core/api/api_exceptions.dart';

// ── Auth State ───────────────────────────────────────────────────────────

@immutable
class AuthState {
  final AuthUser? user;
  final bool isLoading;
  final bool isAuthenticated;
  final String? errorMessage;

  const AuthState({
    this.user,
    this.isLoading = false,
    this.isAuthenticated = false,
    this.errorMessage,
  });

  AuthState copyWith({
    AuthUser? user,
    bool? isLoading,
    bool? isAuthenticated,
    String? errorMessage,
    bool clearError = false,
  }) {
    return AuthState(
      user: user ?? this.user,
      isLoading: isLoading ?? this.isLoading,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

// ── Auth Notifier ────────────────────────────────────────────────────────

class AuthNotifier extends StateNotifier<AuthState> {
  final AuthRepository _repo;

  AuthNotifier(this._repo) : super(const AuthState(isLoading: true)) {
    _checkSession();
  }

  Future<void> _checkSession() async {
    try {
      final hasToken = await _repo.hasToken();
      if (!hasToken) {
        state = const AuthState();
        return;
      }
      final session = await _repo.getSession();
      if (session.authenticated && session.user != null) {
        state = AuthState(
          user: session.user,
          isAuthenticated: true,
        );
      } else {
        state = const AuthState();
      }
    } catch (_) {
      state = const AuthState();
    }
  }

  Future<void> refreshSession() async {
    await _checkSession();
  }

  Future<bool> login(LoginPayload payload) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final response = await _repo.login(payload);
      state = AuthState(
        user: response.user,
        isAuthenticated: true,
      );
      return true;
    } on ApiException catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.message);
      return false;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Login failed. Please try again.',
      );
      return false;
    }
  }

  Future<bool> register(SignupPayload payload) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final response = await _repo.register(payload);
      state = AuthState(
        user: response.user,
        isAuthenticated: true,
      );
      return true;
    } on ApiException catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.message);
      return false;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Registration failed. Please try again.',
      );
      return false;
    }
  }

  Future<void> logout() async {
    state = state.copyWith(isLoading: true);
    await _repo.logout();
    state = const AuthState();
  }

  void clearError() {
    state = state.copyWith(clearError: true);
  }
}

// ── Providers ────────────────────────────────────────────────────────────

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository();
});

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(ref.read(authRepositoryProvider));
});

/// Convenience: is the user currently logged in?
final isAuthenticatedProvider = Provider<bool>((ref) {
  return ref.watch(authProvider).isAuthenticated;
});
