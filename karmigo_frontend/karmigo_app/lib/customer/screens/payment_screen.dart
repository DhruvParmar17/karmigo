import 'package:flutter/material.dart';
import '../../theme/porter_theme.dart';
import '../../services/api_service.dart';
import 'rating_screen.dart';

class PaymentScreen extends StatefulWidget {
  final String jobId;
  final Map<String, dynamic> billingDetails;

  const PaymentScreen({super.key, required this.jobId, required this.billingDetails});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  bool _isLoading = false;
  String _selectedMethod = "online";

  Future<void> _processPayment() async {
    setState(() => _isLoading = true);

    // Simulate Razorpay / Gateway delay
    await Future.delayed(const Duration(seconds: 2));

    try {
      await ApiService.payAndCompleteJob(widget.jobId, paymentMethod: _selectedMethod);
      
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => AlertDialog(
            title: const Column(
              children: [
                Icon(Icons.check_circle, color: Colors.green, size: 60),
                SizedBox(height: 10),
                Text("Payment Successful"),
              ],
            ),
            content: const Text("Thank you for your payment!"),
            actions: [
              TextButton(
                onPressed: () {
                   Navigator.pop(ctx); // Close dialog
                   // Navigate to Rating
                   Navigator.pushReplacement(
                     context,
                     MaterialPageRoute(builder: (_) => RatingScreen(jobId: widget.jobId)),
                   );
                },
                child: const Text("Rate Service"),
              )
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Payment Failed: $e")));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bill = widget.billingDetails;
    final total = bill['total_final_amount'] ?? 0.0;

    return Scaffold(
      appBar: AppBar(title: const Text("Payment")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
             Center(
               child: Column(
                 children: [
                   const Text("Total Amount", style: TextStyle(color: Colors.grey)),
                   Text("₹$total", style: const TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: PorterTheme.textColor)),
                 ],
               ),
             ),
             const SizedBox(height: 30),
             const Text("Bill Breakdown", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
             const Divider(),
             
             _row("Base Fare", bill['base_price']),
             if ((bill['labour_cost_time_final'] ?? 0) > 0)
                _row("Time Charges", bill['labour_cost_time_final']),
             if ((bill['heavy_item_charges'] ?? 0) > 0)
                _row("Heavy Items", bill['heavy_item_charges']),
             if ((bill['floor_charges_final'] ?? 0) > 0) 
                _row("Floor Charges", bill['floor_charges_final']),
             if ((bill['walking_charges_final'] ?? 0) > 0)
                _row("Walking Charges", bill['walking_charges_final']),
             
             const Divider(thickness: 1.5),
             _row("Grand Total", total, isBold: true),
             
             const SizedBox(height: 40),
             const Text("Payment Method", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
             const SizedBox(height: 10),
             
             _paymentMethodTile("online", "Pay Online (UPI / Card)", Icons.payment),
             _paymentMethodTile("cash", "Cash on Delivery", Icons.money),
             
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: ElevatedButton(
            onPressed: _isLoading ? null : _processPayment,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: _isLoading 
              ? const CircularProgressIndicator(color: Colors.white)
              : const Text("PAY NOW", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ),
        ),
      ),
    );
  }

  Widget _row(String label, dynamic amount, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
           Text(label, style: TextStyle(fontWeight: isBold ? FontWeight.bold : FontWeight.normal)),
           Text("₹$amount", style: TextStyle(fontWeight: isBold ? FontWeight.bold : FontWeight.normal)),
        ],
      ),
    );
  }

  Widget _paymentMethodTile(String value, String label, IconData icon) {
    return RadioListTile<String>(
      value: value,
      groupValue: _selectedMethod,
      onChanged: (val) => setState(() => _selectedMethod = val!),
      title: Row(
        children: [
          Icon(icon, color: Colors.blueGrey),
          const SizedBox(width: 10),
          Text(label),
        ],
      ),
      activeColor: PorterTheme.primaryColor,
    );
  }
}
