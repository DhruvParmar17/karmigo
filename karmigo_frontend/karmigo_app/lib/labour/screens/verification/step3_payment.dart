import 'package:flutter/material.dart';
import '../../../services/api_service.dart';
import 'verification_status.dart';

class Step3Payment extends StatefulWidget {
  final Map<String, dynamic> previousData;
  const Step3Payment({super.key, required this.previousData});

  @override
  State<Step3Payment> createState() => _Step3PaymentState();
}

class _Step3PaymentState extends State<Step3Payment> {
  final bankAccount = TextEditingController();
  final ifsc = TextEditingController();
  final upiId = TextEditingController();
  
  bool isLoading = false;

  Future<void> _submit() async {
    if ((bankAccount.text.isEmpty || ifsc.text.isEmpty) && upiId.text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Provide Bank Account OR UPI ID to receive payments")),
      );
      return;
    }

    setState(() => isLoading = true);

    // Merge Data
    final data = Map<String, dynamic>.from(widget.previousData);
    data.addAll({
      "bank_account_number": bankAccount.text.trim().isEmpty ? null : bankAccount.text.trim(),
      "ifsc_code": ifsc.text.trim().isEmpty ? null : ifsc.text.trim(),
      "upi_id": upiId.text.trim().isEmpty ? null : upiId.text.trim(),
    });

    try {
      await ApiService.submitVerification(data);
      
      if (mounted) {
        // Navigate to Status Screen (Replace All)
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const VerificationStatusScreen(status: "pending")),
          (route) => false, 
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
      }
    } finally {
       if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Step 3: Payment Details")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
           crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text("Payout Method", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const Text("We need this to send your earnings.", style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 20),
            
            const Text("Option 1: Bank Account", style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            TextField(controller: bankAccount, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: "Account Number", border: OutlineInputBorder())),
            const SizedBox(height: 10),
            TextField(controller: ifsc, decoration: const InputDecoration(labelText: "IFSC Code", border: OutlineInputBorder())),
            
            const SizedBox(height: 20),
            const Center(child: Text("OR", style: TextStyle(fontWeight: FontWeight.bold))),
            const SizedBox(height: 20),
            
            const Text("Option 2: UPI", style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
             TextField(controller: upiId, decoration: const InputDecoration(labelText: "UPI ID (e.g. 98xx@ybl)", border: OutlineInputBorder())),
            
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: isLoading ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green, 
                padding: const EdgeInsets.symmetric(vertical: 15)
              ),
              child: isLoading 
                ? const CircularProgressIndicator(color: Colors.white)
                : const Text("Submit Verification", style: TextStyle(fontSize: 18)),
            ),
          ],
        ),
      ),
    );
  }
}
