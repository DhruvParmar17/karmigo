import 'package:flutter/material.dart';
import '../../theme/porter_theme.dart';
import '../../services/api_service.dart';

class LabourPaymentCollectionScreen extends StatefulWidget {
  final String jobId;
  final double amountToCollect;

  const LabourPaymentCollectionScreen({
    super.key,
    required this.jobId,
    required this.amountToCollect,
  });

  @override
  State<LabourPaymentCollectionScreen> createState() => _LabourPaymentCollectionScreenState();
}

class _LabourPaymentCollectionScreenState extends State<LabourPaymentCollectionScreen> {
  String _paymentMode = 'upi'; // 'cash' or 'upi'
  bool _isProcessing = false;
  bool _isCompleted = false;

  Future<void> _confirmAndComplete() async {
    setState(() => _isProcessing = true);
    try {
       // Ideally we might pass the payment mode to the backend, but the requirement specifically
       // says "Then Status = COMPLETED", so we'll just complete the job.
       await ApiService.payAndCompleteJob(widget.jobId, paymentMethod: _paymentMode);
       
       if (mounted) {
         setState(() {
           _isCompleted = true;
           _isProcessing = false;
         });
       }
    } catch (e) {
      if (mounted) {
         ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
         setState(() => _isProcessing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isCompleted) {
       return Scaffold(
         backgroundColor: Colors.white,
         body: Center(
           child: Padding(
             padding: const EdgeInsets.all(24.0),
             child: Column(
               mainAxisAlignment: MainAxisAlignment.center,
               children: [
                 const Icon(Icons.check_circle, color: Colors.green, size: 80),
                 const SizedBox(height: 16),
                 const Text("Payment Received\nJob Completed!", textAlign: TextAlign.center, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.green)),
                 const SizedBox(height: 32),
                 SizedBox(
                   width: double.infinity,
                   height: 50,
                   child: ElevatedButton(
                     onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst),
                     style: ElevatedButton.styleFrom(backgroundColor: PorterTheme.primaryColor),
                     child: const Text("Return to Dashboard", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                   ),
                 )
               ],
             ),
           ),
         )
       );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Payment Collection"),
        backgroundColor: PorterTheme.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.blueGrey[50],
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  const Text("Amount to Collect", style: TextStyle(fontSize: 16, color: Colors.grey, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text("₹${widget.amountToCollect.toStringAsFixed(0)}", style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: PorterTheme.primaryColor)),
                ],
              ),
            ),
            const SizedBox(height: 24),
            
            const Align(
              alignment: Alignment.centerLeft,
              child: Text("Select Payment Mode:", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: RadioListTile<String>(
                    title: const Text("UPI"),
                    value: 'upi',
                    groupValue: _paymentMode,
                    onChanged: (val) => setState(() => _paymentMode = val!),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
                Expanded(
                  child: RadioListTile<String>(
                    title: const Text("Cash"),
                    value: 'cash',
                    groupValue: _paymentMode,
                    onChanged: (val) => setState(() => _paymentMode = val!),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 24),
            
            if (_paymentMode == 'upi') ...[
               const Text("Scan QR to pay", style: TextStyle(fontSize: 16, color: Colors.grey)),
               const SizedBox(height: 12),
               ClipRRect(
                 borderRadius: BorderRadius.circular(12),
                 child: Image.asset(
                   'assets/images/qr_code.png',
                   height: 250,
                   width: 250,
                   fit: BoxFit.cover,
                   errorBuilder: (ctx, _, __) => Container(
                     height: 250, width: 250, color: Colors.grey[200],
                     child: const Icon(Icons.qr_code, size: 80, color: Colors.grey),
                   ),
                 ),
               ),
               const SizedBox(height: 24),
            ] else ...[
               const Icon(Icons.money, size: 80, color: Colors.green),
               const SizedBox(height: 12),
               const Text("Collect cash from the customer.", style: TextStyle(fontSize: 16, color: Colors.grey)),
               const SizedBox(height: 24),
            ],

            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton.icon(
                onPressed: _isProcessing ? null : _confirmAndComplete,
                icon: _isProcessing ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Icon(Icons.verified),
                label: _paymentMode == 'cash' ? const Text("Confirm Cash Received & Complete", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)) : const Text("Confirm UPI Payment & Complete", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
