import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../admin_dashboard_screen.dart' show CustomersPage, JobsPage, DashboardPage;
import '../../../../login_screen.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../auth/domain/entities/user_session.dart';
import '../../../../core/security/rbac_constants.dart';
import '../../../../core/security/role_access_provider.dart';
import '../../../technicians/presentation/screens/technicians_screen.dart';


class NavItem {
  final String id;
  final String label;
  final IconData icon;
  final Permission? requiredPermission;

  const NavItem({
    required this.id,
    required this.label,
    required this.icon,
    this.requiredPermission,
  });
}

const allNavItems = [
  NavItem(id: 'dashboard', label: 'Dashboard', icon: Icons.dashboard, requiredPermission: Permission.viewDashboard),
  NavItem(id: 'customers', label: 'Customers', icon: Icons.group, requiredPermission: Permission.viewUsers),
  NavItem(id: 'technicians', label: 'Technicians', icon: Icons.engineering, requiredPermission: Permission.manageTechnicians),
  NavItem(id: 'jobs', label: 'Service Requests', icon: Icons.work, requiredPermission: Permission.assignTasks),
];

class DashboardShellScreen extends ConsumerStatefulWidget {
  const DashboardShellScreen({super.key});

  @override
  ConsumerState<DashboardShellScreen> createState() => _DashboardShellScreenState();
}

class _DashboardShellScreenState extends ConsumerState<DashboardShellScreen> {
  String activePage = 'dashboard';
  bool collapsed = false;

  void _selectPage(String pageId) {
    setState(() => activePage = pageId);
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final isDesktop = mediaQuery.size.width >= 1024;
    final isTablet = mediaQuery.size.width >= 768 && !isDesktop;
    final isMobile = mediaQuery.size.width < 768;
    
    final session = ref.watch(authProvider);
    final permissions = ref.watch(currentUserPermissionsProvider);

    final visibleNavItems = allNavItems.where((item) {
      if (item.requiredPermission == null) return true;
      return permissions.contains(item.requiredPermission);
    }).toList();

    final currentPage = visibleNavItems.any((item) => item.id == activePage) && visibleNavItems.isNotEmpty
        ? activePage
        : (visibleNavItems.isNotEmpty ? visibleNavItems.first.id : 'dashboard');

    final String pageTitle = visibleNavItems.firstWhere((item) => item.id == currentPage, orElse: () => allNavItems.first).label;

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      drawer: (isMobile || isTablet) ? Drawer(
        child: Container(
          color: const Color(0xFF0F172A),
          child: _SidebarContent(
            items: visibleNavItems,
            activePage: currentPage,
            onSelect: _selectPage,
            userRole: session?.role.name.toUpperCase() ?? 'GUEST',
          ),
        ),
      ) : null,
      body: Row(
        children: [
          if (isDesktop)
            Container(
              width: collapsed ? 80 : 260,
              color: const Color(0xFF0F172A),
              child: _SidebarContent(
                items: visibleNavItems,
                activePage: currentPage,
                onSelect: _selectPage,
                collapsed: collapsed,
                onToggleCollapse: () => setState(() => collapsed = !collapsed),
                userRole: session?.role.name.toUpperCase() ?? 'GUEST',
              ),
            ),
          Expanded(
            child: Column(
              children: [
                _buildTopBar(context, pageTitle, isMobile || isTablet, session),
                Expanded(
                  child: _buildPageContent(currentPage),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar(BuildContext context, String pageTitle, bool showMenuIcon, UserSession? session) {
    return Container(
      height: 70,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
      ),
      child: Row(
        children: [
          if (showMenuIcon)
            Builder(
              builder: (ctx) => IconButton(
                icon: const Icon(Icons.menu),
                onPressed: () => Scaffold.of(ctx).openDrawer(),
              ),
            ),
          if (showMenuIcon) const SizedBox(width: 8),
          Expanded(
            child: Text(pageTitle, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF0F172A))),
          ),
          if (MediaQuery.of(context).size.width > 600)
            Container(
              width: 240,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFE2E8F0))),
              child: Row(
                children: const [
                  Icon(Icons.search, color: Color(0xFF94A3B8), size: 18),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text('Search anything…', style: TextStyle(color: Color(0xFF64748B), fontSize: 13)),
                  ),
                  SizedBox(width: 8),
                  Text('⌘K', style: TextStyle(fontSize: 10, color: Color(0xFFCBD5E1))),
                ],
              ),
            ),
          const SizedBox(width: 16),
          Stack(
            children: [
              IconButton(onPressed: () {}, icon: const Icon(Icons.notifications_none, color: Color(0xFF64748B))),
              Positioned(right: 8, top: 8, child: Container(width: 8, height: 8, decoration: const BoxDecoration(color: Color(0xFFF43F5E), shape: BoxShape.circle, border: Border.fromBorderSide(BorderSide(color: Colors.white, width: 1.5)))),),
            ],
          ),
          const SizedBox(width: 14),
          PopupMenuButton<String>(
            tooltip: 'Account',
            onSelected: (value) {
              if (value == 'logout') {
                ref.read(authProvider.notifier).logout();
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                  (route) => false,
                );
              }
            },
            itemBuilder: (context) => const [
              PopupMenuItem<String>(
                value: 'logout',
                child: Text('Log out'),
              ),
            ],
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: const Color(0xFFE2E8F0))),
              child: Row(
                children: [
                  CircleAvatar(backgroundColor: const Color(0xFF6366F1), radius: 14, child: Text(session?.name.substring(0, 1) ?? 'U', style: const TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.bold))),
                  if (MediaQuery.of(context).size.width > 800) ...[
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(session?.name ?? 'User', style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: Color(0xFF0F172A))),
                        Text(session?.role.name.toUpperCase() ?? 'GUEST', style: const TextStyle(fontSize: 10.5, color: Color(0xFF94A3B8))),
                      ],
                    ),
                    const SizedBox(width: 8),
                    const Icon(Icons.keyboard_arrow_down, size: 18, color: Color(0xFF94A3B8)),
                  ]
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPageContent(String pageId) {
    final permissions = ref.watch(currentUserPermissionsProvider);

    bool hasAccess(Permission? permission) {
      if (permission == null) return true;
      return permissions.contains(permission);
    }

    switch (pageId) {
      case 'customers':
        return hasAccess(Permission.viewUsers) ? const CustomersPage() : const _UnauthorizedFeatureView();
      case 'technicians':
        return hasAccess(Permission.manageTechnicians) ? const TechniciansScreen() : const _UnauthorizedFeatureView();
      case 'jobs':
        return hasAccess(Permission.assignTasks) ? const JobsPage() : const _UnauthorizedFeatureView();
      case 'dashboard':
      default:
        return hasAccess(Permission.viewDashboard) ? const DashboardPage() : const _UnauthorizedFeatureView();
    }
  }
}

class _UnauthorizedFeatureView extends StatelessWidget {
  const _UnauthorizedFeatureView();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.lock_outline_rounded, color: Color(0xFF94A3B8), size: 34),
            SizedBox(height: 10),
            Text(
              'Access denied for this feature.',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _SidebarContent extends StatelessWidget {
  final List<NavItem> items;
  final String activePage;
  final Function(String) onSelect;
  final bool collapsed;
  final VoidCallback? onToggleCollapse;
  final String userRole;

  const _SidebarContent({
    required this.items,
    required this.activePage,
    required this.onSelect,
    this.collapsed = false,
    this.onToggleCollapse,
    required this.userRole,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: EdgeInsets.all(collapsed ? 16.0 : 24.0),
          child: Row(
            mainAxisAlignment: collapsed ? MainAxisAlignment.center : MainAxisAlignment.start,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Color(0xFF6366F1), Color(0xFF4F46E5)]),
                  borderRadius: BorderRadius.circular(10),
                ),
                alignment: Alignment.center,
                child: const Text('T', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              ),
              if (!collapsed) ...[
                const SizedBox(width: 14),
                const Text('Techbes', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Colors.white)),
              ],
            ],
          ),
        ),
        const SizedBox(height: 10),
        Expanded(
          child: ListView(
            padding: EdgeInsets.symmetric(horizontal: collapsed ? 8 : 16),
            children: items.map((item) {
              final isActive = activePage == item.id;
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Material(
                  color: isActive ? const Color.fromRGBO(99, 102, 241, 0.18) : Colors.transparent,
                  borderRadius: BorderRadius.circular(14),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: () {
                      onSelect(item.id);
                      if (Scaffold.maybeOf(context)?.hasDrawer ?? false) {
                        Navigator.pop(context);
                      }
                    },
                    child: Container(
                      padding: EdgeInsets.symmetric(vertical: 12, horizontal: collapsed ? 14 : 12),
                      decoration: isActive ? BoxDecoration(borderRadius: BorderRadius.circular(14)) : null,
                      child: Row(
                        mainAxisAlignment: collapsed ? MainAxisAlignment.center : MainAxisAlignment.start,
                        children: [
                          Icon(item.icon, size: 20, color: isActive ? const Color(0xFFFFFFFF) : const Color(0xFF94A3B8)),
                          if (!collapsed) ...[
                            const SizedBox(width: 10),
                            Expanded(child: Text(item.label, style: TextStyle(color: isActive ? Colors.white : const Color(0xFF94A3B8), fontWeight: isActive ? FontWeight.w600 : FontWeight.w500))),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: const BoxDecoration(border: Border(top: BorderSide(color: Color.fromRGBO(255, 255, 255, 0.06)))),
          child: Column(
            children: [
              if (!collapsed)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: const Color.fromRGBO(255, 255, 255, 0.03), borderRadius: BorderRadius.circular(14)),
                  child: Row(
                    children: [
                      const CircleAvatar(backgroundColor: Color(0xFF6366F1), radius: 15, child: Icon(Icons.security, size: 14, color: Colors.white)),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Access Level', style: TextStyle(color: Colors.white, fontSize: 12.5, fontWeight: FontWeight.w600)),
                            Text(userRole, style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 10.5)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 8),
              if (onToggleCollapse != null)
                ElevatedButton(
                  onPressed: onToggleCollapse,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color.fromRGBO(255, 255, 255, 0.03),
                    foregroundColor: const Color(0xFF94A3B8),
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    side: const BorderSide(color: Color.fromRGBO(255, 255, 255, 0.06)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(collapsed ? Icons.arrow_forward_ios : Icons.arrow_back_ios, size: 16),
                      if (!collapsed) const SizedBox(width: 6),
                      if (!collapsed) const Text('Collapse', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
