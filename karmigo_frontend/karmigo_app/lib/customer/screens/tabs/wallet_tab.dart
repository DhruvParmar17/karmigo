import 'package:flutter/material.dart';
import '../../../theme/porter_theme.dart';

class WalletTab extends StatelessWidget {
  const WalletTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Wallet")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Balance Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: PorterTheme.primaryColor,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Total Balance", style: TextStyle(color: Colors.white70)),
                      SizedBox(height: 8),
                      Text("₹0.00", style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white)),
                    ],
                  ),
                  Icon(Icons.account_balance_wallet, color: Colors.white, size: 40),
                ],
              ),
            ),
            const SizedBox(height: 30),
            const Text("Payment Methods", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const ListTile(
               leading: Icon(Icons.add, color: PorterTheme.primaryColor),
               title: Text("Add Payment Method"),
            ),
             const Divider(),
            const SizedBox(height: 20),
            const Text("Recent Transactions", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            const Center(child: Text("No transactions yet", style: TextStyle(color: Colors.grey))),
          ],
        ),
      ),
    );
  }
}
