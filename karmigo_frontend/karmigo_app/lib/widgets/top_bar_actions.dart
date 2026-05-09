
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/locale_provider.dart';
import '../providers/theme_provider.dart';
import '../l10n/translations.dart';

class TopBarActions extends StatelessWidget {
  const TopBarActions({super.key});

  @override
  Widget build(BuildContext context) {
    final localeProvider = Provider.of<LocaleProvider>(context);
    final themeProvider = Provider.of<ThemeProvider>(context);
    final lang = localeProvider.locale.languageCode;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Language Switcher
        IconButton(
          tooltip: AppTranslations.get('language', lang),
          icon: Text(
            lang.toUpperCase(),
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          onPressed: () {
            localeProvider.cycleLanguage();
          },
        ),
        // Theme Switcher
        IconButton(
          tooltip: AppTranslations.get('theme', lang),
          icon: Icon(
            themeProvider.themeMode == ThemeMode.dark 
                ? Icons.light_mode 
                : Icons.dark_mode
          ),
          onPressed: () {
            themeProvider.toggleTheme();
          },
        ),
      ],
    );
  }
}
