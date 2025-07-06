import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PreferenceSettingsProvider with ChangeNotifier {
  String _selectedTranslation = 'en.sahih';
  String _selectedTafsir = 'en.jalalayn';
  bool _showTranslation = true;
  bool _showTafsir = false;
  double _screenBrightness = 1.0;

  // Getters
  String get selectedTranslation => _selectedTranslation;
  String get selectedTafsir => _selectedTafsir;
  bool get showTranslation => _showTranslation;
  bool get showTafsir => _showTafsir;
  double get screenBrightness => _screenBrightness;

  PreferenceSettingsProvider() {
    _loadPreferences();
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
    _selectedTranslation = prefs.getString('selectedTranslation') ?? 'en.sahih';
    _selectedTafsir = prefs.getString('selectedTafsir') ?? 'en.jalalayn';
    _showTranslation = prefs.getBool('showTranslation') ?? true;
    _showTafsir = prefs.getBool('showTafsir') ?? false;
    _screenBrightness = prefs.getDouble('screenBrightness') ?? 1.0;
    notifyListeners();
  }

  Future<void> _savePreferences() async {
    final prefs = await SharedPreferences.getInstance();
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
