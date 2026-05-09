import 'package:flutter/material.dart';
import 'dart:async';
import '../../widgets/logo_widget.dart';
import '../../core/auth_state.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkAuthAndNavigate();
  }

  Future<void> _checkAuthAndNavigate() async {
    // Wait a brief moment for splash effect and ensuring AuthState is ready
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    if (AuthState.isLoggedIn) {
      final role = AuthState.role;
      debugPrint("Splash: Access Token found. Role: $role");
      
      if (role == 'labour') {
          Navigator.pushReplacementNamed(context, '/labour/home');
      } else if (role == 'admin') {
          Navigator.pushReplacementNamed(context, '/admin/dashboard'); 
      } else {
          debugPrint("Splash: Role not explicit or customer. Redirecting to Customer Home.");
          Navigator.pushReplacementNamed(context, '/customer/home');
      }
    } else {
      debugPrint("Splash: No token. Redirecting to Login.");
      Navigator.pushReplacementNamed(context, '/customer/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // App Logo placeholder
            LogoWidget(height: 150),

            SizedBox(height: 20),

            Text(
              "Karmigo",
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Karmigo – Kaam ke liye kaamgar, turant!",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                fontStyle: FontStyle.italic,
                color: Colors.grey[700],
              ),
            ),

            SizedBox(height: 10),

            CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}
