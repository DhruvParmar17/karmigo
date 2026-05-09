import 'dart:convert';
import 'package:flutter/foundation.dart'; // For kIsWeb
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'step2_address.dart';

class Step1Identity extends StatefulWidget {
  const Step1Identity({super.key});

  @override
  State<Step1Identity> createState() => _Step1IdentityState();
}

class _Step1IdentityState extends State<Step1Identity> {
  final aadhaarNumber = TextEditingController();
  final panNumber = TextEditingController(); // Optional
  
  XFile? _aadhaarPhoto;
  XFile? _selfiePhoto;
  
  Uint8List? _aadhaarBytes;
  Uint8List? _selfieBytes;

  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage(String type) async {
    try {
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera, 
        imageQuality: 50, // Optimize size
        preferredCameraDevice: type == 'selfie' ? CameraDevice.front : CameraDevice.rear
      );
      
      if (photo != null) {
        final bytes = await photo.readAsBytes();
        setState(() {
          if (type == 'aadhaar') {
             _aadhaarPhoto = photo;
             _aadhaarBytes = bytes;
          }
          if (type == 'selfie') {
             _selfiePhoto = photo;
             _selfieBytes = bytes;
          }
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error picking image: $e")),
      );
    }
  }

  Future<String?> _imageToBase64(XFile? image) async {
    if (image == null) return null;
    try {
      final bytes = await image.readAsBytes();
      return base64Encode(bytes);
    } catch (e) {
      print("Error converting image: $e");
      return null;
    }
  }

  void _next() async {
    if (aadhaarNumber.text.length < 12) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Enter valid 12-digit Aadhaar Number")),
      );
      return;
    }
    if (_aadhaarPhoto == null || _selfiePhoto == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please upload both Aadhaar photo and Selfie")),
      );
      return;
    }

    // Convert to Base64
    final aadhaarStr = await _imageToBase64(_aadhaarPhoto);
    final selfieStr = await _imageToBase64(_selfiePhoto);

    // Collect Data
    final data = {
      "aadhaar_number": aadhaarNumber.text.trim(),
      "aadhaar_photo": aadhaarStr,
      "selfie_photo": selfieStr,
      "pan_number": panNumber.text.trim().isEmpty ? null : panNumber.text.trim(),
    };

    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => Step2Address(previousData: data)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Step 1: Identity")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text("Identity Details", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            
            TextField(
              controller: aadhaarNumber,
              keyboardType: TextInputType.number,
              maxLength: 12,
              decoration: const InputDecoration(
                labelText: "Aadhaar Number",
                border: OutlineInputBorder(),
                counterText: "",
              ),
            ),
            const SizedBox(height: 15),
             TextField(
              controller: panNumber,
              decoration: const InputDecoration(
                labelText: "PAN Number (Optional)",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            
            const Text("Upload Documents", style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            
            _buildUploadTile("Aadhaar Card Photo", _aadhaarBytes, 'aadhaar'),
            const SizedBox(height: 10),
            _buildUploadTile("Data Selfie", _selfieBytes, 'selfie'),
            
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: _next,
              child: const Text("Next Step"),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUploadTile(String title, Uint8List? imageBytes, String type) {
    return ListTile(
      leading: imageBytes != null 
        ? Image.memory(imageBytes, width: 50, height: 50, fit: BoxFit.cover)
        : const Icon(Icons.camera_alt, color: Colors.grey, size: 40),
      title: Text(title),
      subtitle: Text(imageBytes != null ? "Captured" : "Tap to capture"),
      onTap: () => _pickImage(type),
      trailing: const Icon(Icons.chevron_right),
      shape: RoundedRectangleBorder(
          side: const BorderSide(color: Colors.grey),
          borderRadius: BorderRadius.circular(5)
      ),
    );
  }
}
