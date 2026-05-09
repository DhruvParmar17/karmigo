
import 'package:flutter/material.dart';
import '../../../theme/porter_theme.dart';
import 'job_creation_state.dart';
import 'step5_location.dart';

class Step4DetailsScreen extends StatefulWidget {
  final JobCreationState state;

  const Step4DetailsScreen({super.key, required this.state});

  @override
  _Step4DetailsScreenState createState() => _Step4DetailsScreenState();
}

class _Step4DetailsScreenState extends State<Step4DetailsScreen> {
  int _floor = 0;
  bool _lift = true;
  int _distance = 0;
  
  // Local heavy items map to sync with state
  // We can just use widget.state.heavyItems directly but cleaner to update state on Next or on change.
  // I'll update state on Next.

  final Map<String, String> _heavyItemsLabels = {
    "fridge": "Fridge (Any size)",
    "washing_machine": "Washing Machine",
    "cupboard": "Cupboard / Wardrobe",
    "sofa": "Big Sofa",
    "bed_frame": "Bed Frame",
    "mattress": "Double Mattress",
    "dining_table": "Dining Table",
    "glass_table": "Glass Table (Fragile)",
    "tv_big": "Big TV (>40 inch)",
    "tv_small": "Small TV",
    "marble_slab": "Marble / Granite Slab",
  };

  @override
  void initState() {
    super.initState();
    _floor = widget.state.floorNo;
    _lift = widget.state.liftAvailable;
    _distance = widget.state.walkingDistance;
  }

  void _next() {
    widget.state.updateDetails(floor: _floor, lift: _lift, distance: _distance);
    // Heavy items already updated via references to state's map if we modify it directly 
    // or we call methods. state object is shared.
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => Step5LocationScreen(state: widget.state),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Property Details")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Floor & Lift
            _buildSectionHeader("Floor & Lift"),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text("Floor Number", style: TextStyle(fontSize: 16)),
                        Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.remove_circle_outline),
                              onPressed: () {
                                if (_floor > 0) setState(() => _floor--);
                              },
                            ),
                            Text("$_floor", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                            IconButton(
                              icon: const Icon(Icons.add_circle_outline),
                              onPressed: () => setState(() => _floor++),
                            ),
                          ],
                        )
                      ],
                    ),
                    const Divider(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text("Lift Available?", style: TextStyle(fontSize: 16)),
                        Switch(
                          value: _lift,
                          activeColor: PorterTheme.primaryColor,
                          onChanged: (val) => setState(() => _lift = val),
                        )
                      ],
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 20),
            _buildSectionHeader("Walking Distance"),
            const Text("Distance from truck parking to house entrance", style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 8),
             DropdownButtonFormField<int>(
                value: _distance,
                decoration: const InputDecoration(border: OutlineInputBorder()),
                items: const [
                  DropdownMenuItem(value: 0, child: Text("0 - 50 meters (Standard)")),
                  DropdownMenuItem(value: 60, child: Text("50 - 100 meters")), // Using 60 to triggers >50 logic
                  DropdownMenuItem(value: 110, child: Text("100 - 150 meters")),
                  DropdownMenuItem(value: 160, child: Text("> 150 meters")),
                ],
                onChanged: (val) {
                  if (val != null) setState(() => _distance = val);
                },
             ),

            const SizedBox(height: 20),
            _buildSectionHeader("Heavy Items"),
            const Text("Select items that require extra effort", style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 8),
            ListView.separated(
              physics: const NeverScrollableScrollPhysics(),
              shrinkWrap: true,
              itemCount: _heavyItemsLabels.length,
              separatorBuilder: (c, i) => const Divider(height: 1),
              itemBuilder: (context, index) {
                String key = _heavyItemsLabels.keys.elementAt(index);
                String label = _heavyItemsLabels[key]!;
                int count = widget.state.heavyItems[key] ?? 0;
                
                return ListTile(
                  title: Text(label),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (count > 0)
                        IconButton(
                          icon: Icon(Icons.remove, color: Colors.grey),
                          onPressed: () {
                            widget.state.removeHeavyItem(key);
                            setState(() {}); // Rebuild to show count update
                          },
                        ),
                      if (count > 0)
                        Text("$count", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      IconButton(
                        icon: Icon(Icons.add, color: PorterTheme.primaryColor),
                        onPressed: () {
                          widget.state.addHeavyItem(key);
                          setState(() {});
                        },
                      ),
                    ],
                  ),
                );
              },
            ),
             const SizedBox(height: 80), // Padding for button
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
  
  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: PorterTheme.textColor,
      ),
    );
  }
}
