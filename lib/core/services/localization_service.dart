import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocalizationService extends ChangeNotifier {
  static const String _languageKey = 'selected_language';
  static const String _defaultLanguage = 'en';

  Map<String, dynamic> _translations = {};
  String _currentLanguage = _defaultLanguage;
  bool _isLoading = false;

  // Getters
  String get currentLanguage => _currentLanguage;
  bool get isLoading => _isLoading;

  // Get current translations
  Map<String, dynamic> get translations => _translations;
  bool get isRTL => _currentLanguage == 'ar';
  TextDirection get textDirection =>
      isRTL ? TextDirection.rtl : TextDirection.ltr;

  // Initialize the service
  Future<void> initialize() async {
    await _loadSavedLanguage();
    await _loadTranslations();
  }

  // Load saved language from SharedPreferences
  Future<void> _loadSavedLanguage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _currentLanguage = prefs.getString(_languageKey) ?? _defaultLanguage;
    } catch (e) {
      _currentLanguage = _defaultLanguage;
    }
  }

  // Load translations for current language
  Future<void> _loadTranslations() async {
    try {
      _isLoading = true;
      notifyListeners();

      final String assetPath = 'assets/translations/$_currentLanguage.json';

      final String jsonString = await rootBundle.loadString(assetPath);

      _translations = json.decode(jsonString) as Map<String, dynamic>;

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      notifyListeners();

      // Fallback to empty translations
      _translations = {};
    }
  }

  // Change language
  Future<void> changeLanguage(String languageCode) async {

    if (_currentLanguage == languageCode) {

      return;
    }

    _currentLanguage = languageCode;

    // Save to SharedPreferences
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_languageKey, languageCode);

    } catch (e) {

    }

    // Load new translations
    await _loadTranslations();

  }

  // Get translation by key
  String translate(String key, {Map<String, dynamic>? args}) {
    if (_translations.isEmpty) {

      return key;
    }

    final keys = key.split('.');
    dynamic value = _translations;

    for (final k in keys) {
      if (value is Map<String, dynamic> && value.containsKey(k)) {
        value = value[k];
      } else {
        return key;
      }
    }

    if (value is String) {
      if (args != null) {
        return _replaceArgs(value, args);
      }
      return value;
    }

    return key;
  }

  // Replace arguments in translation string
  String _replaceArgs(String text, Map<String, dynamic> args) {
    String result = text;
    args.forEach((key, value) {
      result = result.replaceAll('{$key}', value.toString());
    });
    return result;
  }

  // Get supported languages
  List<Map<String, String>> get supportedLanguages => [
    {'code': 'en', 'name': 'English', 'nativeName': 'English', 'flag': '🇺🇸'},
    {'code': 'ar', 'name': 'Arabic', 'nativeName': 'العربية', 'flag': '🇸🇦'},
  ];

  // Get current language info
  Map<String, String>? get currentLanguageInfo {
    return supportedLanguages.firstWhere(
      (lang) => lang['code'] == _currentLanguage,
      orElse: () => supportedLanguages.first,
    );
  }

  // Check if language is supported
  bool isLanguageSupported(String languageCode) {
    return supportedLanguages.any((lang) => lang['code'] == languageCode);
  }

  // Get language name by code
  String getLanguageName(String languageCode) {
    final lang = supportedLanguages.firstWhere(
      (lang) => lang['code'] == languageCode,
      orElse: () => supportedLanguages.first,
    );
    return lang['name'] ?? languageCode;
  }

  // Get native language name by code
  String getNativeLanguageName(String languageCode) {
    final lang = supportedLanguages.firstWhere(
      (lang) => lang['code'] == languageCode,
      orElse: () => supportedLanguages.first,
    );
    return lang['nativeName'] ?? languageCode;
  }

  // Get flag by language code
  String getLanguageFlag(String languageCode) {
    final lang = supportedLanguages.firstWhere(
      (lang) => lang['code'] == languageCode,
      orElse: () => supportedLanguages.first,
    );
    return lang['flag'] ?? '🌐';
  }

  // Toggle between supported languages
  Future<void> toggleLanguage() async {
    final currentIndex = supportedLanguages.indexWhere(
      (lang) => lang['code'] == _currentLanguage,
    );

    final nextIndex = (currentIndex + 1) % supportedLanguages.length;
    final nextLanguage = supportedLanguages[nextIndex]['code']!;

    await changeLanguage(nextLanguage);
  }

  // Get next language
  String getNextLanguage() {
    final currentIndex = supportedLanguages.indexWhere(
      (lang) => lang['code'] == _currentLanguage,
    );

    final nextIndex = (currentIndex + 1) % supportedLanguages.length;
    return supportedLanguages[nextIndex]['code']!;
  }

  // Get next language info
  Map<String, String> getNextLanguageInfo() {
    final currentIndex = supportedLanguages.indexWhere(
      (lang) => lang['code'] == _currentLanguage,
    );

    final nextIndex = (currentIndex + 1) % supportedLanguages.length;
    return supportedLanguages[nextIndex];
  }

  // Format date based on current language
  String formatDate(DateTime date) {
    if (_currentLanguage == 'ar') {
      // Arabic date format
      return '${date.day}/${date.month}/${date.year}';
    } else {
      // English date format
      return '${date.month}/${date.day}/${date.year}';
    }
  }

  // Format time based on current language
  String formatTime(TimeOfDay time) {
    if (_currentLanguage == 'ar') {
      // Arabic time format (24-hour)
      return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
    } else {
      // English time format (12-hour)
      final hour = time.hourOfPeriod;
      final period = time.period == DayPeriod.am ? 'AM' : 'PM';
      return '$hour:${time.minute.toString().padLeft(2, '0')} $period';
    }
  }

  // Format currency based on current language
  String formatCurrency(double amount, {String currency = 'USD'}) {
    if (_currentLanguage == 'ar') {
      // Arabic currency format
      return '${amount.toStringAsFixed(2)} $currency';
    } else {
      // English currency format
      return '$currency ${amount.toStringAsFixed(2)}';
    }
  }

  // Get plural form based on current language
  String getPlural(String singular, String plural, int count) {
    if (_currentLanguage == 'ar') {
      // Arabic plural rules
      if (count == 1) return singular;
      if (count == 2) return 'اثنان';
      if (count >= 3 && count <= 10) return plural;
      return singular;
    } else {
      // English plural rules
      return count == 1 ? singular : plural;
    }
  }
}

// Extension for easy translation access
extension LocalizationExtension on BuildContext {
  String tr(String key, {Map<String, dynamic>? args}) {
    return LocalizationService().translate(key, args: args);
  }

  LocalizationService get localization => LocalizationService();
}
