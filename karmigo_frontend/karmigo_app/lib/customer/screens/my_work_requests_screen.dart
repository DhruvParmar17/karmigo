import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../theme/porter_theme.dart';
import 'job_details_screen.dart';
import 'package:intl/intl.dart';

class MyWorkRequestsScreen extends StatefulWidget {
  const MyWorkRequestsScreen({super.key});

  @override
  State<MyWorkRequestsScreen> createState() => _MyWorkRequestsScreenState();
}

class _MyWorkRequestsScreenState extends State<MyWorkRequestsScreen> {
  late Future<List<dynamic>> jobsFuture;

  @override
  void initState() {
    super.initState();
    _loadJobs();
  }

  void _loadJobs() {
    // Strictly using existing ApiService.getMyJobs() as requested
    jobsFuture = ApiService.getMyJobs();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("My Work Requests")),
      body: RefreshIndicator(
        onRefresh: () async {
          setState(() {
            _loadJobs();
          });
          await jobsFuture;
        },
        child: FutureBuilder<List<dynamic>>(
          future: jobsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
  
            if (snapshot.hasError) {
              return Center(child: Text("Error: ${snapshot.error}"));
            }
  
            final jobs = snapshot.data!;
            if (jobs.isEmpty) {
              return _buildEmptyState();
            }
  
            // Sort by latest first (assuming id/created_at helps, or relying on backend order)
            final reversedJobs = jobs.reversed.toList();
  
            return ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              itemCount: reversedJobs.length,
              itemBuilder: (context, index) {
                final job = reversedJobs[index];
                return GestureDetector(
                  onTap: () async {
                     await Navigator.push(
                       context, 
                       MaterialPageRoute(builder: (_) => JobDetailsScreen(jobId: job['id']))
                     );
                     // Refresh list when coming back
                     setState(() {
                       _loadJobs();
                     });
                  },
                  child: _buildJobCard(job),
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Icon(Icons.assignment_outlined, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text("You haven't created any requests yet.", style: TextStyle(color: Colors.grey, fontSize: 16)),
        ],
      ),
    );
  }

  Widget _buildJobCard(dynamic job) {
    // Status Logic
    final rawStatus = (job['order_status'] ?? 'pending').toString().toLowerCase();
    
    // Status Mapping:
    // pending / searching  → Searching
    // assigned             → Assigned
    // on_the_way / started → In Progress
    // completed            → Completed
    // cancelled            → Cancelled
    
    String displayStatus = "Unknown";
    Color statusColor = Colors.grey;
    
    if (rawStatus == 'pending' || rawStatus == 'searching') {
        displayStatus = "Searching";
        statusColor = Colors.orange;
    } else if (rawStatus == 'assigned') {
        displayStatus = "Assigned";
        statusColor = Colors.blue;
    } else if (rawStatus == 'on_the_way' || rawStatus == 'started' || rawStatus == 'in_progress') {
        displayStatus = "In Progress";
        statusColor = Colors.purple;
    } else if (rawStatus == 'completed') {
        displayStatus = "Completed";
        statusColor = Colors.green;
    } else if (rawStatus == 'cancelled') {
        displayStatus = "Cancelled";
        statusColor = Colors.red;
    } else {
        displayStatus = rawStatus.toUpperCase();
    }

    // Amount Display (Estimated or Final)
    // Try billing details if attached (sometimes backend might include it), else fallback to Order total
    final amount = job['total_amount'] ?? 0;

    // Date Formatting (Mocking if created_at string, else 'Now')
    String dateStr = "";
    try {
        if (job['created_at'] != null) {
            final dt = DateTime.parse(job['created_at']);
            dateStr = DateFormat("d MMM, h:mm a").format(dt);
        }
    } catch (_) {}

    return Card(
      elevation: 3,
      shadowColor: Colors.black12,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Row: Service Name + Status Badge
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    job['title'] ?? 'Service',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: PorterTheme.textColor,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: statusColor.withOpacity(0.5)),
                  ),
                  child: Text(
                    displayStatus,
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            // Location Row
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.location_on, size: 16, color: Colors.grey),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    job['location'] ?? 'No location',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.black87, fontSize: 13),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Date & Amount Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.calendar_today, size: 14, color: Colors.grey),
                    const SizedBox(width: 6),
                    Text(
                      dateStr.isNotEmpty ? dateStr : "Just Now",
                      style: const TextStyle(color: Colors.grey, fontSize: 13),
                    ),
                  ],
                ),
                Text(
                  "₹$amount",
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
