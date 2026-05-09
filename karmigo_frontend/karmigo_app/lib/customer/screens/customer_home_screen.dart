import 'package:flutter/material.dart';
import '../../theme/porter_theme.dart';
import '../../core/app_translations.dart';
import '../../widgets/language_switcher_button.dart';
import 'job_creation/job_creation_state.dart';
import 'job_creation/step2_sub_options.dart';
import '../../customer/screens/customer_notifications_screen.dart';
import 'job_creation/step3_description.dart'; // Ensure step3 is imported as it is used

class CustomerHomeScreen extends StatelessWidget {
  const CustomerHomeScreen({super.key});

  final List<Map<String, dynamic>> _workTypes = const [
    {"label": "house_shifting", "icon": Icons.home},
    {"label": "tempo_loading", "icon": Icons.local_shipping},
    {"label": "construction", "icon": Icons.construction},
    {"label": "others", "icon": Icons.more_horiz}, 
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Karmigo"),
        automaticallyImplyLeading: false,
        actions: [
           IconButton(
             icon: const Icon(Icons.notifications_outlined, color: PorterTheme.primaryColor),
             tooltip: "Notifications",
             onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const CustomerNotificationsScreen()),
                );
             },
           ),
           const LanguageSwitcherButton(),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppTranslations.tr("book_labour"),
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: PorterTheme.textColor,
              ),
            ),
            const SizedBox(height: 8),
             Text(
              AppTranslations.tr("select_category"),
              style: const TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 20),
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
    final String label = item['label']; // Direct label usage

    return InkWell(
      onTap: () {
        // Initialize State
        final state = JobCreationState();
        state.updateWorkType(label); 

        // NAVIGATION LOGIC
        // Skip Step 2 (SubOptions) and go directly to Step 3 (Description) for ALL categories
        // per requirement to remove "What kind of help do you need?" screen.
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
              AppTranslations.tr(label),
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
