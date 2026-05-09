import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import 'package:intl/intl.dart';
import '../../theme/porter_theme.dart';

class CustomerNotificationsScreen extends StatefulWidget {
  const CustomerNotificationsScreen({super.key});

  @override
  State<CustomerNotificationsScreen> createState() => _CustomerNotificationsScreenState();
}

class _CustomerNotificationsScreenState extends State<CustomerNotificationsScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _notifications = [];

  @override
  void initState() {
    super.initState();
    _fetchNotifications();
  }

  Future<void> _fetchNotifications() async {
    try {
      final jobs = await ApiService.getMyJobs();
      
      // Derive notifications from jobs
      // We create a notification for current status of each job
      // In a real system, you'd have an events table, but here we derive from status.
      
      List<Map<String, dynamic>> derived = [];
      
      for (var job in jobs) {
        final status = (job['order_status'] ?? '').toString().toLowerCase();
        final title = job['title'] ?? 'Service';
        final rawDate = job['updated_at'] ?? job['created_at']; // Prefer updated_at
        
        String message = "";
        IconData icon = Icons.info_outline;
        Color color = Colors.grey;

        if (status == 'pending' || status == 'searching') {
             message = "We are searching for a partner for your '$title' request.";
             icon = Icons.search;
             color = Colors.orange;
        } else if (status == 'assigned') {
             message = "Partner assigned for '$title'. They will arrive soon.";
             icon = Icons.person_pin_circle;
             color = Colors.blue;
        } else if (status == 'on_the_way') {
             message = "Partner is on the way for '$title'.";
             icon = Icons.directions_bike;
             color = Colors.blue;
        } else if (status == 'started' || status == 'in_progress') {
             message = "Job '$title' has started.";
             icon = Icons.play_circle_fill;
             color = Colors.purple;
        } else if (status == 'completed') {
             message = "Job '$title' is completed. Please rate your partner!";
             icon = Icons.check_circle;
             color = Colors.green;
        } else if (status == 'cancelled') {
             message = "Job '$title' was cancelled.";
             icon = Icons.cancel;
             color = Colors.red;
        } else {
             continue; // Skip unknown
        }
        
        derived.add({
           "message": message,
           "icon": icon,
           "color": color,
           "date": rawDate != null ? DateTime.parse(rawDate) : DateTime.now(),
           "jobId": job['id']
        });
      }

      // Sort by date descending
      derived.sort((a, b) => (b['date'] as DateTime).compareTo(a['date'] as DateTime));
      
      if (mounted) {
        setState(() {
          _notifications = derived;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Notifications")),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : _notifications.isEmpty
           ? Center(
               child: Column(
                 mainAxisAlignment: MainAxisAlignment.center,
                 children: const [
                   Icon(Icons.notifications_none, size: 64, color: Colors.grey),
                   SizedBox(height: 16),
                   Text("No notifications yet", style: TextStyle(color: Colors.grey)),
                 ],
               ),
             )
           : ListView.separated(
               itemCount: _notifications.length,
               separatorBuilder: (_, __) => const Divider(height: 1),
               itemBuilder: (context, index) {
                 final notif = _notifications[index];
                 final dateStr = DateFormat("d MMM, h:mm a").format(notif['date']);
                 
                 return ListTile(
                   leading: CircleAvatar(
                      backgroundColor: (notif['color'] as Color).withOpacity(0.1),
                      child: Icon(notif['icon'], color: notif['color']),
                   ),
                   title: Text(notif['message'], style: const TextStyle(fontSize: 14)),
                   subtitle: Text(dateStr, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                   onTap: () {
                      // Optional: Navigate to job details
                      // Navigator.push... 
                   },
                 );
               },
             ),
    );
  }
}
