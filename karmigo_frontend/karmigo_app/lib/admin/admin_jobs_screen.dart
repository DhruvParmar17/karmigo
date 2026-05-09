import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../theme/porter_theme.dart';
import '../../widgets/language_switcher_button.dart';
import 'admin_job_detail_screen.dart';
import 'admin_map_screen.dart';

class AdminJobsScreen extends StatefulWidget {
  const AdminJobsScreen({super.key});

  @override
  State<AdminJobsScreen> createState() => _AdminJobsScreenState();
}

class _AdminJobsScreenState extends State<AdminJobsScreen> {
  List<dynamic> _allJobs = [];
  List<dynamic> _filteredJobs = [];
  List<dynamic> _labours = [];
  bool _isLoading = true;
  String _filter = "All"; // All, Pending, Assigned, Completed

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      setState(() => _isLoading = true);
      // Fetch filtered jobs directly from backend
      final jobs = await ApiService.getAllJobs(status: _filter);
      final labours = await ApiService.getAllLabours();
      
      if (mounted) {
        setState(() {
          _allJobs = jobs; // Now contains filtered list from backend
          _labours = labours;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // Remove local filtering since we do it on backend now
  // _applyFilter function removed/deprecated in favor of API param

  String _getLabourName(var labourId) {
    if (labourId == null) return "Unassigned";
    final labour = _labours.firstWhere(
      (l) => l['id'].toString() == labourId.toString(), 
      orElse: () => null
    );
    return labour != null ? (labour['full_name'] ?? labour['email']) : "Unknown ID: $labourId";
  }

  Future<void> _assignLabourDialog(String jobId) async {
    String? selectedLabourId;
    
    // Calculate availability details
    final activeJobLabourIds = _allJobs.where((j) {
        final s = j['order_status'].toString().toLowerCase();
        return s == 'assigned' || s == 'in_progress';
    }).map((j) => j['labour_id'].toString()).toSet();

    await showDialog(
      context: context, 
      builder: (context) {
        return AlertDialog(
          title: const Text("Force Assign Labour"),
          content: SizedBox(
            width: double.maxFinite,
            height: 400, // Fixed height for list
            child: _labours.isEmpty 
              ? const Center(child: Text("No labours found."))
              : ListView.builder(
              shrinkWrap: true,
              itemCount: _labours.length,
              itemBuilder: (context, index) {
                final l = _labours[index];
                final lid = l['id'].toString();
                final isBusy = activeJobLabourIds.contains(lid);
                final statusText = isBusy ? "Busy (On Job)" : "Available";
                final statusColor = isBusy ? Colors.red : Colors.green;

                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  child: ListTile(
                    isThreeLine: true,
                    title: Text(l['full_name'] ?? "Unknown", style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Email: ${l['email'] ?? '-'}"),
                        Text("Phone: ${l['phone'] ?? '-'}"),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                             Icon(Icons.circle, size: 12, color: statusColor),
                             const SizedBox(width: 6),
                             Text(statusText, style: TextStyle(color: statusColor, fontWeight: FontWeight.bold)),
                          ],
                        )
                      ],
                    ),
                    trailing: isBusy 
                      ? null 
                      : ElevatedButton(
                          style: ElevatedButton.styleFrom(backgroundColor: PorterTheme.primaryColor),
                          onPressed: () {
                             selectedLabourId = lid;
                             Navigator.pop(context);
                          },
                          child: const Text("Assign", style: TextStyle(color: Colors.white)),
                        ),
                    onTap: isBusy ? null : () {
                      selectedLabourId = lid;
                      Navigator.pop(context);
                    },
                  ),
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            )
          ],
        );
      }
    );

    if (selectedLabourId != null) {
      try {
        await ApiService.adminAssignJob(jobId, selectedLabourId!);
        _loadData(); // Refresh
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Assigned Successfully")));
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
      }
    }
  }

  Future<void> _updateJobStatus(String jobId, String newStatus) async {
      try {
        setState(() => _isLoading = true);
        await ApiService.updateJobStatus(jobId: jobId, status: newStatus);
        _loadData();
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Job marked as $newStatus")));
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error updating status: $e")));
        setState(() => _isLoading = false);
      }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Manage Jobs"),
        automaticallyImplyLeading: false,
        actions: [
          const LanguageSwitcherButton(),
          IconButton(
            icon: const Icon(Icons.map),
            tooltip: "View Map",
            onPressed: () {
               Navigator.push(
                 context,
                 MaterialPageRoute(builder: (_) => const AdminMapScreen()),
               );
            },
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.filter_list),
            onSelected: (val) {
              setState(() {
                _filter = val;
                _loadData(); // Reload from backend with new filter
              });
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: "All", child: Text("All")),
              const PopupMenuItem(value: "Pending", child: Text("Pending")),
              const PopupMenuItem(value: "Assigned", child: Text("Assigned")),
              const PopupMenuItem(value: "In_Progress", child: Text("In Progress")),
              const PopupMenuItem(value: "Completed", child: Text("Completed")),
              const PopupMenuItem(value: "Cancelled", child: Text("Cancelled")),
            ],
          )
        ],
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
            scrollDirection: Axis.vertical,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                headingRowColor: MaterialStateProperty.all(Colors.blueGrey[50]),
                columns: const [
                  DataColumn(label: Text("Job title", style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text("Customer", style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text("Address", style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text("Amount", style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text("Payment", style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text("Status", style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text("Actions", style: TextStyle(fontWeight: FontWeight.bold))),
                ],
                rows: _allJobs.map((job) {
                   final status = job['order_status'].toString().toLowerCase();
                   final required = job['required_labours'] ?? 1;
                   final accepted = job['accepted_labour_count'] ?? 0;
                   return DataRow(cells: [
                      // Job title / id equivalent
                      DataCell(
                         Column(
                           mainAxisAlignment: MainAxisAlignment.center,
                           crossAxisAlignment: CrossAxisAlignment.start,
                           children: [
                             Text(job['title'] ?? 'Job', style: const TextStyle(fontWeight: FontWeight.bold)),
                             Text("Labours: $accepted / $required", style: const TextStyle(fontSize: 11, color: Colors.blueGrey))
                           ]
                         )
                      ),
                      // Customer
                      DataCell(
                        Column(
                           mainAxisAlignment: MainAxisAlignment.center,
                           crossAxisAlignment: CrossAxisAlignment.start,
                           children: [
                              Text(job['customer_name'] ?? 'Unknown'),
                              Text(job['customer_phone'] ?? 'No Phone', style: const TextStyle(fontSize: 10, color: Colors.grey))
                           ]
                        )
                      ),
                      // Address
                      DataCell(SizedBox(width: 150, child: Text(job['location'] ?? 'No Address', maxLines: 2, overflow: TextOverflow.ellipsis))),
                      // Amount
                      DataCell(Text('₹${job['total_amount']?.toString() ?? '0.0'}')),
                      // Payment 
                      DataCell(
                        Column(
                           mainAxisAlignment: MainAxisAlignment.center,
                           crossAxisAlignment: CrossAxisAlignment.start,
                           children: [
                              Text(job['payment_method']?.toString().toUpperCase() ?? 'ONLINE'),
                              Text(job['payment_status']?.toString().toUpperCase() ?? 'PENDING', 
                                   style: TextStyle(fontSize: 10, color: (job['payment_status'] == 'paid' ? Colors.green : Colors.red), fontWeight: FontWeight.bold)),
                           ],
                        )
                      ),
                      // Status
                      DataCell(Text(status.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold))),
                      // Actions
                      DataCell(
                         Row(
                           children: [
                             TextButton(
                               onPressed: () async {
                                 await Navigator.push(context, MaterialPageRoute(builder: (_) => AdminJobDetailScreen(job: job)));
                                 _loadData();
                               },
                               child: const Text("View"),
                             ),
                             if (status == 'pending')
                                IconButton(icon: const Icon(Icons.person_add, color: Colors.blue), tooltip: "Force Assign", onPressed: () => _assignLabourDialog(job['id'].toString())),
                             if (status == 'assigned' || status == 'in_progress')
                                IconButton(icon: const Icon(Icons.check_circle, color: Colors.green), tooltip: "Mark Complete", onPressed: () => _updateJobStatus(job['id'].toString(), "completed")),
                             if (status == 'pending' || status == 'assigned' || status == 'in_progress')
                                IconButton(icon: const Icon(Icons.cancel, color: Colors.red), tooltip: "Cancel Job", onPressed: () => _updateJobStatus(job['id'].toString(), "cancelled")),
                           ],
                         )
                      )
                   ]);
                }).toList(),
              ),
            ),
          ),
    );
  }

  Widget _buildJobCard(dynamic job) {
    final status = job['order_status'].toString().toLowerCase();
    
    // Safety check for keys
    final required = job['required_labours'] ?? 1;
    final accepted = job['accepted_labour_count'] ?? 0;
    final remaining = required - accepted;
    
    // Status Logic for Color
    Color statusColor;
    if (status == 'pending') statusColor = Colors.orange;
    else if (status == 'assigned') statusColor = Colors.blue;
    else if (status == 'in_progress') statusColor = Colors.indigo;
    else if (status == 'completed') statusColor = Colors.green;
    else if (status == 'cancelled') statusColor = Colors.red;
    else statusColor = Colors.grey;

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: statusColor.withOpacity(0.5), width: 1)
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                  Expanded(
                    child: Row(
                      children: [
                        Text(job['title'] ?? "Job", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        if (job['payment_status'] == 'paid' || (job['billing'] != null && job['billing']['payment_status'] == 'paid')) ...[
                           const SizedBox(width: 8),
                           Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(color: Colors.green[100], borderRadius: BorderRadius.circular(4)),
                              child: Text("PAID", style: TextStyle(color: Colors.green[800], fontSize: 10, fontWeight: FontWeight.bold)),
                           ),
                        ]
                      ],
                    )
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(color: statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                    child: Text(status.toUpperCase(), style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 12)),
                  )
              ],
            ),
            const Divider(),
            Row(
              children: [
                const Icon(Icons.location_on, size: 16, color: Colors.grey),
                const SizedBox(width: 4),
                Expanded(child: Text(job['location'] ?? "No location", maxLines: 1, overflow: TextOverflow.ellipsis)),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                     const Icon(Icons.group, size: 16, color: Colors.blueGrey),
                     const SizedBox(width: 4),
                     Text("Labour: $accepted / $required", style: const TextStyle(fontWeight: FontWeight.bold)),
                     if (remaining > 0 && status != 'completed' && status != 'cancelled')
                        Text(" ($remaining left)", style: const TextStyle(color: Colors.redAccent, fontSize: 12)),
                  ],
                ),
                TextButton(
                  onPressed: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => AdminJobDetailScreen(job: job)),
                    );
                    _loadData();
                  },
                  child: const Text("View Details"),
                ),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (status == 'pending')
                  OutlinedButton.icon(
                    icon: const Icon(Icons.person_add, size: 16),
                    label: const Text("Force Assign"),
                    style: OutlinedButton.styleFrom(foregroundColor: Colors.blue),
                    onPressed: () => _assignLabourDialog(job['id'].toString()),
                  ),
                if (status == 'pending' || status == 'assigned' || status == 'in_progress') ...[
                  const SizedBox(width: 8),
                  OutlinedButton.icon(
                    icon: const Icon(Icons.cancel, size: 16),
                    label: const Text("Cancel"),
                    style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                    onPressed: () => _updateJobStatus(job['id'].toString(), "cancelled"),
                  ),
                 ],
                 if (status == 'assigned' || status == 'in_progress') ...[
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.check_circle, size: 16),
                      label: const Text("Complete"),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                      onPressed: () => _updateJobStatus(job['id'].toString(), "completed"),
                    )
                 ]
              ],
            )
          ],
        ),
      ),
    );
  }
}
