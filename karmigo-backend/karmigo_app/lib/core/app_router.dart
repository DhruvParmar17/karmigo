import 'package:flutter/material.dart';

import '../admin/screens/admin_dashboard.dart';
import '../admin/screens/bookings_list.dart';
import '../admin/screens/labour_list.dart';
import '../admin/screens/users_list.dart';
import '../customer/screens/customer_bookings.dart';
import '../customer/screens/customer_dashboard.dart';
import '../customer/screens/customer_profile.dart';
import '../labour/screens/earnings.dart';
import '../labour/screens/job_details.dart';
import '../labour/screens/job_requests.dart';
import '../labour/screens/labour_dashboard.dart';
import '../login_screen.dart';

class AppRouter {
  static const String initialRoute = login;
  static const String login = '/login';
  static const String customerDashboard = '/customer/dashboard';
  static const String customerBookings = '/customer/bookings';
  static const String customerProfile = '/customer/profile';
  static const String labourDashboard = '/labour/dashboard';
  static const String jobRequests = '/labour/requests';
  static const String jobDetails = '/labour/job-details';
  static const String earnings = '/labour/earnings';
  static const String adminDashboard = '/admin/dashboard';
  static const String usersList = '/admin/users';
  static const String labourList = '/admin/labour';
  static const String bookingsList = '/admin/bookings';

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case login:
        return _material(settings, const LoginScreen());
      case customerDashboard:
        return _material(settings, const CustomerDashboard());
      case customerBookings:
        return _material(settings, const CustomerBookings());
      case customerProfile:
        return _material(settings, const CustomerProfile());
      case labourDashboard:
        return _material(settings, const LabourDashboard());
      case jobRequests:
        return _material(settings, const JobRequests());
      case jobDetails:
        final jobId = settings.arguments as String? ?? 'N/A';
        return _material(settings, JobDetails(jobId: jobId));
      case earnings:
        return _material(settings, const Earnings());
      case adminDashboard:
        return _material(settings, const AdminDashboard());
      case usersList:
        return _material(settings, const UsersList());
      case labourList:
        return _material(settings, const LabourList());
      case bookingsList:
        return _material(settings, const BookingsList());
      default:
        return _material(
          settings,
          const Scaffold(
            body: Center(child: Text('Route not found')),
          ),
        );
    }
  }

  static MaterialPageRoute _material(RouteSettings settings, Widget child) {
    return MaterialPageRoute(builder: (_) => child, settings: settings);
  }
}

