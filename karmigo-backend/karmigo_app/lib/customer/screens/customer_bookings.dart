import 'package:flutter/material.dart';

class CustomerBookings extends StatelessWidget {
  const CustomerBookings({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Bookings')),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemBuilder: (context, index) => Card(
          child: ListTile(
            leading: const Icon(Icons.work_history_outlined),
            title: Text('Booking ${index + 1}'),
            subtitle: const Text('Status: pending'),
            trailing: const Icon(Icons.chevron_right),
          ),
        ),
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemCount: 5,
      ),
    );
  }
}

