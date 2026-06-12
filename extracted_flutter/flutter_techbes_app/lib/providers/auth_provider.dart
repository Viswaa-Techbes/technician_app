import 'package:flutter/material.dart';
import 'package:techbes_app/models/models.dart';
import '../services/auth_service.dart';
import '../services/api_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  late ApiService _apiService;

  User? _currentUser;
  bool _isLoggedIn = false;
  bool _isLoading = false;
  String? _error;

  User? get currentUser => _currentUser;
  bool get isLoggedIn => _isLoggedIn;
  bool get isLoading => _isLoading;
  String? get error => _error;

  AuthProvider() {
    _apiService = ApiService();
    _initializeAuth();
  }

  Future<void> _initializeAuth() async {
    await _apiService.init();
    // Check if user has a stored token from previous session
    if (_apiService.getAuthToken() != null) {
      _isLoggedIn = true;
      notifyListeners();
    }
  }

  Future<void> login(String email, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await _authService.login(email, password);

      if (result['success']) {
        final userData = result['user'] ?? {};
        _currentUser = User(
          id: userData['id'] ?? userData['userId'] ?? email,
          name: userData['name'] ?? '',
          email: userData['email'] ?? email,
          phone: userData['phone'] ?? userData['mobileNumber'] ?? '',
          profileImage: userData['profileImage'],
        );
        _isLoggedIn = true;
        _error = null;
      } else {
        _error = result['message'] ?? 'Login failed';
        _isLoggedIn = false;
        _currentUser = null;
      }
    } catch (e) {
      _error = 'An error occurred: ${e.toString()}';
      _isLoggedIn = false;
      _currentUser = null;
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> signup(String name, String email, String password, {String phone = ''}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await _authService.register(name, email, password, phone);

      if (result['success']) {
        final userData = result['user'] ?? {};
        _currentUser = User(
          id: userData['id'] ?? userData['userId'] ?? email,
          name: name,
          email: email,
          phone: phone,
          profileImage: userData['profileImage'],
        );
        _isLoggedIn = true;
        _error = null;
      } else {
        _error = result['message'] ?? 'Registration failed';
        _isLoggedIn = false;
        _currentUser = null;
      }
    } catch (e) {
      _error = 'An error occurred: ${e.toString()}';
      _isLoggedIn = false;
      _currentUser = null;
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> logout() async {
    _isLoading = true;
    notifyListeners();

    try {
      await _authService.logout();
    } catch (e) {
      // Continue logout even if API call fails
    }

    _currentUser = null;
    _isLoggedIn = false;
    _error = null;
    _isLoading = false;
    notifyListeners();
  }

  Future<void> checkAuthStatus() async {
    try {
      final result = await _authService.getSession();
      if (result['success']) {
        final userData = result['user'] ?? {};
        _currentUser = User(
          id: userData['id'] ?? '',
          name: userData['name'] ?? '',
          email: userData['email'] ?? '',
          phone: userData['phone'] ?? '',
          profileImage: userData['profileImage'],
        );
        _isLoggedIn = true;
      } else {
        _currentUser = null;
        _isLoggedIn = false;
      }
    } catch (e) {
      _currentUser = null;
      _isLoggedIn = false;
    }
    notifyListeners();
  }
}
