import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../theme/porter_theme.dart';
import '../../core/auth_state.dart';
import '../../core/app_translations.dart';
import '../../widgets/top_bar_actions.dart';
import 'labour_job_detail_screen.dart';
import 'verification/verification_wrapper.dart';

class LabourAvailableJobsScreen extends StatefulWidget {
  const LabourAvailableJobsScreen({super.key});

  @override
  State<LabourAvailableJobsScreen> createState() => _LabourAvailableJobsScreenState();
}

class _LabourAvailableJobsScreenState extends State<LabourAvailableJobsScreen> {
  late Future<List<dynamic>> _jobsFuture;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _loadJobs();
  }

  void _loadJobs() {
    setState(() {
      _jobsFuture = ApiService.getJobs(status: "pending");
    });
  }

  Future<void> _acceptJob(String jobId) async {
    // PRE-CHECK: Verification
    try {
      final statusData = await ApiService.getVerificationStatus();
      if (statusData['status'] != 'verified') {
        if (!mounted) return;
        _showVerificationDialog();
        return;
      }
    } catch (e) {
      // If check fails, maybe allow backend to block? 
      // But safer to block or show error.
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Could not verify account status. Please try again.")),
      );
      return;
    }

    setState(() => _isProcessing = true);
    try {
      if (AuthState.userId == null) {
        throw Exception("You are not logged in.");
      }
      
      await ApiService.assignJobToLabour(jobId);
      
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppTranslations.tr("status_updated"))),
      );
      
      _loadJobs(); 

    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  void _showVerificationDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Verification Required"),
        content: const Text("You must complete verification to accept jobs."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
               Navigator.push(context, MaterialPageRoute(builder: (_) => const VerificationWrapper()));
            }, 
            child: const Text("Verify Now")
          ),
        ],
      )
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppTranslations.tr("available_jobs")),
        automaticallyImplyLeading: false,
        actions: [
          const TopBarActions(),
        ],
      ),
      body: FutureBuilder<List<dynamic>>(
        future: _jobsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }

          final jobs = snapshot.data ?? [];
          // Double check status client side if needed
          final pendingJobs = jobs.where((j) => 
            j['order_status'].toString().toLowerCase() == 'pending'
          ).toList();

          if (pendingJobs.isEmpty) {
            return Center(child: Text(AppTranslations.tr("no_jobs_available") == "no_jobs_available" ? "No jobs available" : AppTranslations.tr("no_jobs_available")));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: pendingJobs.length,
            itemBuilder: (context, index) {
              return _buildJobCard(pendingJobs[index]);
            },
          );
        },
      ),
    );
  }

  Widget _buildJobCard(dynamic job) {
    // fields
    final String title = job['title'] ?? 'Job';
    final String location = job['location'] ?? 'Unknown Location';
    final String status = "PENDING";
    
    // Slots
    final int required = job['required_labours'] ?? 1;
    final int filled = job['accepted_labours_count'] ?? 0;
    
    // Payment Logic
    // per_labour_net should be available from backend now
    final double? earning = (job['per_labour_earning'] ?? job['per_labour_net']) != null 
        ? ((job['per_labour_earning'] ?? job['per_labour_net']) as num).toDouble() 
        : null;

    final bool isEarningAvailable = earning != null && earning > 0;
    final String earningText = isEarningAvailable ? "₹${earning.toStringAsFixed(0)}" : "Calculating...";

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 16),
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
              // Title & Status
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                        fontSize: 18, 
                        fontWeight: FontWeight.bold,
                        color: PorterTheme.textColor
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: Colors.orange),
                    ),
                    child: Text(
                      AppTranslations.tr("pending").toUpperCase(),
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.orange),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              
              // Location
              Row(
                children: [
                  const Icon(Icons.location_on_outlined, size: 16, color: Colors.grey),
                  const SizedBox(width: 4),
                  Expanded(child: Text(location, style: const TextStyle(color: Colors.black87))),
                ],
              ),
              const SizedBox(height: 12),

              // Slots & Earnings Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                   Column(
                     crossAxisAlignment: CrossAxisAlignment.start,
                     children: [
                       Text(AppTranslations.tr("net_earning"), style: const TextStyle(fontSize: 12, color: Colors.grey)),
                       Text(
                         earningText,
                         style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green),
                       ),
                     ],
                   ),
                   Column(
                     crossAxisAlignment: CrossAxisAlignment.end,
                     children: [
                       Text(AppTranslations.tr("slots"), style: const TextStyle(fontSize: 12, color: Colors.grey)),
                       Text(
                         "$filled / $required", 
                         style: TextStyle(
                           fontSize: 16, 
                           fontWeight: FontWeight.bold,
                           color: filled >= required ? Colors.red : Colors.black87
                         )
                       ),
                     ],
                   )
                ],
              ),
              
              const SizedBox(height: 16),
              
              // Actions
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isProcessing ? null : () => _acceptJob(job['id'].toString()),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: _isProcessing 
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : Text(AppTranslations.tr("accept").toUpperCase()),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
