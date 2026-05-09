import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../theme/porter_theme.dart';
import 'package:intl/intl.dart';

class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  bool _isLoading = true;
  double _balance = 0.0;
  List<dynamic> _transactions = [];

  @override
  void initState() {
    super.initState();
    _fetchWalletData();
  }

  Future<void> _fetchWalletData() async {
    try {
      final balanceData = await ApiService.getWalletBalance();
      final transactions = await ApiService.getWalletTransactions(); // Need to implement these in ApiService

      if (mounted) {
        setState(() {
          _balance = balanceData['balance'] ?? 0.0;
          _transactions = transactions;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        // Fallback or mock if API fails during dev
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("My Earnings")),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : Column(
            children: [
              // Balance Card
              Container(
                width: double.infinity,
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [PorterTheme.primaryColor, Colors.blueAccent]),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [BoxShadow(color: Colors.blue.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 5))],
                ),
                child: Column(
                  children: [
                    const Text("Wallet Balance", style: TextStyle(color: Colors.white70, fontSize: 16)),
                    const SizedBox(height: 8),
                    Text(
                      "₹${_balance.toStringAsFixed(2)}",
                      style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),

              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Align(alignment: Alignment.centerLeft, child: Text("Transaction History", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
              ),

              Expanded(
                child: _transactions.isEmpty
                  ? const Center(child: Text("No transactions yet"))
                  : ListView.builder(
                      itemCount: _transactions.length,
                      itemBuilder: (context, index) {
                        final tx = _transactions[index];
                        final isCredit = tx['transaction_type'] == 'credit';
                        final amount = tx['amount'];
                        final date = tx['created_at'] != null 
                             ? DateFormat.yMMMd().format(DateTime.parse(tx['created_at']))
                             : 'Unknown Date';

                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: isCredit ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                            child: Icon(isCredit ? Icons.arrow_downward : Icons.arrow_upward, color: isCredit ? Colors.green : Colors.red),
                          ),
                          title: Text(tx['description'] ?? 'Transaction'),
                          subtitle: Text(date),
                          trailing: Text(
                            "${isCredit ? '+' : ''}₹$amount",
                            style: TextStyle(
                              color: isCredit ? Colors.green : Colors.red,
                              fontWeight: FontWeight.bold,
                              fontSize: 16
                            ),
                          ),
                        );
                      },
                    ),
              ),
            ],
          ),
    );
  }
}
