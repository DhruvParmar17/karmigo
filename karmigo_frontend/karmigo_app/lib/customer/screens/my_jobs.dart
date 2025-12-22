import 'package:flutter/material.dart';
import '../../services/api_service.dart';

class MyJobsScreen extends StatefulWidget {
  const MyJobsScreen({super.key});

  @override
  State<MyJobsScreen> createState() => _MyJobsScreenState();
}

class _MyJobsScreenState extends State<MyJobsScreen> {
  late Future<List<dynamic>> jobsFuture;

  @override
  void initState() {
    super.initState();
    jobsFuture = ApiService.getMyJobs();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("My Jobs")),
      body: FutureBuilder<List<dynamic>>(
        future: jobsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text(snapshot.error.toString()));
          }

          final jobs = snapshot.data!;

          if (jobs.isEmpty) {
            return const Center(child: Text("No jobs found"));
          }

          return ListView.builder(
            itemCount: jobs.length,
            itemBuilder: (context, index) {
              final job = jobs[index];

              return Card(
                margin: const EdgeInsets.all(10),
                child: ListTile(
                  title: Text(job['title'] ?? "No title"),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Location: ${job['location']}"),
                      Text("Status: ${job['order_status']}"),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
