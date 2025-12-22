import 'package:flutter/material.dart';

class LabourHome extends StatelessWidget {
  const LabourHome({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Labour Home")),
      body: const Center(
        child: Text("Labour Dashboard"),
      ),
    );
  }
}
