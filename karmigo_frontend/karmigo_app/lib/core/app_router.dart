import 'package:flutter/material.dart';
import '../customer/screens/customer_dashboard.dart';
import '../customer/screens/login_screen.dart';
import '../customer/screens/signup_screen.dart';
import '../labour/screens/labour_main_screen.dart';
import '../labour/screens/labour_login.dart';
import '../admin/admin_login_screen.dart';
import '../admin/admin_dashboard_screen.dart';
import '../admin/admin_jobs_screen.dart';
import '../admin/admin_reports_screen.dart';

class AppRouter {
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case '/':
      case '/customer/home':
        return MaterialPageRoute(builder: (_) => const CustomerDashboard());
      
      case '/customer/login':
        return MaterialPageRoute(builder: (_) => LoginScreen());
      
      case '/signup':
        return MaterialPageRoute(builder: (_) => SignupScreen());

      case '/labour/login':
        return MaterialPageRoute(builder: (_) => LabourLogin());
      
      case '/labour/home':
        return MaterialPageRoute(builder: (_) => const LabourMainScreen());

      case '/admin/login':
        return MaterialPageRoute(builder: (_) => const AdminLoginScreen());
      
      case '/admin/dashboard':
        return MaterialPageRoute(builder: (_) => const AdminDashboardScreen());
      
      case '/admin/jobs':
        return MaterialPageRoute(builder: (_) => const AdminJobsScreen());
      
      case '/admin/reports':
        return MaterialPageRoute(builder: (_) => const AdminReportsScreen());
        
      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            appBar: AppBar(title: const Text("Error")),
            body: Center(child: Text("Route not found: ${settings.name}")),
          ),
        );
    }
  }
}
