import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PreferenceSettingsProvider with ChangeNotifier {
  bool _isDarkTheme = false;
  bool _isNightReadingMode = false;
  double _arabicFontSize = 20.0;
  String _selectedTranslation = 'en.sahih';
  String _selectedTafsir = 'en.jalalayn';
  bool _showTranslation = true;
  bool _showTafsir = false;
  double _screenBrightness = 1.0;

  // Getters
  bool get isDarkTheme => _isDarkTheme;
  bool get isNightReadingMode => _isNightReadingMode;
  double get arabicFontSize => _arabicFontSize;
  String get selectedTranslation => _selectedTranslation;
  String get selectedTafsir => _selectedTafsir;
  bool get showTranslation => _showTranslation;
  bool get showTafsir => _showTafsir;
  double get screenBrightness => _screenBrightness;

  PreferenceSettingsProvider() {
    _loadPreferences();
  }

  void enableDarkTheme(bool isEnabled) {
    _isDarkTheme = isEnabled;
    _savePreferences();
    notifyListeners();
  }

  void enableNightReadingMode(bool isEnabled) {
    _isNightReadingMode = isEnabled;
    _savePreferences();
    notifyListeners();
  }

  void setArabicFontSize(double size) {
    _arabicFontSize = size;
    _savePreferences();
    notifyListeners();
  }

  void setSelectedTranslation(String translation) {
    _selectedTranslation = translation;
    _savePreferences();
    notifyListeners();
  }

  void setSelectedTafsir(String tafsir) {
    _selectedTafsir = tafsir;
    _savePreferences();
    notifyListeners();
  }

  void toggleTranslation(bool show) {
    _showTranslation = show;
    _savePreferences();
    notifyListeners();
  }

  void toggleTafsir(bool show) {
    _showTafsir = show;
    _savePreferences();
    notifyListeners();
  }

  void setScreenBrightness(double brightness) {
    _screenBrightness = brightness;
    _savePreferences();
    notifyListeners();
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    _isDarkTheme = prefs.getBool('isDarkTheme') ?? false;
    _isNightReadingMode = prefs.getBool('isNightReadingMode') ?? false;
    _arabicFontSize = prefs.getDouble('arabicFontSize') ?? 20.0;
    _selectedTranslation = prefs.getString('selectedTranslation') ?? 'en.sahih';
    _selectedTafsir = prefs.getString('selectedTafsir') ?? 'en.jalalayn';
    _showTranslation = prefs.getBool('showTranslation') ?? true;
    _showTafsir = prefs.getBool('showTafsir') ?? false;
    _screenBrightness = prefs.getDouble('screenBrightness') ?? 1.0;
    notifyListeners();
  }

  Future<void> _savePreferences() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDarkTheme', _isDarkTheme);
    await prefs.setBool('isNightReadingMode', _isNightReadingMode);
    await prefs.setDouble('arabicFontSize', _arabicFontSize);
    await prefs.setString('selectedTranslation', _selectedTranslation);
    await prefs.setString('selectedTafsir', _selectedTafsir);
    await prefs.setBool('showTranslation', _showTranslation);
    await prefs.setBool('showTafsir', _showTafsir);
    await prefs.setDouble('screenBrightness', _screenBrightness);
  }

  // Available translations
  static const Map<String, String> availableTranslations = {
    'en.sahih': 'Sahih International (English)',
    'en.pickthall': 'Pickthall (English)',
    'en.yusufali': 'Yusuf Ali (English)',
    'en.asad': 'Muhammad Asad (English)',
    'ur.jalandhry': 'Jalandhry (Urdu)',
    'ur.kanzuliman': 'Kanz ul Iman (Urdu)',
    'ar.muyassar': 'Al-Tafsir Al-Muyassar (Arabic)',
  };

  // Available Tafsir
  static const Map<String, String> availableTafsir = {
    'en.jalalayn': 'Tafsir al-Jalalayn (English)',
    'ar.jalalayn': 'تفسير الجلالين (Arabic)',
    'en.maarifulquran': 'Maarif-ul-Quran (English)',
    'ar.muyassar': 'التفسير الميسر (Arabic)',
    'en.wahiduddin': 'Wahiduddin Khan (English)',
  };
}
