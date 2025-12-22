import 'package:flutter/material.dart';

class BookingsList extends StatelessWidget {
  const BookingsList({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('All Bookings')),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemBuilder: (context, index) => ListTile(
          leading: const Icon(Icons.event_available),
          title: Text('Booking #${index + 100}'),
          subtitle: const Text('Status: pending'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () {},
        ),
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemCount: 12,
      ),
    );
  }
}

