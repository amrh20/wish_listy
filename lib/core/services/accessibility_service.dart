import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Service to manage accessibility preferences
class AccessibilityService extends ChangeNotifier {
  static const String _keyMinFontSize = 'accessibility_min_font_size';
  static const String _keyHighContrast = 'accessibility_high_contrast';
  static const String _keyLargeText = 'accessibility_large_text';

  double _minFontSize = 12.0;
  bool _highContrast = false;
  bool _largeText = false;

  double get minFontSize => _minFontSize;
  bool get highContrast => _highContrast;
  bool get largeText => _largeText;

  AccessibilityService() {
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    _minFontSize = prefs.getDouble(_keyMinFontSize) ?? 12.0;
    _highContrast = prefs.getBool(_keyHighContrast) ?? false;
    _largeText = prefs.getBool(_keyLargeText) ?? false;
    notifyListeners();
  }

  Future<void> setMinFontSize(double size) async {
    if (size < 10.0 || size > 20.0) return; // Reasonable bounds
    _minFontSize = size;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_keyMinFontSize, size);
    notifyListeners();
  }

  Future<void> setHighContrast(bool enabled) async {
    _highContrast = enabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyHighContrast, enabled);
    notifyListeners();
  }

  Future<void> setLargeText(bool enabled) async {
    _largeText = enabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyLargeText, enabled);
    notifyListeners();
  }
}

