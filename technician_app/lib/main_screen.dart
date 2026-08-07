import 'package:flutter/material.dart';
import 'dashboard_screen.dart';
import 'jobs_screen.dart';
import 'screens/amc_jobs_screen.dart';
import 'expenses_screen.dart';
import 'profile_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = const [
    DashboardScreen(),
    JobsScreen(),
    AmcJobsScreen(),
    ExpensesScreen(),
    ProfileScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _screens,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: _onItemTapped,
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          selectedItemColor: Colors.blue.shade800,
          unselectedItemColor: Colors.grey.shade400,
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w900, fontSize: 11),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 11),
          elevation: 0,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.grid_view_rounded),
              activeIcon: Icon(Icons.grid_view_rounded),
              label: 'HOME',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.assignment_rounded),
              activeIcon: Icon(Icons.assignment_rounded),
              label: 'JOBS',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.verified_user_rounded),
              activeIcon: Icon(Icons.verified_user_rounded),
              label: 'AMC JOBS',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.account_balance_wallet_rounded),
              activeIcon: Icon(Icons.account_balance_wallet_rounded),
              label: 'EXPENSES',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_rounded),
              activeIcon: Icon(Icons.person_rounded),
              label: 'PROFILE',
            ),
          ],
        ),
      ),
    );
  }
}
