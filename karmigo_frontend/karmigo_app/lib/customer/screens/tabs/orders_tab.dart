import 'package:flutter/material.dart';
import '../my_work_requests_screen.dart';

class OrdersTab extends StatelessWidget {
  const OrdersTab({super.key});

  @override
  Widget build(BuildContext context) {
    // Reuse the existing MyWorkRequestsScreen
    return const MyWorkRequestsScreen();
  }
}
