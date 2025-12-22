import 'package:flutter/material.dart';

class UsersList extends StatelessWidget {
  const UsersList({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Users')),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemBuilder: (context, index) => ListTile(
          leading: const Icon(Icons.person_outline),
          title: Text('User ${index + 1}'),
          subtitle: const Text('email@example.com'),
          trailing: IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: () {},
          ),
        ),
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemCount: 10,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {},
        label: const Text('Add User'),
        icon: const Icon(Icons.add),
      ),
    );
  }
}

