import 'package:flutter/material.dart';
import '../../core/auth_state.dart';
import '../../theme/porter_theme.dart';
import 'login_screen.dart';
import '../../services/saved_address_service.dart'; // Just in case, though handled by screen import
import 'saved_addresses_screen.dart';
import '../../services/api_service.dart';
import '../../core/app_translations.dart';
import 'edit_profile_screen.dart';
import 'support_screen.dart';

class CustomerAccountScreen extends StatefulWidget {
  const CustomerAccountScreen({super.key});

  @override
  State<CustomerAccountScreen> createState() => _CustomerAccountScreenState();
}

class _CustomerAccountScreenState extends State<CustomerAccountScreen> {
  int _totalJobs = 0;
  int _completedJobs = 0;
  int _cancelledJobs = 0;
  bool _isLoadingStats = true;

  @override
  void initState() {
    super.initState();
    _fetchStats();
  }

  Future<void> _fetchStats() async {
    try {
      // Fetch all jobs to calculate stats client-side as requested
      final jobs = await ApiService.getMyJobs();
      
      int total = jobs.length;
      int completed = 0;
      int cancelled = 0;

      for (var job in jobs) {
         final status = (job['order_status'] ?? '').toString().toLowerCase();
         if (status == 'completed') completed++;
         if (status == 'cancelled') cancelled++;
      }

      if (mounted) {
        setState(() {
          _totalJobs = total;
          _completedJobs = completed;
          _cancelledJobs = cancelled;
          _isLoadingStats = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingStats = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(AppTranslations.tr("account"))),
      body: ListView(
        children: [
          UserAccountsDrawerHeader(
            decoration: const BoxDecoration(color: PorterTheme.primaryColor),
            accountName: Text(
               AuthState.name != null && AuthState.name!.isNotEmpty ? AuthState.name! : "Customer",
               style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            accountEmail: Text(AuthState.email ?? "No Email"), 
            currentAccountPicture: const CircleAvatar(
              backgroundColor: Colors.white,
              child: Icon(Icons.person, color: PorterTheme.primaryColor, size: 40),
            ),
          ),
          
          // Stats Row
          Container(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
            color: Colors.grey[50],
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem(AppTranslations.tr("total_jobs"), _totalJobs),
                _buildStatItem(AppTranslations.tr("completed"), _completedJobs, color: Colors.green),
                _buildStatItem(AppTranslations.tr("cancelled_jobs"), _cancelledJobs, color: Colors.red),
              ],
            ),
          ),
          const Divider(height: 1),

          ListTile(
            leading: const Icon(Icons.history),
            title: Text(AppTranslations.tr("order_history")),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
               // Navigation to My Requests (Tab 1) is handled by Main Screen usually, 
               // but here we can just let user switch tabs or push the screen.
               // For now, let's just show a snackbar or no-op if they are already on main screen tabs.
               // Ideally, we switch the tab index in CustomerMainScreen, but without access to parent state...
               ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Visit 'My Requests' tab to view history")));
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.person_outline),
            title: Text(AppTranslations.tr("edit_profile") == "edit_profile" ? "Edit Profile" : AppTranslations.tr("edit_profile")),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
               Navigator.push(
                 context,
                 MaterialPageRoute(builder: (_) => const EditProfileScreen()),
               ).then((_) {
                  setState(() {}); // refresh the name
               });
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.location_on_outlined),
            title: Text(AppTranslations.tr("saved_addresses")),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
               Navigator.push(
                 context,
                 MaterialPageRoute(builder: (_) => const SavedAddressesScreen()),
               );
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.card_giftcard),
            title: Text(AppTranslations.tr("rewards")),
            subtitle: Text(AppTranslations.tr("coming_soon")),
            onTap: () {},
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.help_outline),
            title: Text(AppTranslations.tr("help_support")),
            onTap: () {
               Navigator.push(
                 context,
                 MaterialPageRoute(builder: (_) => const SupportScreen()),
               );
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: Text(AppTranslations.tr("logout"), style: const TextStyle(color: Colors.red)),
            onTap: () {
              // Clear AuthState and Logout
              try { 
                  AuthState.clear(); 
              } catch (_) {}
              
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => LoginScreen()),
                (route) => false,
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, int value, {Color color = Colors.black87}) {
    return Column(
      children: [
        if (_isLoadingStats) 
           const SizedBox(width: 15, height: 15, child: CircularProgressIndicator(strokeWidth: 2))
        else
           Text("$value", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }
}
