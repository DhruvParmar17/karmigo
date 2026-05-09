import 'package:flutter/material.dart';
import '../../theme/porter_theme.dart';
import 'package:url_launcher/url_launcher.dart';

class SupportScreen extends StatelessWidget {
  const SupportScreen({super.key});

  Future<void> _makePhoneCall(String phoneNumber) async {
    final Uri launchUri = Uri(
      scheme: 'tel',
      path: phoneNumber,
    );
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri);
    }
  }

  Future<void> _launchWhatsApp(String phoneNumber) async {
    // Make sure number has country code for whatsapp: e.g. +919892593525
    final Uri launchUri = Uri.parse("https://wa.me/91$phoneNumber");
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri, mode: LaunchMode.externalApplication);
    }
  }

  Widget _buildContactCard(String title, String phone) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
             Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
             const SizedBox(height: 8),
             Text(phone, style: const TextStyle(fontSize: 20, color: PorterTheme.primaryColor)),
             const SizedBox(height: 16),
             Row(
               mainAxisAlignment: MainAxisAlignment.spaceEvenly,
               children: [
                 ElevatedButton.icon(
                   style: ElevatedButton.styleFrom(
                     backgroundColor: Colors.blue,
                     foregroundColor: Colors.white,
                   ),
                   onPressed: () => _makePhoneCall(phone),
                   icon: const Icon(Icons.phone),
                   label: const Text("Call"),
                 ),
                 ElevatedButton.icon(
                   style: ElevatedButton.styleFrom(
                     backgroundColor: Colors.green,
                     foregroundColor: Colors.white,
                   ),
                   onPressed: () => _launchWhatsApp(phone),
                   icon: const Icon(Icons.chat),
                   label: const Text("WhatsApp"),
                 ),
               ],
             )
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Help & Support")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Icon(Icons.support_agent, size: 80, color: PorterTheme.primaryColor),
            const SizedBox(height: 16),
            const Text(
              "How can we help you?",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              "Our support team is available to assist you. Please reach out via Call or WhatsApp.",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey, fontSize: 16),
            ),
            const SizedBox(height: 32),
            _buildContactCard("Primary Support Support", "9892593525"),
            _buildContactCard("Secondary Support", "9321786622"),
          ],
        ),
      ),
    );
  }
}
