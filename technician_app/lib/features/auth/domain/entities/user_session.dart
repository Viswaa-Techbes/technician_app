import '../../../../core/security/rbac_constants.dart';

class UserSession {
  final String id;
  final String name;
  final String email;
  final Role role;

  const UserSession({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
  });
}
