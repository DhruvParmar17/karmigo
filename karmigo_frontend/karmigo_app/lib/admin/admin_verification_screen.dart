import 'package:flutter/material.dart';
import '../../services/api_service.dart';

class AdminVerificationScreen extends StatefulWidget {
  const AdminVerificationScreen({super.key});

  @override
  State<AdminVerificationScreen> createState() => _AdminVerificationScreenState();
}

class _AdminVerificationScreenState extends State<AdminVerificationScreen> {
  Map<String, dynamic> _stats = {};

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    setState(() {
      _verificationsFuture = ApiService.getPendingVerifications();
    });
    _loadStats();
  }

  Future<void> _loadStats() async {
    try {
      final stats = await ApiService.getAdminStats();
      if (mounted) setState(() => _stats = stats);
    } catch (e) {
      debugPrint("Error loading stats: $e");
    }
  }

  Future<void> _approve(String labourId) async {
    try {
      await ApiService.approveVerification(labourId);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Approved")));
      _loadData();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  Future<void> _reject(String labourId) async {
    final reasonController = TextEditingController();
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Reject Verification"),
        content: TextField(
          controller: reasonController,
          decoration: const InputDecoration(labelText: "Reason"),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await ApiService.rejectVerification(labourId, reasonController.text);
                 if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Rejected")));
                    _loadData();
                 }
              } catch (e) {
                 if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
              }
            },
            child: const Text("Reject"),
          ),
        ],
      )
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Pending Verifications")),
      body: Column(
        children: [
          if (_stats.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(12),
              color: Colors.blue[50],
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                   _buildSummaryItem("Total", "${_stats['labour']?['total'] ?? 0}"),
                   _buildSummaryItem("Verified", "${_stats['labour']?['verified'] ?? 0}"),
                   _buildSummaryItem("Available", "${_stats['labour']?['available'] ?? 0}"),
                ],
              ),
            ),
          Expanded(
            child: FutureBuilder<List<dynamic>>(
              future: _verificationsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          if (snapshot.hasError) return Center(child: Text("Error: ${snapshot.error}"));
          
          final list = snapshot.data ?? [];
          if (list.isEmpty) return const Center(child: Text("No pending verifications"));

          return ListView.builder(
            itemCount: list.length,
            itemBuilder: (context, index) {
              final item = list[index];
              return Card(
                margin: const EdgeInsets.all(10),
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Labour: ${item['full_name']}", style: const TextStyle(fontWeight: FontWeight.bold)),
                      Text("Phone: ${item['phone']}"),
                      Text("Aadhaar: ${item['aadhaar_number_masked'] ?? 'N/A'}"),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () => _reject(item['id']), 
                            child: const Text("Reject", style: TextStyle(color: Colors.red))
                          ),
                          const SizedBox(width: 10),
                          ElevatedButton(
                            onPressed: () => _approve(item['id']),
                            child: const Text("Approve"),
                          ),
                        ],
                      )
                    ],
                  ),
                ),
              );
            },
          );
        },
          ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blue)),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }
}
