
import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../theme/porter_theme.dart';
import 'package:url_launcher/url_launcher.dart';

class AdminJobDetailScreen extends StatefulWidget {
  final Map<String, dynamic> job;
  const AdminJobDetailScreen({super.key, required this.job});

  @override
  State<AdminJobDetailScreen> createState() => _AdminJobDetailScreenState();
}

class _AdminJobDetailScreenState extends State<AdminJobDetailScreen> {
  late Map<String, dynamic> _job;
  Map<String, dynamic>? _customer;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _job = widget.job;
    _loadAdditionalData();
  }
  
  Future<void> _loadAdditionalData() async {
     if (_job['user_id'] != null) {
        try {
           final users = await ApiService.getAllUsers();
           final user = users.firstWhere((u) => u['id'].toString() == _job['user_id'].toString(), orElse: () => null);
           if (mounted && user != null) {
              setState(() => _customer = user);
           }
        } catch (e) {
           debugPrint("Error loading customer: $e");
        }
     }
  }

  Future<void> _refreshJob() async {
    try {
      final jobs = await ApiService.getAllJobs();
      final fresh = jobs.firstWhere((j) => j['id'] == _job['id'], orElse: () => _job);
      if (mounted) setState(() => _job = fresh);
    } catch (e) {
      // safe fail
    }
  }

  Future<void> _markCompleted() async {
    // Safety check: Don't mark if already completed
    if (_job['order_status'].toString().toLowerCase() == 'completed') return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Mark Job Completed?"),
        content: const Text("This action will force status to 'completed'.\n\nEnsure payment is handled! Backend may block if unpaid."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true), 
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text("Complete"),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isLoading = true);
    try {
      await ApiService.updateJobStatus(jobId: _job['id'], status: 'completed');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Job Marked Completed!")));
        await _refreshJob();
      }
    } catch (e) {
      if (mounted) _showErrorDialog(e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _markPaymentPaid() async {
    final isPaid = (_job['payment_status'] == 'paid' || (_job['billing'] != null && _job['billing']['payment_status'] == 'paid'));
    if (isPaid) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Mark Payment as Paid?"),
        content: const Text("This will mark the job as PAID manually."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Cancel")),
          ElevatedButton(
             onPressed: () => Navigator.pop(ctx, true),
             style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
             child: const Text("Mark Paid"),
          ),
        ],
      )
    );

    if (confirm != true) return;

    setState(() => _isLoading = true);
    try {
      await ApiService.payAndCompleteJob(_job['id'].toString(), paymentMethod: "admin_manual");
      if (mounted) {
         ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Payment Marked Paid")));
         await _refreshJob();
      }
    } catch(e) {
      if (mounted) _showErrorDialog(e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
  
  void _showErrorDialog(String msg) {
     showDialog(
       context: context,
       builder: (ctx) => AlertDialog(
         title: const Text("Error"),
         content: Text(msg.replaceAll("Exception:", "").trim()),
         actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("OK"))],
       )
     );
  }

  // --- ACTIONS ---

  Future<void> _forceCancelJob() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Force Cancel Job?"),
        content: const Text("This will set stats to 'cancelled'. Only do this if the job cannot proceed."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("No")),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text("Yes, Cancel")),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isLoading = true);
    try {
      await ApiService.cancelJob(_job['id']);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Job Cancelled (Force)")));
        await _refreshJob();
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteJob() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Permanently Delete Job?"),
        content: const Text("This cannot be undone. It will remove the job record from the database."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true), 
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text("Delete"),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isLoading = true);
    try {
      await ApiService.deleteJob(_job['id']);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Job Deleted!")));
        Navigator.pop(context, true); // Return true to refresh list
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    
    final status = _job['order_status'].toString().toLowerCase();

    return Scaffold(
      appBar: AppBar(title: const Text("Job Details (Admin)")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                 Text("ID: ...${_job['id'].toString().substring(0,8)}", style: const TextStyle(color: Colors.grey)),
                 Chip(label: Text(status.toUpperCase()), backgroundColor: Colors.grey.shade200),
              ],
            ),
            const SizedBox(height: 16),
            
            Text(_job['title'] ?? 'Job', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 8),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.location_on),
              title: Text(_job['location'] ?? 'No Location'),
              subtitle: Text("Lat: ${_job['latitude']}, Lng: ${_job['longitude']}"),
            ),
            const Divider(),
            
            const Text("Description", style: TextStyle(fontWeight: FontWeight.bold)),
            Text(_job['description'] ?? 'No Description'),
            const SizedBox(height: 20),

            const Text("Billing", style: TextStyle(fontWeight: FontWeight.bold)),
            Text("Est. Price: ₹${_job['total_amount']}"),
            if (_job['billing'] != null && _job['billing']['total_final_amount'] != null)
              Text("Cash Collected: ₹${_job['billing']['total_final_amount']}", style: const TextStyle(color: Colors.green)),
            const SizedBox(height: 8),
            Row(
              children: [
                const Text("Payment Status: "),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: (_job['payment_status'] == 'paid' || (_job['billing'] != null && _job['billing']['payment_status'] == 'paid')) ? Colors.green[100] : Colors.orange[100],
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    (_job['payment_status'] == 'paid' || (_job['billing'] != null && _job['billing']['payment_status'] == 'paid')) ? "PAID" : "PENDING",
                    style: TextStyle(
                      color: (_job['payment_status'] == 'paid' || (_job['billing'] != null && _job['billing']['payment_status'] == 'paid')) ? Colors.green[800] : Colors.orange[800],
                      fontWeight: FontWeight.bold,
                      fontSize: 12
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (_job['payment_method'] != null || (_job['billing'] != null && _job['billing']['payment_method'] != null))
              Text("Mode: ${(_job['payment_method'] ?? _job['billing']['payment_method']).toString().toUpperCase()}"),
            if (_job['transaction_id'] != null || (_job['billing'] != null && _job['billing']['transaction_id'] != null))
              Text("Txn ID: ${_job['transaction_id'] ?? _job['billing']['transaction_id']}"),
            const SizedBox(height: 20),
            
            if (_customer != null) ...[
               const Text("Customer Details", style: TextStyle(fontWeight: FontWeight.bold)),
               ListTile(
                 contentPadding: EdgeInsets.zero,
                 leading: const Icon(Icons.person),
                 title: Text(_customer!['full_name'] ?? "Unknown"),
                 subtitle: Text("${_customer!['email']}\n${_customer!['phone']}"),
               ),
               const SizedBox(height: 20),
            ],

            // ADMIN ACTIONS
            const Text("Admin Controls", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.indigo)),
            const SizedBox(height: 10),
            
            // Mark Completed (Only if assigned/started/in_progress)
            if (status == 'assigned' || status == 'started' || status == 'in_progress')
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _markCompleted,
                  icon: const Icon(Icons.check_circle, color: Colors.white),
                  label: const Text("Mark as Completed"),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                ),
              ),
            
            const SizedBox(height: 12),
            
            // Mark Payment
            if (!(_job['payment_status'] == 'paid' || (_job['billing'] != null && _job['billing']['payment_status'] == 'paid')))
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _markPaymentPaid,
                  icon: const Icon(Icons.payments, color: Colors.green),
                  label: const Text("Mark as Paid (Manual)", style: TextStyle(color: Colors.green)),
                ),
              ),

            const SizedBox(height: 12),
            
            if (status == 'pending' || status == 'assigned')
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _forceCancelJob,
                  icon: const Icon(Icons.cancel, color: Colors.orange),
                  label: const Text("Force Cancel Job", style: TextStyle(color: Colors.orange)),
                ),
              ),
            
            const SizedBox(height: 12),
            
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _deleteJob,
                icon: const Icon(Icons.delete_forever, color: Colors.white),
                label: const Text("Delete Job Record"),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
