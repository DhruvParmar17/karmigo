import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../core/auth_state.dart';
import 'labour_dashboard.dart';
import '../../customer/screens/login_screen.dart';
import '../../customer/screens/signup_screen.dart';

class LabourLogin extends StatelessWidget {
  final email = TextEditingController();
  final password = TextEditingController();

  LabourLogin({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Labour Login")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(
              controller: email,
              decoration: const InputDecoration(labelText: "Email"),
            ),

            const SizedBox(height: 10),

            TextField(
              controller: password,
              decoration: const InputDecoration(labelText: "Password"),
              obscureText: true,
            ),

            const SizedBox(height: 20),

            ElevatedButton(
              onPressed: () async {
                final userEmail = email.text.trim();
                final userPassword = password.text.trim();

                if (userEmail.isEmpty || userPassword.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Please enter email & password"),
                    ),
                  );
                  return;
                }

                try {
                  // 🔐 LOGIN API
                  final response =
                      await ApiService.login(userEmail, userPassword);

                  // ✅ SAVE AUTH DATA (CLEAN WAY)
                  await AuthState.setAuthData(
                    accessToken: response['access_token'],
                    userRole: response['role'],
                    id: response['user_id'] ?? response['id'],
                  );

                  if (context.mounted) {
                    // ✅ NAVIGATE TO LABOUR DASHBOARD
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const LabourDashboard(),
                      ),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(e.toString())),
                    );
                  }
                }
              },
              child: const Text("Login"),
            ),

            const SizedBox(height: 20),

            TextButton(
              onPressed: () {
                 Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (_) => LoginScreen(),
                    ),
                  );
              },
              child: const Text("Not a labour? Login as customer"),
            ),

            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => SignupScreen()),
                );
              },
              child: const Text("Don't have an account? Sign Up"),
            ),
          ],
        ),
      ),
    );
  }
}
