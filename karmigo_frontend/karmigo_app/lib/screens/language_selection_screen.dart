import 'package:flutter/material.dart';
import '../core/app_translations.dart';
import '../theme/porter_theme.dart';
import '../customer/screens/login_screen.dart';

class LanguageSelectionScreen extends StatefulWidget {
  const LanguageSelectionScreen({super.key});

  @override
  State<LanguageSelectionScreen> createState() => _LanguageSelectionScreenState();
}

class _LanguageSelectionScreenState extends State<LanguageSelectionScreen> {
  
  void _selectLanguage(String langCode) async {
    await AppTranslations.setLanguage(langCode);
    
    if (!mounted) return;

    // Navigate to Login after selection
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Logo Placeholder or Text
               const Icon(
                Icons.language,
                size: 80,
                color: PorterTheme.primaryColor,
              ),
              const SizedBox(height: 20),
              const Text(
                "Select Language\nभाषा चुनें\nभाषा निवडा",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: PorterTheme.textColor,
                ),
              ),
              const SizedBox(height: 50),

              _buildLangButton("English", "en"),
              const SizedBox(height: 16),
              _buildLangButton("हिंदी", "hi"),
              const SizedBox(height: 16),
              _buildLangButton("मराठी", "mr"),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLangButton(String label, String langCode) {
    return ElevatedButton(
      onPressed: () => _selectLanguage(langCode),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: PorterTheme.textColor,
        elevation: 2,
        side: const BorderSide(color: PorterTheme.primaryColor, width: 1.5),
        padding: const EdgeInsets.symmetric(vertical: 18),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
