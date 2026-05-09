
import 'package:flutter/material.dart';
import '../../../theme/porter_theme.dart';
import 'job_creation_state.dart';
import 'step3_labour_count.dart';

class Step2DescriptionScreen extends StatefulWidget {
  final JobCreationState state;

  const Step2DescriptionScreen({super.key, required this.state});

  @override
  _Step2DescriptionScreenState createState() => _Step2DescriptionScreenState();
}

class _Step2DescriptionScreenState extends State<Step2DescriptionScreen> {
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

  String? _errorText;

  void _next() {
    if (_controller.text.trim().isEmpty) {
      setState(() {
        _errorText = "Please describe the work to proceed";
      });
      return;
    }
    widget.state.updateDescription(_controller.text);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => Step3LabourCountScreen(state: widget.state),
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
              "What do you want to shift?",
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 8),
            Text(
              "Describe the items briefly",
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _controller,
              maxLines: 4,
              onChanged: (_) => setState(() => _errorText = null),
              decoration: InputDecoration(
                hintText: "e.g. Shifting 2 BHK household items including fridge, bed, sofa...",
                errorText: _errorText,
                border: const OutlineInputBorder(),
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
