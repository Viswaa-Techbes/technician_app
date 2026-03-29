import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/auth/domain/entities/user_session.dart';
import '../../features/auth/presentation/providers/auth_provider.dart';
import 'rbac_constants.dart';

class UserRoleProfile {
  final String userId;
  final String name;
  final String email;
  final Role role;

  const UserRoleProfile({
    required this.userId,
    required this.name,
    required this.email,
    required this.role,
  });

  UserRoleProfile copyWith({Role? role}) {
    return UserRoleProfile(
      userId: userId,
      name: name,
      email: email,
      role: role ?? this.role,
    );
  }
}

class RoleAccessState {
  final Map<Role, Set<Permission>> rolePermissionMap;
  final List<UserRoleProfile> users;

  const RoleAccessState({
    required this.rolePermissionMap,
    required this.users,
  });

  RoleAccessState copyWith({
    Map<Role, Set<Permission>>? rolePermissionMap,
    List<UserRoleProfile>? users,
  }) {
    return RoleAccessState(
      rolePermissionMap: rolePermissionMap ?? this.rolePermissionMap,
      users: users ?? this.users,
    );
  }
}

class RoleAccessNotifier extends StateNotifier<RoleAccessState> {
  RoleAccessNotifier()
      : super(
          RoleAccessState(
            rolePermissionMap: {
              for (final entry in defaultRolePermissions.entries)
                entry.key: entry.value.toSet(),
            },
            users: const [
              UserRoleProfile(
                userId: 'u_admin',
                name: 'Admin User',
                email: 'admin@techbes.com',
                role: Role.admin,
              ),
              UserRoleProfile(
                userId: 'u_manager',
                name: 'Manager User',
                email: 'manager@techbes.com',
                role: Role.manager,
              ),
              UserRoleProfile(
                userId: 'u_technician',
                name: 'Technician User',
                email: 'tech@techbes.com',
                role: Role.technician,
              ),
            ],
          ),
        );

  Set<Permission> permissionsForRole(Role role) {
    return state.rolePermissionMap[role] ?? <Permission>{};
  }

  bool hasPermission(UserSession? session, Permission permission) {
    if (session == null) return false;
    return permissionsForRole(session.role).contains(permission);
  }

  void setPermission({
    required Role role,
    required Permission permission,
    required bool enabled,
  }) {
    final updated = <Role, Set<Permission>>{
      for (final entry in state.rolePermissionMap.entries)
        entry.key: Set<Permission>.from(entry.value),
    };
    final rolePermissions = updated[role] ?? <Permission>{};
    if (enabled) {
      rolePermissions.add(permission);
    } else {
      rolePermissions.remove(permission);
    }
    updated[role] = rolePermissions;
    state = state.copyWith(rolePermissionMap: updated);
  }

  void assignRole({
    required String userId,
    required Role role,
  }) {
    final updatedUsers = state.users
        .map(
          (u) => u.userId == userId ? u.copyWith(role: role) : u,
        )
        .toList(growable: false);
    state = state.copyWith(users: updatedUsers);
  }
}

final roleAccessProvider =
    StateNotifierProvider<RoleAccessNotifier, RoleAccessState>(
  (ref) => RoleAccessNotifier(),
);

final currentUserPermissionsProvider = Provider<Set<Permission>>((ref) {
  final session = ref.watch(authProvider);
  final roleAccess = ref.watch(roleAccessProvider);
  if (session == null) return <Permission>{};
  return roleAccess.rolePermissionMap[session.role] ?? <Permission>{};
});
