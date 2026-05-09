
import 'package:flutter/material.dart';
import '../../../theme/porter_theme.dart';
import 'job_creation_state.dart';
import 'step5_location.dart';

class Step5DetailsScreen extends StatefulWidget {
  final JobCreationState state;

  const Step5DetailsScreen({super.key, required this.state});

  @override
  _Step5DetailsScreenState createState() => _Step5DetailsScreenState();
}

class _Step5DetailsScreenState extends State<Step5DetailsScreen> {
  int _floor = 0;
  bool _lift = true;
  int _distance = 0;
  
  // New Fields
  double _hours = 1.0;
  String _houseSize = "1RK";
  int _specialItems = 0;
  
  // Legacy Map Removed from display logic

  
  // Expanded heavy items map
  final Map<String, String> _heavyItemsLabels = {
    // Original Generic
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
    
    // New Commercial / Material
    "plywood_sheet": "Plywood Sheet",
    "cement_bag": "Cement Bag (50kg)",
    "tile_box": "Tile Box",
    "glass_slab": "Glass Slab",
    "machinery": "Heavy Machinery",
    "wooden_plank": "Wooden Plank",
    "carton": "Heavy Carton Box",
    "other_heavy": "Other Heavy Item (>20kg)",
  };

  @override
  void initState() {
    super.initState();
    _floor = widget.state.floorNo;
    _lift = widget.state.liftAvailable;
    _distance = widget.state.walkingDistance;
    
    _hours = widget.state.hoursRequested;
    _houseSize = widget.state.houseSize;
    _specialItems = widget.state.specialItemsCount;
  }

  void _next() {
    widget.state.updateDetails(
      floor: _floor, 
      lift: _lift, 
      distance: _distance,
      hours: _hours,
      size: _houseSize,
      specialItems: _specialItems,
      // Map Service Type logic here or in state?
      // Simple logic: "Heavy" keyword -> heavy
      serviceType: widget.state.workType.toLowerCase().contains("heavy") ? "heavy_lifting" : "normal"
    );
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
      appBar: AppBar(title: const Text("Property & Items")),
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
            const SizedBox(height: 20),
            _buildSectionHeader("Time Required"),
            Text("${_hours.toStringAsFixed(1)} Hours", style: const TextStyle(fontWeight: FontWeight.bold)),
            Slider(
              value: _hours,
              min: 1.0,
              max: 12.0,
              divisions: 22,
              onChanged: (val) => setState(() => _hours = val),
              activeColor: PorterTheme.primaryColor,
            ),

            const SizedBox(height: 20),
            if (widget.state.workType == "House Shifting") ...[
              _buildSectionHeader("House Size"),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                  value: _houseSize,
                  decoration: const InputDecoration(border: OutlineInputBorder()),
                  items: ["1RK", "1BHK", "2BHK", "3BHK"].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => _houseSize = val);
                  },
              ),
              const SizedBox(height: 20),
            ],
            
            const SizedBox(height: 20),
            const SizedBox(height: 20),
            if (widget.state.workType == "House Shifting") ...[
              _buildSectionHeader("Furniture & Heavy Items"),
              const Text("Select items to shift", style: TextStyle(color: Colors.grey)),
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
                    contentPadding: EdgeInsets.zero,
                    title: Text(label),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (count > 0)
                          IconButton(
                            icon: const Icon(Icons.remove_circle_outline, color: Colors.grey),
                            onPressed: () {
                              widget.state.removeHeavyItem(key);
                              setState(() {}); 
                            },
                          ),
                        if (count > 0)
                          Text("$count", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        IconButton(
                          icon: const Icon(Icons.add_circle_outline, color: PorterTheme.primaryColor),
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
              const SizedBox(height: 20),
            ],

            _buildSectionHeader("Special / Fragile Items"),
            const Text("Items requiring extra care (₹50/item)", style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 10),
            
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("Quantity", style: TextStyle(fontSize: 16)),
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.remove_circle_outline),
                        onPressed: () {
                          if (_specialItems > 0) setState(() => _specialItems--);
                        },
                      ),
                      Text("$_specialItems", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      IconButton(
                        icon: const Icon(Icons.add_circle_outline),
                        onPressed: () => setState(() => _specialItems++),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
             const SizedBox(height: 40), // Padding for button
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
