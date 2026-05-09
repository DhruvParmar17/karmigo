import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/app_translations.dart';

class LocaleProvider with ChangeNotifier {
  Locale _locale = const Locale('en');

  Locale get locale => _locale;

  LocaleProvider() {
    _loadLocale();
  }

  Future<void> _loadLocale() async {
    final prefs = await SharedPreferences.getInstance();
    final langCode = prefs.getString('language_code') ?? 'en';
    _locale = Locale(langCode);
    await AppTranslations.setLanguage(langCode); // Sync
    notifyListeners();
  }

  Future<void> setLocale(Locale locale) async {
    if (!['en', 'hi', 'mr'].contains(locale.languageCode)) return;
    _locale = locale;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('language_code', locale.languageCode);
    await AppTranslations.setLanguage(locale.languageCode); // Sync
    notifyListeners();
  }

  void cycleLanguage() {
    if (_locale.languageCode == 'en') {
      setLocale(const Locale('hi'));
    } else if (_locale.languageCode == 'hi') {
      setLocale(const Locale('mr'));
    } else {
      setLocale(const Locale('en'));
    }
  }
}
