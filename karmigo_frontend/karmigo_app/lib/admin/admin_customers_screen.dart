import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../theme/porter_theme.dart';
import '../../widgets/language_switcher_button.dart';

class AdminCustomersScreen extends StatefulWidget {
  const AdminCustomersScreen({super.key});

  @override
  State<AdminCustomersScreen> createState() => _AdminCustomersScreenState();
}

class _AdminCustomersScreenState extends State<AdminCustomersScreen> {
  List<dynamic> _users = [];
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
      final users = await ApiService.getAllUsers();
      if (mounted) {
        setState(() {
           _users = users;
           _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }
  // Removed unnecessary local frontend stats parser as it's provided recursively!
  Future<void> _toggleBlockUser(String userId, bool currentActive) async {
     setState(() => _isLoading = true);
     try {
       // if currentActive is true, we block (pass true)
       await ApiService.toggleCustomerBlock(userId, currentActive);
       if (mounted) {
         ScaffoldMessenger.of(context).showSnackBar(SnackBar(
           content: Text("User ${currentActive ? 'blocked' : 'unblocked'} successfully"),
           backgroundColor: currentActive ? Colors.red : Colors.green,
         ));
       }
       _loadData(); 
     } catch (e) {
       if (mounted) {
         ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
         setState(() => _isLoading = false);
       }
     }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Manage Customers"),
        automaticallyImplyLeading: false,
        actions: const [LanguageSwitcherButton()],
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: _users.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final user = _users[index];
              // Stats now come from backend!
              final int totalJobs = user['total_jobs'] ?? 0;
              final int cancelledJobs = user['cancelled_jobs'] ?? 0;
              final isActive = user['is_active'] ?? true;
              
              return Card(
                elevation: 2,
                color: isActive ? Colors.white : Colors.grey[200],
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: isActive ? (cancelledJobs > 3 ? Colors.orange[100] : Colors.blueGrey[100]) : Colors.red[100],
                    child: Text(
                      (user['full_name'] ?? user['username'] ?? "U")[0].toUpperCase(),
                      style: TextStyle(fontWeight: FontWeight.bold, color: isActive ? Colors.blueGrey : Colors.red),
                    ),
                  ),
                  title: Row(
                    children: [
                      Text(user['full_name'] ?? user['username'] ?? "Unknown", style: const TextStyle(fontWeight: FontWeight.bold)),
                      if (!isActive)
                        const Padding(
                          padding: EdgeInsets.only(left: 8.0),
                          child: Text("(BLOCKED)", style: TextStyle(color: Colors.red, fontSize: 10, fontWeight: FontWeight.bold)),
                        ),
                      if (isActive && cancelledJobs > 3)
                        const Padding(
                          padding: EdgeInsets.only(left: 8.0),
                          child: Text("(HIGH-RISK)", style: TextStyle(color: Colors.orange, fontSize: 10, fontWeight: FontWeight.bold)),
                        )
                    ],
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(user['email'] ?? user['phone'] ?? "No Contact"),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.work_outline, size: 14, color: Colors.grey[600]),
                          const SizedBox(width: 4),
                          Text("$totalJobs Jobs", style: const TextStyle(fontSize: 12)),
                          const SizedBox(width: 12),
                          Icon(Icons.cancel_outlined, size: 14, color: Colors.red[300]),
                          const SizedBox(width: 4),
                          Text("$cancelledJobs Cancelled", style: const TextStyle(fontSize: 12, color: Colors.red)),
                        ],
                      )
                    ],
                  ),
                  trailing: PopupMenuButton<String>(
                    onSelected: (val) {
                       if (val == 'toggle_block') {
                          _toggleBlockUser(user['id'].toString(), isActive);
                       } else if (val == 'warn') {
                          // TODO: implement warn feature
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Warning sent to user")));
                       }
                    },
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: 'toggle_block',
                        child: Text(isActive ? "Block User" : "Unblock User", style: TextStyle(color: isActive ? Colors.red : Colors.green)),
                      ),
                      if (isActive)
                        const PopupMenuItem(
                          value: 'warn',
                          child: Text("Warn Customer", style: TextStyle(color: Colors.orange)),
                        )
                    ],
                  ),
                ),
              );
            },
          ),
    );
  }
}
