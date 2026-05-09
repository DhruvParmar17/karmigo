import 'package:flutter/material.dart';
import '../../../services/api_service.dart';
import '../labour_main_screen.dart';
import 'verification_landing.dart';
import 'verification_status.dart';

class VerificationWrapper extends StatefulWidget {
  const VerificationWrapper({super.key});

  @override
  State<VerificationWrapper> createState() => _VerificationWrapperState();
}

class _VerificationWrapperState extends State<VerificationWrapper> {
  bool isLoading = true;
  String? status;
  String? rejectionReason;

  @override
  void initState() {
    super.initState();
    _checkStatus();
  }

  Future<void> _checkStatus() async {
    try {
      final response = await ApiService.getVerificationStatus();
      setState(() {
        status = response['status'] ?? "unsubmitted";
        rejectionReason = response['rejection_reason'];
        isLoading = false;
      });

      // If verified, navigate to Main Screen
      if (status == "verified" && mounted) {
        Navigator.pushReplacement(
            context, MaterialPageRoute(builder: (_) => const LabourMainScreen()));
      }
    } catch (e) {
      setState(() {
        // If error (e.g. network), default to unsubmitted or show error
        status = "unsubmitted"; 
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (status == "unsubmitted") {
      return const VerificationLanding();
    } else if (status == "pending" || status == "rejected") {
      return VerificationStatusScreen(status: status!, reason: rejectionReason);
    } else {
      // Should be verified, but if we are here, means we are navigating away soon
      return const SizedBox(); 
    }
  }
}
