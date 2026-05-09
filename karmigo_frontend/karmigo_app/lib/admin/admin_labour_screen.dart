import 'package:flutter/material.dart';
import 'package:karmigo_app/core/app_translations.dart';
import '../../services/api_service.dart';
import '../../widgets/language_switcher_button.dart';

class AdminLabourScreen extends StatefulWidget {
  const AdminLabourScreen({super.key});

  @override
  State<AdminLabourScreen> createState() => _AdminLabourScreenState();
}

class _AdminLabourScreenState extends State<AdminLabourScreen> {
  List<dynamic> _labours = [];
  List<dynamic> _jobs = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      setState(() => _isLoading = true);
      final response = await ApiService.getAllLabours();
      final labours = response is List ? response : (response as Map<String, dynamic>)['labour'] as List? ?? [];
      
      if (mounted) {
        setState(() {
          _labours = labours;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // Removed _getLabourStats because stats are now fetched from backend directly

  Future<void> _toggleVerification(String labourId, bool currentStatus) async {
    setState(() => _isLoading = true);
    try {
      if (currentStatus) {
        // Assume verified -> block/reject
        await ApiService.rejectVerification(labourId, "Blocked by Admin");
      } else {
        await ApiService.approveVerification(labourId);
      }
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppTranslations.tr("status_updated"))));
      _loadData();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
      if (mounted) setState(() => _isLoading = false);
    } 
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppTranslations.tr("manage_labour")), 
        automaticallyImplyLeading: false,
        actions: const [
          LanguageSwitcherButton(),
        ],
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : ListView.builder(
            itemCount: _labours.length,
            padding: const EdgeInsets.all(16),
            itemBuilder: (context, index) {
              final l = _labours[index];
              final isVerified = l['is_verified'] ?? false;
              final balance = l['wallet_balance'] ?? 0.0;
              final int activeJobs = l['active_jobs'] ?? 0;
              final int completedJobs = l['completed_jobs'] ?? 0;
              final isActive = activeJobs > 0;
              
              // Inferred Availability
              final statusText = isActive ? "Busy" : "Free";
              final statusColor = isActive ? Colors.orange : Colors.green;

              return Card(
                elevation: 2,
                margin: const EdgeInsets.only(bottom: 12),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    children: [
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: CircleAvatar(
                          backgroundColor: isVerified ? Colors.green : Colors.grey,
                          child: const Icon(Icons.person, color: Colors.white),
                        ),
                        title: Text(l['full_name'] ?? l['username'] ?? "Unknown", style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text(l['email'] ?? ""),
                        trailing: PopupMenuButton<String>(
                          onSelected: (val) {
                             if (val == 'verify') _toggleVerification(l['id'].toString(), isVerified);
                             // To Do: Implement Ban / Reset features as specified
                          },
                           itemBuilder: (context) => [
                            PopupMenuItem(
                              value: 'verify', 
                              child: Text(isVerified ? AppTranslations.tr("reject") : AppTranslations.tr("approve"), style: TextStyle(color: isVerified ? Colors.red : Colors.green))
                            ),
                            PopupMenuItem(value: 'block', child: Text("Block", style: const TextStyle(color: Colors.orange))),
                            PopupMenuItem(value: 'ban', child: Text("Ban", style: const TextStyle(color: Colors.red))),
                          ],
                        ),
                      ),
                      const Divider(),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                           Column(
                             crossAxisAlignment: CrossAxisAlignment.start,
                             children: [
                               Text("Wallet: ₹$balance", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
                               const SizedBox(height: 4),
                               Row(
                                 children: [
                                   Icon(Icons.circle, size: 10, color: statusColor),
                                   const SizedBox(width: 4),
                                   Text("$statusText (Inferred)", style: const TextStyle(fontSize: 12, color: Colors.grey)),
                                 ],
                               )
                             ],
                           ),
                           Row(
                             children: [
                               _buildStatBadge("Active", activeJobs.toString(), Colors.orange),
                               const SizedBox(width: 8),
                               _buildStatBadge("Done", completedJobs.toString(), Colors.green),
                             ],
                           )
                        ],
                      )
                    ],
                  ),
                ),
              );
            },
          ),
    );
  }
  
  Widget _buildStatBadge(String label, String count, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.5))
      ),
      child: Column(
        children: [
          Text(count, style: TextStyle(fontWeight: FontWeight.bold, color: color)),
          Text(label, style: TextStyle(fontSize: 10, color: color)),
        ],
      ),
    );
  }
}
