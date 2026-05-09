import 'package:flutter/material.dart';
import 'step1_identity.dart';

class VerificationLanding extends StatelessWidget {
  const VerificationLanding({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Verification Required")),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.verified_user, size: 80, color: Colors.orange),
            const SizedBox(height: 20),
            const Text(
              "Complete Your Profile",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            const Text(
              "To start accepting jobs and earning money, we need to verify your identity. This helps keep our platform safe for everyone.",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 10),
            const Text(
               "Required:\n• Aadhaar Card\n• Selfie\n• Address Details\n• Bank / UPI Details",
               textAlign: TextAlign.center, 
               style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const Step1Identity()),
                  );
                },
                child: const Text("Start Verification"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
