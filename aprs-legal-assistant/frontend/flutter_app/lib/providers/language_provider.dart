import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/translation_service.dart';

class LanguageProvider with ChangeNotifier {
  static const String _languageKey = 'app_language';
  
  String _currentLanguage = 'en';
  String get currentLanguage => _currentLanguage;
  bool get isEnglish => _currentLanguage == 'en';

  // Load saved language from SharedPreferences
  Future<void> loadLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    _currentLanguage = prefs.getString(_languageKey) ?? 'en';
    notifyListeners();
  }

  // Toggle between English and Telugu
  Future<void> toggleLanguage() async {
    final newLang = _currentLanguage == 'en' ? 'te' : 'en';
    await setLanguage(newLang);
  }

  // Set specific language
  Future<void> setLanguage(String langCode) async {
    if (_currentLanguage != langCode) {
      _currentLanguage = langCode;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_languageKey, langCode);
      notifyListeners();
    }
  }

  // Translate text based on current language
  Future<String> translate(String text, {String? fromLang}) async {
    if (_currentLanguage == 'en') return text;
    
    return await TranslationService.translateText(
      text: text,
      fromLang: fromLang ?? 'en',
      toLang: _currentLanguage,
      fromScript: 'Latn',
      toScript: _currentLanguage == 'te' ? 'Telu' : 'Latn',
    );
  }
}
