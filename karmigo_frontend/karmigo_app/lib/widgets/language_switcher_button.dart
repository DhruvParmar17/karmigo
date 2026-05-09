import 'package:flutter/material.dart';
import '../core/app_translations.dart';

class LanguageSwitcherButton extends StatelessWidget {
  const LanguageSwitcherButton({super.key});

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.language, color: Colors.white),
      tooltip: "Change Language",
      onSelected: (lang) {
        AppTranslations.setLanguage(lang);
      },
      itemBuilder: (context) => [
        const PopupMenuItem(value: "en", child: Text("English")),
        const PopupMenuItem(value: "hi", child: Text("हिंदी (Hindi)")),
        const PopupMenuItem(value: "mr", child: Text("मराठी (Marathi)")),
      ],
    );
  }
}
