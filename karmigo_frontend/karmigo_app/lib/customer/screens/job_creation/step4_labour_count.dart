
import 'package:flutter/material.dart';
import '../../../theme/porter_theme.dart';
import 'job_creation_state.dart';
import 'step5_details.dart';

class Step4LabourCountScreen extends StatefulWidget {
  final JobCreationState state;

  const Step4LabourCountScreen({super.key, required this.state});

  @override
  _Step4LabourCountScreenState createState() => _Step4LabourCountScreenState();
}

class _Step4LabourCountScreenState extends State<Step4LabourCountScreen> {
  int _count = 1;

  @override
  void initState() {
    super.initState();
    _count = widget.state.labourCount;
  }

  void _increment() {
    setState(() {
      _count++;
    });
  }

  void _decrement() {
    if (_count > 1) {
      setState(() {
        _count--;
      });
    }
  }

  void _next() {
    widget.state.updateLabourCount(_count);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => Step5DetailsScreen(state: widget.state),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Labour Count")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              "How many helpers?",
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 30),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildButton(Icons.remove, _decrement),
                const SizedBox(width: 30),
                Text(
                  "$_count",
                  style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: 30),
                _buildButton(Icons.add, _increment),
              ],
            ),
            const SizedBox(height: 20),
            const Text(
              "Base price starts from ₹350 / labour",
              style: TextStyle(color: Colors.grey, fontSize: 16),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: ElevatedButton(
            onPressed: _next,
            child: const Text("Next"),
          ),
        ),
      ),
    );
  }

  Widget _buildButton(IconData icon, VoidCallback onPressed) {
    return Container(
      decoration: BoxDecoration(
        color: PorterTheme.primaryColor.withOpacity(0.1),
        shape: BoxShape.circle,
      ),
      child: IconButton(
        icon: Icon(icon, color: PorterTheme.primaryColor, size: 32),
        onPressed: onPressed,
      ),
    );
  }
}
