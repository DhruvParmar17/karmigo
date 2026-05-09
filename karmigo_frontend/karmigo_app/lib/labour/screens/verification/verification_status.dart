import 'package:flutter/material.dart';
import '../labour_main_screen.dart';
import 'step1_identity.dart'; // To retry

class VerificationStatusScreen extends StatelessWidget {
  final String status;
  final String? reason;

  const VerificationStatusScreen({super.key, required this.status, this.reason});

  @override
  Widget build(BuildContext context) {
    bool isRejected = status == "rejected";

    return Scaffold(
      appBar: AppBar(title: const Text("Verification Status")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isRejected ? Icons.error_outline : Icons.hourglass_top,
              size: 80,
              color: isRejected ? Colors.red : Colors.orange,
            ),
            const SizedBox(height: 20),
            Text(
              isRejected ? "Verification Rejected" : "Verification Pending",
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Text(
              isRejected 
                ? "Reason: ${reason ?? 'Documents invalid'}"
                : "Your documents are under review. This usually takes 24-48 hours. You will be notified once approved.",
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 30),
            
            if (isRejected)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    // Retry
                    Navigator.pushReplacement(
                        context, MaterialPageRoute(builder: (_) => const Step1Identity()));
                  },
                  child: const Text("Re-submit Documents"),
                ),
              ),
            
            const SizedBox(height: 10),
            
            TextButton(
              onPressed: () {
                 // Browse only
                 Navigator.pushReplacement(
                   context, MaterialPageRoute(builder: (_) => const LabourMainScreen()),
                 );
              },
              child: const Text("Go to Dashboard (Restricted Access)"),
            ),
          ],
        ),
      ),
    );
  }
}
