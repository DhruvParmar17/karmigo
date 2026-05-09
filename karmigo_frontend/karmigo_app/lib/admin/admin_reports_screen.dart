import 'package:flutter/material.dart';
import '../services/api_service.dart';

class AdminReportsScreen extends StatefulWidget {
  const AdminReportsScreen({super.key});

  @override
  State<AdminReportsScreen> createState() => _AdminReportsScreenState();
}

class _AdminReportsScreenState extends State<AdminReportsScreen> {
  Future<Map<String, dynamic>>? _statsFuture;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  void _loadStats() {
    setState(() {
      _statsFuture = _calculateStats();
    });
  }

  Future<Map<String, dynamic>> _calculateStats() async {
    try {
      final futures = await Future.wait([
        ApiService.getAllUsers(),
        ApiService.getAllLabours(),
        ApiService.getAllJobs(),
      ]);
      
      final users = futures[0] as List;
      final labours = futures[1] as List;
      final jobs = futures[2] as List;
      
      int pending = jobs.where((j) => j['order_status'] == 'pending').length;
      int assigned = jobs.where((j) => j['order_status'] == 'assigned').length;
      int completed = jobs.where((j) => j['order_status'] == 'completed').length;
      
      return {
        'users': users.length,
        'labour': labours.length,
        'jobs': {
          'total': jobs.length,
          'pending': pending,
          'assigned': assigned,
          'completed': completed,
        }
      };
    } catch (e) {
      return {
        'users': 0, 'labour': 0,
        'jobs': {'total': 0, 'pending': 0, 'assigned': 0, 'completed': 0}
      };
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Admin Reports")),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _statsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }

          if (!snapshot.hasData) {
            return const Center(child: Text("No data available"));
          }

          final stats = snapshot.data!;
          final jobs = stats['jobs'];

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("User Statistics", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(child: _buildStatCard("Total Users", stats['users'].toString(), Colors.blueGrey)),
                    Expanded(child: _buildStatCard("Total Labour", stats['labour'].toString(), Colors.teal)),
                  ],
                ),
                const SizedBox(height: 20),
                const Text("Job Statistics", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                _buildStatCard("Total Jobs", jobs['total'].toString(), Colors.indigo),
                
                const SizedBox(height: 10),
                GridView.count(
                  crossAxisCount: 3,
                  shrinkWrap: true,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    _buildStatCard("Pending", jobs['pending'].toString(), Colors.orange),
                    _buildStatCard("Assigned", jobs['assigned'].toString(), Colors.blue),
                    _buildStatCard("Completed", jobs['completed'].toString(), Colors.green),
                  ],
                ),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _loadStats,
        child: const Icon(Icons.refresh),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, Color color) {
    return Card(
      color: color.withOpacity(0.1),
      shape: RoundedRectangleBorder(
        side: BorderSide(color: color, width: 2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(value, style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: color)),
            const SizedBox(height: 5),
            Text(title, textAlign: TextAlign.center, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }
}
