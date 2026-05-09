import 'package:flutter/material.dart';
import '../../theme/porter_theme.dart';
import '../../services/api_service.dart';
import 'tracking_screen.dart';
import 'rating_screen.dart';
import 'package:url_launcher/url_launcher.dart';
import 'payment_screen.dart';
import 'package:intl/intl.dart';
import 'create_job.dart';

class JobDetailsScreen extends StatefulWidget {
  final String jobId;
  final bool isHistory; 

  const JobDetailsScreen({super.key, required this.jobId, this.isHistory = false});

  @override
  State<JobDetailsScreen> createState() => _JobDetailsScreenState();
}

class _JobDetailsScreenState extends State<JobDetailsScreen> {
  bool _isLoading = true;
  Map<String, dynamic>? _job;
  Map<String, dynamic>? _billing;
  Map<String, dynamic>? _labour;

  @override
  void initState() {
    super.initState();
    _fetchDetails();
  }

  Future<void> _fetchDetails() async {
    try {
      final jobs = await ApiService.getMyJobs();
      final job = jobs.firstWhere((j) => j['id'] == widget.jobId, orElse: () => null);
      
      Map<String, dynamic>? billing;

      if (job != null) {
        // Fetch Billing
        try {
           billing = await ApiService.getBillingDetails(widget.jobId);
        } catch (_) {}
      }

      if (mounted) {
        setState(() {
          _job = job;
          _billing = billing;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
      }
    }
  }

  Future<void> _cancelJob() async {
    final confirm = await showDialog(
      context: context, 
      builder: (_) => AlertDialog(
        title: const Text("Cancel Job?"),
        content: const Text("Are you sure you want to cancel this booking?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("No")),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text("Yes, Cancel")),
        ],
      )
    );

    if (confirm == true) {
      setState(() => _isLoading = true);
      try {
        await ApiService.cancelJob(widget.jobId);
        _fetchDetails(); // Refresh details
      } catch (e) {
        if (mounted) {
           ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Failed to cancel: $e")));
           setState(() => _isLoading = false);
        }
      }
    }
  }

  void _bookAgain() {
    if (_job == null) return;
    
    // Extract Description (Simple clean up or raw)
    String rawDesc = _job!['description'] ?? "";
    String desc = rawDesc;
    // Attempt basic parsing if it follows consistent format
    if (desc.startsWith("Work: ")) {
       desc = desc.replaceAll("Work: ", "");
       if (desc.contains("\nLabours Required:")) {
         desc = desc.split("\nLabours Required:")[0];
       }
    }

    // Construct Prefill Data
    Map<String, dynamic> prefill = {
      "work_type_ui": _job!['title'], // 'Shifting', 'Loading' etc
      "location": _job!['location'],
      "latitude": _job!['latitude'],
      "longitude": _job!['longitude'],
      "description": desc,
      "labour_count": _job!['required_labours'] ?? 1, // or labour_count
    };
    
    // Add billing details if available
    if (_billing != null) {
       prefill['floor_no'] = _billing!['floor_no'];
       prefill['lift_available'] = _billing!['lift_available'];
       prefill['walking_distance'] = _billing!['walking_distance_meters'];
       // prefill['hours_requested'] = _billing!['hours_requested']; // If stored
       // prefill['special_items_count'] = _billing!['special_items_count']; 
    }
    
    // Navigate to Create Job Step 1
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CreateJobScreen(
          prefillData: prefill,
        ),
      ),
    );
  }

  void _contactSupport() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Contact Support"),
        content: const Text("For support, please contact Karmigo support at +91-9999999999 or email support@karmigo.com"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Close")),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    if (_job == null) return const Scaffold(body: Center(child: Text("Job not found")));

    final status = (_job!['order_status'] ?? 'pending').toString().toLowerCase();
    
    // Status Logic
    final isPending = status == 'pending' || status == 'searching';
    final isAssigned = status == 'assigned';
    final isActive = status == 'on_the_way' || status == 'started' || status == 'in_progress';
    final isCompleted = status == 'completed';
    final isCancelled = status == 'cancelled';

    return Scaffold(
      appBar: AppBar(
        title: const Text("Job Details"),
        actions: [
           // Support Button (Only for Active Jobs: Searching, Assigned, In Progress)
           if (isPending || isAssigned || isActive)
             IconButton(
               icon: const Icon(Icons.help_outline),
               onPressed: _contactSupport,
               tooltip: "Help",
             )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Header Section
            _buildHeader(status),
            const Divider(height: 30),
            
            // 2. Timeline
            if (!isCancelled) _buildTimeline(status),
            if (!isCancelled) const Divider(height: 30),

            // 3. Job Summary
            _buildSummary(),
            const Divider(height: 30),
            
            // 4. Partner Section
            _buildPartnerSection(isPending, isAssigned, isActive, isCompleted),
            const Divider(height: 30),

            // 5. Payment Section (Mock)
            _buildPaymentSection(isCompleted),
            
             // 6. Actions
             const SizedBox(height: 20),
             
             // RE-BOOK BUTTON (Only for Completed Jobs)
             if (isCompleted)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _bookAgain,
                    icon: const Icon(Icons.refresh),
                    label: const Text("Book Again"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: PorterTheme.primaryColor,
                      padding: const EdgeInsets.symmetric(vertical: 12)
                    ),
                  ),
                ),
             
             if (isPending || (isAssigned && !isActive)) // Allow cancel if assigned but not started (assumption)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _cancelJob,
                    icon: const Icon(Icons.cancel),
                    label: const Text("Cancel Booking"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red[50],
                      foregroundColor: Colors.red,
                      elevation: 0,
                    ),
                  ),
                ),
                
             // Clean Navigation to Tracking (if active)
             if (isActive || (isAssigned && _job!['latitude'] != null)) // Assigned/Active can track
               Padding(
                 padding: const EdgeInsets.only(top: 10),
                 child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                       Navigator.push(context, MaterialPageRoute(builder: (_) => TrackingScreen(jobId: widget.jobId)));
                    },
                    icon: const Icon(Icons.map),
                    label: const Text("Track Job"),
                  ),
                 ),
               ),
               
             // CUSTOMER SOS / REPORT EMERGENCY!
             if (isAssigned || isActive)
               Padding(
                 padding: const EdgeInsets.only(top: 10),
                 child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () async {
                       final confirm = await showDialog(
                         context: context, 
                         builder: (_) => AlertDialog(
                           title: const Text("Report Emergency!"),
                           content: const Text("Are you sure you want to flag this booked job as an emergency or severe issue? Admins will be alerted immediately!"),
                           actions: [
                             TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Cancel")),
                             TextButton(onPressed: () => Navigator.pop(context, true), child: const Text("Yes, SOS", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold))),
                           ],
                         )
                       );

                       if (confirm == true) {
                         setState(() => _isLoading = true);
                         try {
                           // Flag back-end native statuses triggers Admin Attention!
                           await ApiService.updateJobStatus(jobId: widget.jobId, status: "sos");
                           _fetchDetails(); 
                           if(mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Emergency SOS Sent!"), backgroundColor: Colors.red));
                         } catch (e) {
                           if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Failed to report: $e")));
                              setState(() => _isLoading = false);
                           }
                         }
                       }
                    },
                    icon: const Icon(Icons.warning_amber_rounded),
                    label: const Text("Emergency / Report Issue"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red[50],
                      foregroundColor: Colors.red[900],
                      elevation: 0,
                    ),
                  ),
                 ),
               ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(String status) {
    // Booking ID mock or partial UUID
    String bookingId = widget.jobId.substring(0, 8).toUpperCase();
    
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: PorterTheme.primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.work, color: PorterTheme.primaryColor, size: 30),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _job!['title'] ?? 'Service',
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text("Booking ID: #$bookingId", style: const TextStyle(color: Colors.grey)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTimeline(String currentStatus) {
    // Steps: Searching -> Assigned -> On the Way -> Started -> Completed
    final steps = [
      {"key": "pending", "label": "Searching"},
      {"key": "assigned", "label": "Assigned"},
      {"key": "on_the_way", "label": "On the Way"}, // Merged In Progress logic
      {"key": "started", "label": "Started"},
      {"key": "completed", "label": "Completed"},
    ];
    
    // Determine current step index
    int currentIndex = 0;
    if (currentStatus == "searching") currentIndex = 0;
    else if (currentStatus == "assigned") currentIndex = 1;
    else if (currentStatus == "on_the_way") currentIndex = 2; // Approximate mapping
    else if (currentStatus == "in_progress") currentIndex = 3; // Started/In Progress
    else if (currentStatus == "started") currentIndex = 3;
    else if (currentStatus == "completed") currentIndex = 4;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Status Timeline", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 15),
        Row(
          children: steps.asMap().entries.map((entry) {
            int idx = entry.key;
            Map step = entry.value;
            bool isCompleted = idx <= currentIndex;
            bool isLast = idx == steps.length - 1;
            
            return Expanded(
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(child: Container(height: 2, color: idx == 0 ? Colors.transparent : (idx <= currentIndex ? Colors.green : Colors.grey[300]))),
                      Icon(
                        isCompleted ? Icons.check_circle : Icons.radio_button_unchecked,
                        color: isCompleted ? Colors.green : Colors.grey[300],
                        size: 20,
                      ),
                      Expanded(child: Container(height: 2, color: isLast ? Colors.transparent : (idx < currentIndex ? Colors.green : Colors.grey[300]))),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    step["label"], 
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 10, 
                      color: isCompleted ? Colors.black87 : Colors.grey,
                      fontWeight: isCompleted ? FontWeight.bold : FontWeight.normal
                    )
                  )
                ],
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildSummary() {
    String dateStr = "N/A";
    try {
        if (_job!['scheduled_at'] != null) {
          dateStr = DateFormat("d MMM yyyy, h:mm a").format(DateTime.parse(_job!['scheduled_at']));
        } else if (_job!['created_at'] != null) {
          dateStr = DateFormat("d MMM yyyy, h:mm a").format(DateTime.parse(_job!['created_at']));
        }
    } catch (_) {}

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Job Details", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 15),
        _infoRow(Icons.calendar_today, "Date & Time", dateStr),
        const SizedBox(height: 10),
        _infoRow(Icons.location_on, "Location", _job!['location'] ?? "N/A"),
        const SizedBox(height: 10),
        // job['labour_count'] or job['required_labours']
        _infoRow(Icons.group, "Labours Booked", "${_job!['required_labours'] ?? 1}"),
        const SizedBox(height: 10),
        _infoRow(Icons.description, "Description", _job!['description'] ?? "No description"),
      ],
    );
  }

  Widget _buildPartnerSection(bool isPending, bool isAssigned, bool isActive, bool isCompleted) {
    if (isPending) {
       return Container(
         padding: const EdgeInsets.all(16),
         decoration: BoxDecoration(
           color: Colors.orange[50],
           borderRadius: BorderRadius.circular(8),
           border: Border.all(color: Colors.orange.withOpacity(0.3)),
         ),
         child: Row(
           children: const [
             SizedBox(
               width: 20, height: 20,
               child: CircularProgressIndicator(strokeWidth: 2, color: Colors.orange),
             ),
             SizedBox(width: 12),
             Text("Searching for partner...", style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold)),
           ],
         ),
       );
    }

    List<dynamic> assignedLabours = _job?['assigned_labours'] ?? [];
    int acceptedCount = _job?['accepted_labours_count'] ?? assignedLabours.length;
    int requiredCount = _job?['required_labours'] ?? 1;

    if ((isAssigned || isActive || isCompleted) && assignedLabours.isNotEmpty) {
       return Column(
         crossAxisAlignment: CrossAxisAlignment.start,
         children: [
           Text("Assigned Partners ($acceptedCount/$requiredCount accepted)", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
           const SizedBox(height: 10),
           ...assignedLabours.map((labour) => 
               Card(
                 margin: const EdgeInsets.only(bottom: 8),
                 child: ListTile(
                   leading: CircleAvatar(
                     backgroundColor: PorterTheme.primaryColor,
                     backgroundImage: labour['photo'] != null ? NetworkImage(labour['photo']) : null,
                     child: labour['photo'] == null ? Text(((labour['full_name'] as String?) ?? "P")[0].toUpperCase(), style: const TextStyle(color: Colors.white)) : null,
                   ),
                   title: Text(labour['full_name'] ?? "Karmigo Partner"),
                   subtitle: Row(
                     mainAxisSize: MainAxisSize.min,
                     children: [
                        const Icon(Icons.star, size: 14, color: Colors.orange),
                        const SizedBox(width: 4),
                        Text("${labour['rating'] ?? 5.0}"),
                     ],
                   ),
                   trailing: IconButton(
                     icon: const Icon(Icons.phone, color: Colors.green),
                     onPressed: () async {
                        final phone = labour['phone'];
                        if (phone != null) {
                           final uri = Uri.parse("tel:$phone");
                           if (await canLaunchUrl(uri)) await launchUrl(uri);
                        }
                     },
                   ),
                 ),
               ),
           ).toList(),
           if (isAssigned && !isActive && acceptedCount < requiredCount)
             Padding(
               padding: const EdgeInsets.only(top: 8.0),
               child: Text("Waiting for ${requiredCount - acceptedCount} more partner(s)...", style: const TextStyle(color: Colors.orange, fontStyle: FontStyle.italic)),
             ),
         ],
       );
    }

    return const SizedBox();
  }

  Widget _buildPaymentSection(bool isCompleted) {
    // Safe mock payment section
    double amount = 0.0;
    if (_billing != null) {
       amount = (_billing!['total_estimated_amount'] as num?)?.toDouble() ?? 0.0;
    } else {
       amount = (_job!['total_amount'] as num?)?.toDouble() ?? 0.0;
    }

    // Payment Mock Status
    // If backend had payment_status, use it.
    String payStatus = "Pending";
    double finalAmount = amount;
    if (_billing != null) {
        if (_billing!['payment_status'] == 'paid') payStatus = "Paid";
        if (_billing!['total_final_amount'] != null) finalAmount = (_billing!['total_final_amount'] as num).toDouble();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
         const Text("Payment", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
         const SizedBox(height: 10),
         Container(
           padding: const EdgeInsets.all(16),
           decoration: BoxDecoration(
             color: Colors.grey[50],
             borderRadius: BorderRadius.circular(8),
             border: Border.all(color: Colors.grey[300]!),
           ),
           child: Column(
             children: [
               Row(
                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
                 children: [
                   Text(payStatus == "Paid" ? "Total Paid" : "Estimated Total"),
                   Text("₹${payStatus == "Paid" ? finalAmount : amount}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                 ],
               ),
               const SizedBox(height: 8),
               Row(
                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
                 children: [
                   const Text("Status"),
                   Container(
                     padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                     decoration: BoxDecoration(
                       color: payStatus == "Paid" ? Colors.green[100] : Colors.orange[100],
                       borderRadius: BorderRadius.circular(4),
                     ),
                     child: Text(
                       payStatus,
                       style: TextStyle(
                         color: payStatus == "Paid" ? Colors.green[800] : Colors.orange[800], 
                         fontWeight: FontWeight.bold,
                         fontSize: 12
                       ),
                     ),
                   ),
                 ],
               ),
               const SizedBox(height: 12),
               
               // Disclaimer
               Row(
                 children: [
                   Icon(Icons.info_outline, size: 14, color: Colors.grey[600]),
                   const SizedBox(width: 6),
                   Expanded(
                     child: Text(
                       "Final amount may change after job completion.",
                       style: TextStyle(color: Colors.grey[600], fontSize: 12),
                     ),
                   ),
                 ],
               ),
               
               // Pay Button (Only if completed and not 'paid')
               if (isCompleted && payStatus != "Paid") ...[
                 const SizedBox(height: 16),
                 SizedBox(
                   width: double.infinity,
                   child: ElevatedButton.icon(
                     onPressed: () {
                         // Real Payment Navigation
                         Navigator.pushReplacement(
                           context, 
                           MaterialPageRoute(
                             builder: (_) => PaymentScreen(
                               jobId: widget.jobId,
                               billingDetails: _billing ?? {'total_final_amount': amount},
                             )
                           )
                         );
                     }, 
                     icon: const Icon(Icons.payment),
                     label: const Text("Pay Now / Confirm Payment"),
                     style: ElevatedButton.styleFrom(
                         backgroundColor: Colors.green,
                         foregroundColor: Colors.white,
                     ),
                   ),
                 )
               ]
             ],
           ),
         )
      ],
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: Colors.grey),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
              Text(value, style: const TextStyle(fontSize: 15)),
            ],
          ),
        ),
      ],
    );
  }
}
