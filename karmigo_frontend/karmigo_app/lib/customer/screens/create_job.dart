import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import 'my_jobs.dart'; // ✅ ADD THIS

class CreateJobScreen extends StatelessWidget {
  const CreateJobScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final workType = TextEditingController();
    final location = TextEditingController();
    final notes = TextEditingController();

    return Scaffold(
      appBar: AppBar(title: const Text("Create Job")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(
              controller: workType,
              decoration: const InputDecoration(labelText: "Work Type"),
            ),
            const SizedBox(height: 10),

            TextField(
              controller: location,
              decoration: const InputDecoration(labelText: "Location"),
            ),
            const SizedBox(height: 10),

            TextField(
              controller: notes,
              decoration: const InputDecoration(labelText: "Notes"),
            ),
            const SizedBox(height: 20),

            ElevatedButton(
              onPressed: () async {
                final wt = workType.text.trim();
                final loc = location.text.trim();
                final nt = notes.text.trim();

                if (wt.isEmpty || loc.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Work type & location required"),
                    ),
                  );
                  return;
                }

                try {
                  await ApiService.createJob(
                    title: wt,        // backend: title
                    description: nt,  // backend: description
                    location: loc,
                  );

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Job created successfully"),
                    ),
                  );

                  // ✅ AUTO REDIRECT TO MY JOBS
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const MyJobsScreen(),
                    ),
                  );

                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(e.toString())),
                  );
                }
              },
              child: const Text("Submit Job"),
            ),
          ],
        ),
      ),
    );
  }
}
