import 'package:flutter/material.dart';
import 'package:karmigo_app/widgets/logo_widget.dart';
import '../tabs/orders_tab.dart'; // To navigate to orders if needed
import 'package:karmigo_app/theme/porter_theme.dart';
import '../job_creation/job_creation_state.dart';
import '../job_creation/step2_sub_options.dart';
import '../job_creation/step3_description.dart';

class HomeTab extends StatefulWidget {
  final Function(int) onTabChange;

  const HomeTab({super.key, required this.onTabChange});

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  final TextEditingController _workController = TextEditingController();

  final List<Map<String, dynamic>> _workTypes = const [
    {"label": "House Shifting", "icon": Icons.home},
    {"label": "Tempo / Truck Loading & Unloading", "icon": Icons.local_shipping},
    {"label": "Construction Work", "icon": Icons.construction},
    {"label": "Others", "icon": Icons.more_horiz}, // New General Service
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Karmigo"),
        automaticallyImplyLeading: false, // Hide back button
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Center(child: LogoWidget(height: 60)),
            const SizedBox(height: 10),
            const Text(
              "Welcome to Karmigo 👋",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 30),

            // ======================
            // DESCRIBE WORK SECTION
            // ======================
            Container(
               padding: const EdgeInsets.all(16),
               decoration: BoxDecoration(
                 color: Colors.blue.shade50,
                 borderRadius: BorderRadius.circular(12),
                 border: Border.all(color: Colors.blue.shade100),
               ),
               child: Column(
                 crossAxisAlignment: CrossAxisAlignment.start,
                 children: [
                   const Text("Describe your work (Optional)", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                   const SizedBox(height: 8),
                   TextField(
                     controller: _workController,
                     decoration: InputDecoration(
                       hintText: "E.g. I need to move a sofa...",
                       border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                       filled: true,
                       fillColor: Colors.white,
                       contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                     ),
                     maxLines: 2,
                   ),
                   const SizedBox(height: 12),
                   SizedBox(
                     width: double.infinity,
                     child: ElevatedButton(
                       onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("Please select a service category below to proceed"))
                          );
                       },
                       child: const Text("Select Service Below"),
                     ),
                   )
                 ],
               ),
            ),

            const SizedBox(height: 30),

            const Text("Services", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),

            // ======================
            // SERVICE GRID
            // ======================
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 1.1,
              ),
              itemCount: _workTypes.length,
              itemBuilder: (context, index) {
                final item = _workTypes[index];
                return _buildWorkCard(context, item);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWorkCard(BuildContext context, Map<String, dynamic> item) {
    final String label = item['label'];

    return InkWell(
      onTap: () {
        // Initialize State
        final state = JobCreationState();
        state.updateWorkType(label);
        
        // Pass description if user typed it
        if (_workController.text.isNotEmpty) {
           state.updateDescription(_workController.text);
        }
        
        // NAVIGATION LOGIC
        // NAVIGATION LOGIC - UPDATED
        // Always skip Step 2 (SubOptions) and go directly to Step 3 (Description)
        Navigator.push(
          context,
          MaterialPageRoute(
             builder: (_) => Step3DescriptionScreen(state: state),
          ),
        );
      },
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(item['icon'], size: 40, color: PorterTheme.primaryColor),
            const SizedBox(height: 12),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
