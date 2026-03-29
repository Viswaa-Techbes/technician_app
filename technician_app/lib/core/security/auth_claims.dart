import 'rbac_constants.dart';

/// API-ready JWT claim model for backend role validation.
class AuthClaims {
  final String userId;
  final Role role;
  final Set<Permission> permissions;

  const AuthClaims({
    required this.userId,
    required this.role,
    required this.permissions,
  });

  factory AuthClaims.fromJson(Map<String, dynamic> json) {
    final permissionNames = (json['permissions'] as List<dynamic>? ?? const [])
        .map((e) => e.toString())
        .toSet();

    return AuthClaims(
      userId: json['sub']?.toString() ?? '',
      role: Role.values.firstWhere(
        (r) => r.name == json['role'],
        orElse: () => Role.technician,
      ),
      permissions: allPermissions.where((p) => permissionNames.contains(p.name)).toSet(),
    );
  }
}
