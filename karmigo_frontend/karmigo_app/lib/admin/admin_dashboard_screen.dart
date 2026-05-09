import 'package:flutter/material.dart';
import '../../core/auth_state.dart';
import '../../theme/porter_theme.dart';
import '../../customer/screens/login_screen.dart';
import 'admin_overview_screen.dart';
import 'admin_jobs_screen.dart';
import 'admin_labour_screen.dart';
import 'admin_customers_screen.dart';
import 'admin_attention_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    AdminOverviewScreen(),
    AdminJobsScreen(),
    AdminLabourScreen(),
    AdminCustomersScreen(),
    AdminAttentionScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        selectedItemColor: PorterTheme.primaryColor,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: "Overview V2",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.work),
            label: "Jobs",
          ),
           BottomNavigationBarItem(
            icon: Icon(Icons.group),
            label: "Labour",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people_outline),
            label: "Customers",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.warning_amber),
            label: "Attention",
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.small(
        backgroundColor: Colors.redAccent,
        child: const Icon(Icons.logout, color: Colors.white),
        onPressed: () {
          AuthState.clear();
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => LoginScreen()),
            (route) => false,
          );
        },
      ),
    );
  }
}
