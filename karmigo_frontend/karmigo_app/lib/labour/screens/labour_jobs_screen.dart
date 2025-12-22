import 'package:flutter/material.dart';
import '../../services/api_service.dart';

class LabourJobsScreen extends StatefulWidget {
  const LabourJobsScreen({super.key});

  @override
  State<LabourJobsScreen> createState() => _LabourJobsScreenState();
}

class _LabourJobsScreenState extends State<LabourJobsScreen> {
  late Future<List<dynamic>> jobsFuture;

  @override
  void initState() {
    super.initState();
    jobsFuture = ApiService.getMyJobs(); // pending jobs
  }

  void refreshJobs() {
    setState(() {
      jobsFuture = ApiService.getMyJobs();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Available Jobs")),
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
            return const Center(child: Text("No jobs available"));
          }

          return ListView.builder(
            itemCount: jobs.length,
            itemBuilder: (context, index) {
              final job = jobs[index];

              return Card(
                margin: const EdgeInsets.all(10),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Work: ${job['title']}"),
                      Text("Location: ${job['location']}"),
                      Text("Status: ${job['order_status']}"),

                      if (job['order_status'] == 'pending')
                        Align(
                          alignment: Alignment.centerRight,
                          child: ElevatedButton(
                            onPressed: () async {
                              try {
                                await ApiService.assignJobToLabour(
                                  job['id'],
                                );

                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text("Job accepted successfully"),
                                  ),
                                );

                                refreshJobs();
                              } catch (e) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text(e.toString())),
                                );
                              }
                            },
                            child: const Text("Accept Job"),
                          ),
                        ),
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
