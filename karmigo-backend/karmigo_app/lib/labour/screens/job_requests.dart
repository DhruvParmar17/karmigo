import 'package:flutter/material.dart';

class JobRequests extends StatelessWidget {
  const JobRequests({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Job Requests')),
      body: ListView.builder(
        itemCount: 6,
        itemBuilder: (context, index) => Card(
          child: ListTile(
            leading: const Icon(Icons.notifications_active_outlined),
            title: Text('Request #${index + 1}'),
            subtitle: const Text('Tap to view details'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {},
          ),
        ),
      ),
    );
  }
}

