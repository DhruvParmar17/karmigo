import 'package:flutter/material.dart';
import '../../theme/porter_theme.dart';
import '../../services/api_service.dart';
import '../../core/auth_state.dart';

class LabourEditProfileScreen extends StatefulWidget {
  const LabourEditProfileScreen({super.key});

  @override
  State<LabourEditProfileScreen> createState() => _LabourEditProfileScreenState();
}

class _LabourEditProfileScreenState extends State<LabourEditProfileScreen> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _experienceController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController.text = AuthState.name ?? "";
    _phoneController.text = AuthState.phone ?? "";
    _fetchLabourData();
  }

  Future<void> _fetchLabourData() async {
     final labourId = AuthState.userId;
     if (labourId == null) return;

     setState(() => _isLoading = true);
     try {
       final data = await ApiService.getLabourDetails(labourId);
       if (mounted) {
         setState(() {
           _nameController.text = data['full_name'] ?? AuthState.name ?? "";
           _phoneController.text = data['phone'] ?? AuthState.phone ?? "";
           _experienceController.text = (data['years_of_experience'] ?? "").toString();
           _isLoading = false;
         });
       }
     } catch(e) {
       if (mounted) setState(() => _isLoading = false);
     }
  }

  Future<void> _saveProfile() async {
    final labourId = AuthState.userId;
    if (labourId == null) return;

    setState(() => _isLoading = true);
    try {
      await ApiService.updateLabourProfile(labourId, {
         "full_name": _nameController.text,
         "phone": _phoneController.text,
      });
      
      // Update AuthState
      AuthState.name = _nameController.text;
      AuthState.phone = _phoneController.text;

      if (mounted) {
         ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Profile updated successfully")));
         Navigator.pop(context, true); 
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
