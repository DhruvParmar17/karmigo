import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../core/auth_state.dart';

class LabourDashboard extends StatefulWidget {
  const LabourDashboard({super.key});

  @override
  State<LabourDashboard> createState() => _LabourDashboardState();
}

class _LabourDashboardState extends State<LabourDashboard> {
  late Future<List<dynamic>> jobsFuture;

  @override
  void initState() {
    super.initState();
    jobsFuture = ApiService.getMyJobs(); // reuse same API
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Labour Dashboard")),
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
                child: ListTile(
                  title: Text(job['title']),
                  subtitle: Text(
                    "Location: ${job['location']}\nStatus: ${job['order_status']}",
                  ),
                  trailing: job['order_status'] == 'pending'
                      ? ElevatedButton(
                          onPressed: () async {
                            try {
                              if (AuthState.userId == null) {
                                throw Exception("User ID not found. Please relogin.");
                              }
                              await ApiService.assignJobToLabour(
                                job['id'].toString(),
                              );

                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text("Job accepted successfully!"),
                                    backgroundColor: Colors.green,
                                  ),
                                );
                                setState(() {
                                  jobsFuture = ApiService.getMyJobs();
                                });
                              }
                            } catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text("Error: $e"),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            }
                          },
                          child: const Text("Accept"),
                        )
                      : const Text("Taken"),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
