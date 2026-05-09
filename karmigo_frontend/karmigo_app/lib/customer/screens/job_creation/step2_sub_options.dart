
import 'package:flutter/material.dart';
import '../../../theme/porter_theme.dart';
import 'job_creation_state.dart';
import 'step3_description.dart';

class Step2SubOptionsScreen extends StatefulWidget {
  final JobCreationState state;

  const Step2SubOptionsScreen({super.key, required this.state});

  @override
  _Step2SubOptionsScreenState createState() => _Step2SubOptionsScreenState();
}

class _Step2SubOptionsScreenState extends State<Step2SubOptionsScreen> {
  // Define sub-options for categories
  final Map<String, List<String>> _optionsMap = {
    // Categories that share the same options
    "Tempo / Truck Loading & Unloading": [
      "Loading Only", "Unloading Only", "Loading + Unloading", "Packing Support", "Stacking Work"
    ],
    // Others might have empty or different options
    "Construction Work": ["Material Shifting", "Mixing", "General Help"],
  };

  @override
  Widget build(BuildContext context) {
    // Get options for current work type
    // We match string loosely or exact. 
    // State workType should match one of the keys or we default.
    List<String> options = _optionsMap[widget.state.workType] ?? [];

    // If no options, maybe auto-skip to next step? 
    // For now, let's show "General" or skip.
    // User requirement: "Then show dynamic sub-options based on category".
    
    if (options.isEmpty) {
       // Auto navigate or show generic message?
       // Let's show a "Briefing" screen or just Generic Checkbox?
       // Let's Just Allow Skip/Next if empty.
    }

    return Scaffold(
      appBar: AppBar(title: Text(widget.state.workType)),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "What kind of help do you need?",
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 8),
            Text(
              "Select all that apply",
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey),
            ),
            const SizedBox(height: 20),
            if (options.isNotEmpty)
              Expanded(
                child: ListView.builder(
                  itemCount: options.length,
                  itemBuilder: (context, index) {
                    final option = options[index];
                    final isSelected = widget.state.selectedSubOptions.contains(option);
                    return CheckboxListTile(
                      title: Text(option),
                      value: isSelected,
                      activeColor: PorterTheme.primaryColor,
                      onChanged: (val) {
                        widget.state.toggleSubOption(option);
                        setState(() {});
                      },
                    );
                  },
                ),
              )
            else
              const Center(child: Text("No specific sub-options. Click Next to describe.")),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => Step3DescriptionScreen(state: widget.state)),
              );
            },
            child: const Text("Next"),
          ),
        ),
      ),
    );
  }
}
