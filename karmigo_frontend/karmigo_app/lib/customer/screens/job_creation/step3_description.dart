
import 'package:flutter/material.dart';
import '../../../theme/porter_theme.dart';
import 'job_creation_state.dart';
import 'step4_labour_count.dart'; // Forward to Step 4

class Step3DescriptionScreen extends StatefulWidget {
  final JobCreationState state;

  const Step3DescriptionScreen({super.key, required this.state});

  @override
  _Step3DescriptionScreenState createState() => _Step3DescriptionScreenState();
}

class _Step3DescriptionScreenState extends State<Step3DescriptionScreen> {
  final TextEditingController _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    _controller.text = widget.state.description;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _next() {
    if (_controller.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please describe the work")),
      );
      return;
    }
    widget.state.updateDescription(_controller.text);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => Step4LabourCountScreen(state: widget.state),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Enter Details")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Describe what work you want the labour to do",
              style: Theme.of(context).textTheme.headlineSmall, // slightly smaller than headlineMedium
            ),
             const SizedBox(height: 8),
            Text(
              "Provide details for the labour",
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _controller,
              maxLines: 4,
              decoration: const InputDecoration(
                hintText: "e.g. Move household items, construction help, etc...",
                border: OutlineInputBorder(),
              ),
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
}
