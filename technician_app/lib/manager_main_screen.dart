import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/network/api_client.dart';
import 'features/auth/presentation/providers/auth_provider.dart';
import 'manager_dashboard_screen.dart';
import 'manager_jobs_screen.dart';
import 'teams_screen.dart';
import 'completion_requests_screen.dart';
import 'manager_profile_screen.dart';
import 'demo_data.dart';

class ManagerMainScreen extends ConsumerStatefulWidget {
  const ManagerMainScreen({super.key});

  @override
  ConsumerState<ManagerMainScreen> createState() => _ManagerMainScreenState();
}

class _ManagerMainScreenState extends ConsumerState<ManagerMainScreen> {
  int _selectedIndex = 0;
  bool _isLoading = true;

  final List<Widget> _screens = [
    const ManagerDashboardScreen(),
    const ManagerJobsScreen(),
    const TeamsScreen(),
    const CompletionRequestsScreen(),
    const ManagerProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _initData();
  }

  Future<void> _initData() async {
    final client = ref.read(apiClientProvider);
    final session = ref.read(authProvider);
    await DemoData.instance.loadFromApi(client, session?.token ?? '');
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _screens,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 20, offset: const Offset(0, -5)),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: BottomNavigationBar(
              currentIndex: _selectedIndex,
              onTap: (index) => setState(() => _selectedIndex = index),
              backgroundColor: Colors.transparent,
              elevation: 0,
              type: BottomNavigationBarType.fixed,
              selectedItemColor: const Color(0xFF1E3A8A),
              unselectedItemColor: const Color(0xFF94A3B8),
              selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w900, fontSize: 11),
              unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 11),
              items: const [
                BottomNavigationBarItem(icon: Icon(Icons.dashboard_rounded), label: 'DASHBOARD'),
                BottomNavigationBarItem(icon: Icon(Icons.assignment_rounded), label: 'JOBS'),
                BottomNavigationBarItem(icon: Icon(Icons.group_rounded), label: 'TEAMS'),
                BottomNavigationBarItem(icon: Icon(Icons.pending_actions_rounded), label: 'REQUESTS'),
                BottomNavigationBarItem(icon: Icon(Icons.person_rounded), label: 'PROFILE'),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
