import 'package:flutter/material.dart';

class LabourList extends StatelessWidget {
  const LabourList({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Labour Directory')),
      body: ListView.builder(
        itemCount: 8,
        itemBuilder: (context, index) => Card(
          child: ListTile(
            leading: const Icon(Icons.handyman_outlined),
            title: Text('Labour ${index + 1}'),
            subtitle: const Text('Skills: plumbing, carpentry'),
            trailing: IconButton(
              icon: const Icon(Icons.edit_outlined),
              onPressed: () {},
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {},
        label: const Text('Add Labour'),
        icon: const Icon(Icons.add),
      ),
    );
  }
}

