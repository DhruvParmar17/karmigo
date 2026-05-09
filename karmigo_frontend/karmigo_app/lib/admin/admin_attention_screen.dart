import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../theme/porter_theme.dart';
import '../../widgets/language_switcher_button.dart';
import 'admin_job_detail_screen.dart';

class AdminAttentionScreen extends StatefulWidget {
  const AdminAttentionScreen({super.key});

  @override
  State<AdminAttentionScreen> createState() => _AdminAttentionScreenState();
}

class _AdminAttentionScreenState extends State<AdminAttentionScreen> {
  List<dynamic> _alerts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
       setState(() => _isLoading = true);
       final alerts = await ApiService.getAdminAlerts();
       if (mounted) {
         setState(() {
           _alerts = alerts;
           _isLoading = false;
         });
       }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _dismissAlert(int index) {
    setState(() {
      _alerts.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Attention Required"),
        automaticallyImplyLeading: false,
        actions: const [LanguageSwitcherButton()],
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : _alerts.isEmpty 
           ? const Center(child: Text("All caught up! No active alerts.", style: TextStyle(color: Colors.grey)))
           : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _alerts.length,
              itemBuilder: (context, index) {
                final alert = _alerts[index];
                final data = alert['data'];
                
                return Card(
                  elevation: 2,
                  margin: const EdgeInsets.only(bottom: 12),
                  child: Column(
                    children: [
                      ListTile(
                        leading: CircleAvatar(
                          backgroundColor: alert['color'] == 'orange' ? Colors.orange : (alert['color'] == 'blue' ? Colors.blue : Colors.red),
                          child: Icon(alert['icon'] == 'watch_later' ? Icons.watch_later : Icons.verified_user, color: Colors.white),
                        ),
                        title: Text(alert['title'], style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text(alert['subtitle']),
                        trailing: ElevatedButton(
                          onPressed: () => _dismissAlert(index),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.grey[200],
                            foregroundColor: Colors.black87,
                            elevation: 0
                          ),
                          child: const Text("Dismiss"),
                        ),
                      ),
                      if (alert['type'] == 'job_delayed' || alert['type'] == 'payment_pending')
                        Column(
                          children: [
                            const Divider(height: 1),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                   TextButton(
                                     onPressed: () async {
                                        await Navigator.push(
                                          context, 
                                          MaterialPageRoute(builder: (_) => AdminJobDetailScreen(job: data))
                                        );
                                        _loadData(); // Refresh after
                                     },
                                     child: const Text("View Job Details"),
                                   ),
                                ],
                              ),
                            ),
                          ],
                        )
                    ],
                  ),
                );
              },
             ),
    );
  }
}
