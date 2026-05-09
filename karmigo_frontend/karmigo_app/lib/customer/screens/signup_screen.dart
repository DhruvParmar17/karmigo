import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../widgets/logo_widget.dart';

class SignupScreen extends StatelessWidget {
  final email = TextEditingController();
  final password = TextEditingController();

  SignupScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Sign Up")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const LogoWidget(),
            const SizedBox(height: 20),
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
                        content: Text("Please enter email & password")),
                  );
                  return;
                }

                try {
                  await ApiService.signup(userEmail, userPassword);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Account created! Please login.")),
                  );
                  Navigator.pop(context); // Go back to login
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(e.toString())),
                  );
                }
              },
              child: const Text("Sign Up"),
            ),
          ],
        ),
      ),
    );
  }
}
