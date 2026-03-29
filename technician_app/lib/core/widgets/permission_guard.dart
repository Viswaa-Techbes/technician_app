import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../security/rbac_constants.dart';
import '../security/role_access_provider.dart';


class PermissionGuard extends ConsumerWidget {
  final Permission permission;
  final Widget child;
  final Widget fallback;

  const PermissionGuard({
    super.key,
    required this.permission,
    required this.child,
    this.fallback = const SizedBox.shrink(),
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final permissions = ref.watch(currentUserPermissionsProvider);
    if (!permissions.contains(permission)) {
      return fallback;
    }
    return child;
  }
}
