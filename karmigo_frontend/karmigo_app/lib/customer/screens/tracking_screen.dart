
import 'dart:async';
import 'package:flutter/material.dart';
import '../../theme/porter_theme.dart';
import '../../services/api_service.dart';
import 'package:url_launcher/url_launcher.dart';
import 'payment_screen.dart';

class TrackingScreen extends StatefulWidget {
  final String jobId;

  const TrackingScreen({super.key, required this.jobId});

  @override
  _TrackingScreenState createState() => _TrackingScreenState();
}

class _TrackingScreenState extends State<TrackingScreen> {
  Timer? _timer;
  Map<String, dynamic>? _job;
  Map<String, dynamic>? _billing;
  Map<String, dynamic>? _labour;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchData();
    _startPolling();
  }
  
  void _startPolling() {
    _timer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (mounted) _fetchData(silent: true);
    });
  }

  Future<void> _fetchData({bool silent = false}) async {
    try {
      // 1. Fetch Job Status
      final job = await ApiService.getJob(widget.jobId);
      
      Map<String, dynamic>? billing;
      Map<String, dynamic>? labour;

      // 2. Fetch Labour (if assigned)
      if (job['labour_id'] != null) {
         try {
           labour = await ApiService.getLabourDetails(job['labour_id']);
         } catch (_) {}
      }

      // 3. Fetch Billing (if started or completed)
      // Optimistically try to fetch billing if status suggests it might exist
      final status = job['order_status'] ?? 'pending';
      if (status != 'pending') {
         try {
            billing = await ApiService.getBillingDetails(widget.jobId);
         } catch (_) {}
      }

      if (mounted) {
        setState(() {
          _job = job;
          _billing = billing;
          _labour = labour;
          if (!silent) _isLoading = false;
        });
      }
    } catch (e) {
      print("Error fetching tracking data: $e");
      if (mounted && !silent) {
         setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
  
  void _openPayment() async {
    if (_billing != null) {
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => PaymentScreen(jobId: widget.jobId, billingDetails: _billing!)),
      );
      _fetchData(); // Refresh on return
    }
  }

  Future<void> _makeCall(String? phone) async {
    if (phone == null) return;
    final uri = Uri.parse("tel:$phone");
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Call: $phone")));
    }
  }

  Future<void> _openMaps() async {
    // Current customer location is in _job['location'] (text) and maybe lat/lng
    // We want to navigate to valid lat/lng if available
    final lat = _job!['latitude'];
    final lng = _job!['longitude'];
    
    if (lat != null && lng != null) {
       // Open Google Maps
       final uri = Uri.parse("https://www.google.com/maps/search/?api=1&query=$lat,$lng");
       if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
       }
    } else {
       ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Location coordinates not available")));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    if (_job == null) {
      return Scaffold(
        appBar: AppBar(title: const Text("Track Job")),
        body: RefreshIndicator(
          onRefresh: () async {
            await _fetchData();
          },
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
               const SizedBox(height: 100),
               const Center(child: Text("Unable to load job details.")),
               const SizedBox(height: 16),
               Center(
                 child: ElevatedButton(
                  onPressed: () {
                     setState(() => _isLoading = true);
                     _fetchData();
                  },
                  child: const Text("Retry"),
                 ),
               )
            ],
          ),
        ),
      );
    }

    final status = _job!['order_status']?.toString().toLowerCase() ?? 'pending';
    final isAssigned = (status == 'assigned' || status == 'in_progress' || status == 'completed');
    final isInProgress = status == 'in_progress';
    final isCompleted = status == 'completed';
    final isCancelled = status == 'cancelled';

    // State Logic
    String displayStatus = "Searching for Labour...";
    Color statusColor = Colors.orange;
    String statusDesc = "We are finding the nearest partner for you.";

    if (isCancelled) {
      displayStatus = "Job Cancelled";
      statusColor = Colors.red;
      statusDesc = "This booking was cancelled.";
    } else if (isCompleted) {
       displayStatus = "Job Completed";
       statusColor = Colors.green;
       statusDesc = "Service finished. Please complete payment.";
    } else if (isInProgress) {
       displayStatus = "Work in Progress";
       statusColor = Colors.green; // Distinct color if needed, or keep green
       statusDesc = "Partner is currently working on your task.";
    } else if (isAssigned) {
       displayStatus = "Labour Assigned";
       statusColor = Colors.blue;
       statusDesc = "Partner is on the way to your location.";
    }

      return Scaffold(
        appBar: AppBar(title: const Text("Track Job")),
        body: RefreshIndicator(
          onRefresh: () async {
             await _fetchData();
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(), // Ensure scroll for refresh
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                // MAP SECTION
                Container(
                  height: 250,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // TODO: Real Map Widget here
                      const Column(
                         mainAxisAlignment: MainAxisAlignment.center,
                         children: [
                            Icon(Icons.map, size: 40, color: Colors.grey),
                            SizedBox(height: 8),
                            Text("Live Map View", style: TextStyle(color: Colors.grey)),
                         ]
                      ),
                      if (isAssigned && !isCancelled && !isCompleted)
                        Positioned(
                          bottom: 16,
                          right: 16,
                          child: FloatingActionButton.small(
                            heroTag: "maps_btn",
                            onPressed: _openMaps,
                            backgroundColor: Colors.white,
                            child: const Icon(Icons.directions, color: Colors.blue),
                          ),
                        )
                    ],
                  ),
                ),
                const SizedBox(height: 24),
    
                // STATUS CARD
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      children: [
                        Text(displayStatus, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: statusColor)),
                        const SizedBox(height: 8),
                        Text(statusDesc, textAlign: TextAlign.center, style: TextStyle(color: Colors.grey[600])),
                        
                        if (isAssigned && _labour != null) ...[
                           const Divider(height: 32),
                           Row(
                             children: [
                               CircleAvatar(
                                  backgroundColor: PorterTheme.primaryColor.withOpacity(0.1),
                                  radius: 24,
                                  child: Text((_labour!['full_name']??"P")[0].toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold)),
                               ),
                               const SizedBox(width: 16),
                               Expanded(
                                 child: Column(
                                   crossAxisAlignment: CrossAxisAlignment.start,
                                   children: [
                                     Text(_labour!['full_name'] ?? "Partner", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                     Row(
                                       children: [
                                         const Icon(Icons.star, color: Colors.amber, size: 16),
                                         const SizedBox(width: 4),
                                         Text("${_labour!['rating'] ?? 5.0}"),
                                       ],
                                     )
                                   ],
                                 ),
                               ),
                               IconButton(
                                 icon: const Icon(Icons.phone, color: Colors.green),
                                 onPressed: () => _makeCall(_labour!['phone']),
                               )
                             ],
                           )
                        ]
                      ],
                    ),
                  ),
                ),
    
                const SizedBox(height: 32),
    
                // ACTIONS
                if (!isCancelled && !isCompleted)
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: (isAssigned && _labour!=null) ? () => _makeCall(_labour!['phone']) : null,
                        icon: const Icon(Icons.call), 
                        label: const Text("Call Partner"),
                        style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {}, // Help
                        icon: const Icon(Icons.support_agent), 
                        label: const Text("Support"),
                       style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                      ),
                    ),
                  ],
                ),
    
                if (isCompleted) ...[
                   const SizedBox(height: 20),
                   SizedBox(
                     width: double.infinity,
                     child: ElevatedButton(
                       onPressed: (_billing != null && (_billing!['payment_status']??'pending') != 'paid') ? _openPayment : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          padding: const EdgeInsets.symmetric(vertical: 16)
                        ),
                       child: Text((_billing != null && (_billing!['payment_status']??'pending') == 'paid') ? "PAID" : "PROCEED TO PAYMENT"),
                     ),
                   )
                ]
              ],
            ),
          ),
        ),
      );
  }
}
