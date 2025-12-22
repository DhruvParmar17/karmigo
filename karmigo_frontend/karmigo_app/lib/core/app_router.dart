import 'package:flutter/material.dart';
import '../customer/screens/customer_home.dart';
import '../labour/screens/labour_home.dart';

class AppRouter {
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case '/':
        return MaterialPageRoute(builder: (_) => const CustomerHome());
      case '/labour':
        return MaterialPageRoute(builder: (_) => const LabourHome());
      default:
        return MaterialPageRoute(
          builder: (_) => const Scaffold(
            body: Center(child: Text("Route not found")),
          ),
        );
    }
  }
}
