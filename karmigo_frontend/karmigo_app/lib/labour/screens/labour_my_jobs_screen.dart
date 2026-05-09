import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../core/app_translations.dart';
import '../../theme/porter_theme.dart';
import 'labour_job_detail_screen.dart';

class LabourMyJobsScreen extends StatefulWidget {
  const LabourMyJobsScreen({super.key});

  @override
  State<LabourMyJobsScreen> createState() => _LabourMyJobsScreenState();
}

class _LabourMyJobsScreenState extends State<LabourMyJobsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;
  List<dynamic> _activeJobs = [];
  List<dynamic> _completedJobs = [];
  List<dynamic> _cancelledJobs = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadJobs();
  }

  Future<void> _loadJobs() async {
    setState(() => _isLoading = true);
    try {
      final jobs = await ApiService.getLaborMyJobs();
      
      final active = <dynamic>[];
      final completed = <dynamic>[];
      final cancelled = <dynamic>[];

      for (var job in jobs) {
        final status = job['order_status'].toString().toLowerCase();
        
        if (status == 'assigned' || status == 'on_the_way' || status == 'reached' || status == 'started' || status == 'in_progress') {
          active.add(job);
        } else if (status == 'completed') {
          completed.add(job);
        } else if (status == 'cancelled') {
          cancelled.add(job);
        }
      }

      if (mounted) {
        setState(() {
          _activeJobs = active;
          _completedJobs = completed;
          _cancelledJobs = cancelled;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
      print("Error loading my jobs: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppTranslations.tr("my_jobs")),
        automaticallyImplyLeading: false,
        bottom: TabBar(
          controller: _tabController,
          labelColor: PorterTheme.primaryColor,
          unselectedLabelColor: Colors.grey,
          indicatorColor: PorterTheme.primaryColor,
          tabs: [
            Tab(text: "Active"),
            Tab(text: "Completed"),
            Tab(text: "Cancelled"),
          ],
        ),
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : TabBarView(
            controller: _tabController,
            children: [
              _buildJobList(_activeJobs, "ongoing"),
              _buildJobList(_completedJobs, "completed"),
              _buildJobList(_cancelledJobs, "cancelled"),
            ],
          ),
    );
  }

  Widget _buildJobList(List<dynamic> jobs, String type) {
    if (jobs.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(type == "ongoing" ? Icons.work_outline : (type == "completed" ? Icons.check_circle_outline : Icons.cancel_outlined), size: 64, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(
              type == "ongoing" ? "No active jobs" : (type == "completed" ? "No completed jobs" : "No cancelled jobs"),
              style: TextStyle(color: Colors.grey[600], fontSize: 16),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadJobs,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: jobs.length,
        itemBuilder: (context, index) {
          final job = jobs[index];
          return _buildMyJobCard(job);
        },
      ),
    );
  }

  Widget _buildMyJobCard(dynamic job) {
    final status = job['order_status'].toString().toUpperCase();
    final double? earning = (job['per_labour_earning'] ?? job['per_labour_net']) != null 
        ? ((job['per_labour_earning'] ?? job['per_labour_net']) as num).toDouble() 
        : null;
    final String earningText = earning != null ? "₹${earning.toStringAsFixed(0)}" : "";

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => LabourJobDetailScreen(job: job)),
          );
          _loadJobs();
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      job['title'] ?? "Job",
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getStatusColor(status).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: _getStatusColor(status)),
                    ),
                    child: Text(
                      status,
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: _getStatusColor(status)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                   const Icon(Icons.location_on, size: 14, color: Colors.grey),
                   const SizedBox(width: 4),
                   Expanded(child: Text(job['location'] ?? "", style: const TextStyle(color: Colors.grey))),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (earningText.isNotEmpty)
                    Text(
                      earningText,
                      style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green, fontSize: 16),
                    ),
                  const Icon(Icons.chevron_right, color: Colors.grey),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'assigned': return Colors.blue; // Accepted
      case 'on_the_way': return Colors.indigo;
      case 'reached': return Colors.purple;
      case 'started': return Colors.deepOrange;
      case 'completed': return Colors.green;
      case 'cancelled': return Colors.red;
      default: return Colors.grey;
    }
  }
}
