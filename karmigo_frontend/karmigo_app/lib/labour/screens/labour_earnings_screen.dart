import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../theme/porter_theme.dart';

class LabourEarningsScreen extends StatefulWidget {
  const LabourEarningsScreen({super.key});

  @override
  State<LabourEarningsScreen> createState() => _LabourEarningsScreenState();
}

class _LabourEarningsScreenState extends State<LabourEarningsScreen> {
  bool _isLoading = true;
  double _balance = 0.0;
  List<dynamic> _transactions = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final balanceData = await ApiService.getWalletBalance();
      final transactions = await ApiService.getWalletTransactions();

      if (mounted) {
        setState(() {
          _balance = (balanceData['balance'] ?? 0.0).toDouble();
          _transactions = transactions;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Earnings & Wallet"),
        backgroundColor: PorterTheme.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : Column(
            children: [
              // Balance Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                color: PorterTheme.primaryColor,
                child: Column(
                  children: [
                    const Text(
                      "Current Balance",
                      style: TextStyle(color: Colors.white70, fontSize: 16),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "₹$_balance",
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                         ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Withdraw feature coming soon")));
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: PorterTheme.primaryColor,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      ),
                      child: const Text("Withdraw Money"),
                    )
                  ],
                ),
              ),

              // Breakdown Header
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "Transaction History",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              ),

              // List
              Expanded(
                child: _transactions.isEmpty
                    ? const Center(child: Text("No transactions yet."))
                    : ListView.builder(
                        itemCount: _transactions.length,
                        itemBuilder: (context, index) {
                          final trx = _transactions[index];
                          final isCredit = trx['transaction_type'] == 'credit';
                          return ListTile(
                            leading: CircleAvatar(
                              backgroundColor: isCredit ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                              child: Icon(
                                isCredit ? Icons.arrow_downward : Icons.arrow_upward,
                                color: isCredit ? Colors.green : Colors.red,
                              ),
                            ),
                            title: Text(trx['description'] ?? 'Transaction'),
                            subtitle: Text(trx['created_at']?.substring(0, 10) ?? ''),
                            trailing: Text(
                              "${isCredit ? '+' : '-'} ₹${trx['amount']}",
                              style: TextStyle(
                                color: isCredit ? Colors.green : Colors.red,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
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
