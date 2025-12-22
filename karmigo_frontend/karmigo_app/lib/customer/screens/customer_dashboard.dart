import 'package:flutter/material.dart';
import '../../core/auth_state.dart';
import '../screens/create_job.dart';
import '../screens/my_jobs.dart';
import '../../customer/screens/login_screen.dart';
import '../../labour/screens/labour_dashboard.dart'; // ✅ NEW IMPORT

class CustomerDashboard extends StatelessWidget {
  const CustomerDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Customer Dashboard"),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              AuthState.clear();
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => LoginScreen()),
                (route) => false,
              );
            },
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              "Welcome to Karmigo 👋",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 30),

            // ======================
            // CREATE JOB
            // ======================
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const CreateJobScreen()),
                );
              },
              child: const Text("Create Job"),
            ),

            const SizedBox(height: 15),

            // ======================
            // MY JOBS
            // ======================
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const MyJobsScreen()),
                );
              },
              child: const Text("My Jobs"),
            ),

            const SizedBox(height: 30),

            // ======================
            // LABOUR DASHBOARD (TEMP)
            // ======================
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const LabourDashboard(),
                  ),
                );
              },
              child: const Text(
                "Open Labour Dashboard (TEMP)",
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
