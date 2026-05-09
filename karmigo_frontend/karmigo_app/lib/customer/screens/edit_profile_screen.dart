import 'package:flutter/material.dart';
import '../../theme/porter_theme.dart';
import '../../services/api_service.dart';
import '../../core/auth_state.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController.text = AuthState.name ?? "";
    _phoneController.text = AuthState.phone ?? "";
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
     setState(() => _isLoading = true);
     try {
       final data = await ApiService.getCustomerMe();
       if (mounted) {
         setState(() {
           _nameController.text = data['full_name'] ?? AuthState.name ?? "";
           _phoneController.text = data['phone'] ?? AuthState.phone ?? "";
           _addressController.text = data['address'] ?? "";
           _isLoading = false;
         });
       }
     } catch(e) {
       if (mounted) setState(() => _isLoading = false);
     }
  }

  Future<void> _saveProfile() async {
    setState(() => _isLoading = true);
    try {
      final response = await ApiService.updateCustomerProfile({
         "full_name": _nameController.text,
         "phone": _phoneController.text,
         "address": _addressController.text,
      });
      
      // Update AuthState
      if (response['full_name'] != null) AuthState.name = response['full_name'];
      if (response['phone'] != null) AuthState.phone = response['phone'];

      if (mounted) {
         ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Profile updated successfully")));
         Navigator.pop(context, true); // Return true to indicate success
      }
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
      appBar: AppBar(title: const Text("Edit Profile")),
      body: _isLoading 
         ? const Center(child: CircularProgressIndicator())
         : Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                TextField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: "Full Name",
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.person),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _phoneController,
                  decoration: const InputDecoration(
                    labelText: "Phone Number",
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.phone),
                  ),
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _addressController,
                  decoration: const InputDecoration(
                    labelText: "Address",
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.location_on),
                  ),
                  maxLines: 3,
                ),
                const Spacer(),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _saveProfile,
                    style: ElevatedButton.styleFrom(
                       backgroundColor: PorterTheme.primaryColor,
                       padding: const EdgeInsets.symmetric(vertical: 16)
                    ),
                    child: const Text("Save Changes"),
                  ),
                )
              ]
            ),
         )
    );
  }
}
