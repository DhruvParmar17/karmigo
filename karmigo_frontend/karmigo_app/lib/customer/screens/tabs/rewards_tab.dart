import 'package:flutter/material.dart';

class RewardsTab extends StatelessWidget {
  const RewardsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Rewards")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
             Icon(Icons.card_giftcard, size: 80, color: Colors.purple),
             SizedBox(height: 20),
             Text("🎁 Rewards coming soon!", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
             SizedBox(height: 10),
             Text("Stay tuned for exciting offers.", style: TextStyle(color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}
