import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/security/rbac_constants.dart';
import '../../domain/entities/user_session.dart';

class AuthNotifier extends StateNotifier<UserSession?> {
  AuthNotifier() : super(null);

  void loginAs(Role role) {
    String name = 'User';
    String email = 'user@example.com';
    
    switch (role) {
      case Role.admin:
        name = 'Admin User';
        email = 'admin@techbes.com';
        break;
      case Role.manager:
        name = 'Manager User';
        email = 'manager@techbes.com';
        break;
      case Role.technician:
        name = 'Technician User';
        email = 'tech@techbes.com';
        break;
    }

    state = UserSession(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      email: email,
      role: role,
    );
  }

  void logout() {
    state = null;
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, UserSession?>((ref) {
  return AuthNotifier();
});
