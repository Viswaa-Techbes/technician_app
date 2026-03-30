import '../../../../core/security/rbac_constants.dart';

class UserSession {
  final String id;
  final String name;
  final String email;
  final Role role;
  final String token;

  const UserSession({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.token,
  });

  factory UserSession.fromApi(Map<String, dynamic> json) {
    final user = json['user'] as Map<String, dynamic>? ?? <String, dynamic>{};

    return UserSession(
      id: user['id']?.toString() ?? '',
      name: user['name']?.toString() ?? 'User',
      email: user['email']?.toString() ?? '',
      role: _parseRole(user['role']?.toString()),
      token: json['token']?.toString() ?? '',
    );
  }

  static Role _parseRole(String? value) {
    switch (value?.toLowerCase()) {
      case 'manager':
        return Role.manager;
      case 'technician':
      default:
        return Role.technician;
    }
  }
}
