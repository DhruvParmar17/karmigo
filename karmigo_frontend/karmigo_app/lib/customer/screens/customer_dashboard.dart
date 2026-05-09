import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'customer_home_screen.dart';
import 'my_work_requests_screen.dart'; // Orders
import 'tabs/rewards_tab.dart'; // Assuming this isn't fully replaced yet
import 'tabs/wallet_tab.dart';  // Assuming this isn't fully replaced yet
import 'customer_account_screen.dart';
import '../../theme/porter_theme.dart';

class CustomerDashboard extends StatefulWidget {
  const CustomerDashboard({super.key});

  @override
  State<CustomerDashboard> createState() => _CustomerDashboardState();
}

class _CustomerDashboardState extends State<CustomerDashboard> {
  int _selectedIndex = 0;

  // Pages
  late List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [
      const CustomerHomeScreen(),          /* Home */
      const MyWorkRequestsScreen(),        /* Orders */
      const RewardsTab(),                  /* Rewards */
      const WalletTab(),                   /* Wallet */
      const CustomerAccountScreen(),       /* Account */
    ];
  }

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
        children: _pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed, // Ensure all items show
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: PorterTheme.primaryColor,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
          BottomNavigationBarItem(icon: Icon(Icons.receipt_long), label: "Orders"),
          BottomNavigationBarItem(icon: Icon(Icons.card_giftcard), label: "Rewards"),
          BottomNavigationBarItem(icon: Icon(Icons.account_balance_wallet), label: "Wallet"),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "Account"),
        ],
      ),
    );
  }
}
