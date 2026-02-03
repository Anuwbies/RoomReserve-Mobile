import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocaleProvider with ChangeNotifier {
  Locale? _locale;

  LocaleProvider() {
    _loadLocale();
  }

  Locale? get locale => _locale;

  Future<void> _loadLocale() async {
    final prefs = await SharedPreferences.getInstance();
    final String? languageCode = prefs.getString('language_code');
    
    if (languageCode != null && ['en', 'ja', 'ko', 'fil'].contains(languageCode)) {
      _locale = Locale(languageCode);
      debugPrint("Loaded locale from prefs: $languageCode");
      notifyListeners();
    }
  }

  Future<void> setLocale(Locale locale) async {
    if (!['en', 'ja', 'ko', 'fil'].contains(locale.languageCode)) return;

    _locale = locale;
    notifyListeners();
    debugPrint("Locale set to: ${locale.languageCode}");

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('language_code', locale.languageCode);
  }
}
