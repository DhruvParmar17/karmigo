import 'package:flutter/material.dart';
import 'package:karmigo_app/customer/screens/login_screen.dart';
import '../../../core/auth_state.dart';

class AccountTab extends StatelessWidget {
  const AccountTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Account")),
      body: ListView(
        children: [
          UserAccountsDrawerHeader(
            accountName: Text(AuthState.name ?? "Customer"),
            accountEmail: Text(AuthState.email ?? "No Email"), 
            currentAccountPicture: const CircleAvatar(
              child: Icon(Icons.person, size: 40),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.person_outline),
            title: const Text("Edit Profile"),
            onTap: () {},
          ),
          ListTile(
            leading: const Icon(Icons.settings_outlined),
            title: const Text("Settings"),
            onTap: () {},
          ),
          ListTile(
            leading: const Icon(Icons.help_outline),
            title: const Text("Help & Support"),
            onTap: () {},
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text("Logout", style: TextStyle(color: Colors.red)),
            onTap: () {
               AuthState.clear();
               Navigator.pushAndRemoveUntil(
                 context,
                 MaterialPageRoute(builder: (_) => LoginScreen()),
                 (route) => false,
               );
            },
          ),
          const SizedBox(height: 20),
          const Center(child: Text("App Version 1.0.0", style: TextStyle(color: Colors.grey))),
        ],
      ),
    );
  }
}
