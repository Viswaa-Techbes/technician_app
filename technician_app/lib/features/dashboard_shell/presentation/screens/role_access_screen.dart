import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/security/rbac_constants.dart';
import '../../../../core/security/role_access_provider.dart';

class RoleAccessScreen extends ConsumerWidget {
  const RoleAccessScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(roleAccessProvider);
    final notifier = ref.read(roleAccessProvider.notifier);
    final width = MediaQuery.of(context).size.width;
    final isDesktop = width >= 1100;
    final cardWidth = isDesktop ? (width - 120) / 2 : double.infinity;

    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Wrap(
            spacing: 16,
            runSpacing: 16,
            children: [
              SizedBox(
                width: cardWidth,
                child: _SectionCard(
                  title: 'Role Management',
                  subtitle: 'Assign users to Admin, Manager, or Technician roles',
                  child: Column(
                    children: state.users
                        .map(
                          (user) => _UserRoleRow(
                            user: user,
                            onRoleChanged: (role) {
                              if (role == null) return;
                              notifier.assignRole(userId: user.userId, role: role);
                            },
                          ),
                        )
                        .toList(growable: false),
                  ),
                ),
              ),
              SizedBox(
                width: cardWidth,
                child: _SectionCard(
                  title: 'Permission Toggles',
                  subtitle: 'Dynamically map permissions to each role',
                  child: Column(
                    children: Role.values
                        .map(
                          (role) => _RolePermissionPanel(
                            role: role,
                            assigned: state.rolePermissionMap[role] ?? <Permission>{},
                            onChanged: (permission, enabled) {
                              notifier.setPermission(
                                role: role,
                                permission: permission,
                                enabled: enabled,
                              );
                            },
                          ),
                        )
                        .toList(growable: false),
                  ),
                ),
              ),
              SizedBox(
                width: constraints.maxWidth,
                child: const _JwtReadyHint(),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget child;

  const _SectionCard({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

class _UserRoleRow extends StatelessWidget {
  final UserRoleProfile user;
  final ValueChanged<Role?> onRoleChanged;

  const _UserRoleRow({
    required this.user,
    required this.onRoleChanged,
  });

  @override
  Widget build(BuildContext context) {
    final initials = user.name.isNotEmpty
        ? user.name
            .trim()
            .split(' ')
            .where((e) => e.isNotEmpty)
            .take(2)
            .map((e) => e[0])
            .join()
            .toUpperCase()
        : 'U';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: const Color(0xFF6366F1),
            child: Text(
              initials,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.name,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  user.email,
                  style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          DropdownButton<Role>(
            value: user.role,
            onChanged: onRoleChanged,
            items: Role.values
                .map(
                  (role) => DropdownMenuItem<Role>(
                    value: role,
                    child: Text(role.name.toUpperCase()),
                  ),
                )
                .toList(growable: false),
          ),
        ],
      ),
    );
  }
}

class _RolePermissionPanel extends StatelessWidget {
  final Role role;
  final Set<Permission> assigned;
  final void Function(Permission, bool) onChanged;

  const _RolePermissionPanel({
    required this.role,
    required this.assigned,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return ExpansionTile(
      tilePadding: EdgeInsets.zero,
      title: Text(
        role.name.toUpperCase(),
        style: const TextStyle(fontWeight: FontWeight.w700),
      ),
      children: allPermissions
          .map(
            (permission) => SwitchListTile(
              dense: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: 4),
              title: Text(permission.name),
              value: assigned.contains(permission),
              onChanged: (value) => onChanged(permission, value),
            ),
          )
          .toList(growable: false),
    );
  }
}

class _JwtReadyHint extends StatelessWidget {
  const _JwtReadyHint();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFEEF2FF),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Text(
        'Backend-ready note: role and permission state can be replaced by JWT claims and '
        'fetched API policies. Keep server-side permission middleware as the source of truth.',
        style: TextStyle(color: Color(0xFF3730A3), fontSize: 12.5),
      ),
    );
  }
}
