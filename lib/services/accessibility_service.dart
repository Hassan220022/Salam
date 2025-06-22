import 'dart:async';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum TtsSpeed { verySlow, slow, normal, fast, veryFast }

enum TtsLanguage { arabic, english, urdu, french, indonesian }

class AccessibilityService {
  static final AccessibilityService _instance =
      AccessibilityService._internal();
  factory AccessibilityService() => _instance;
  AccessibilityService._internal();

  final FlutterTts _flutterTts = FlutterTts();

  // Settings keys
  static const String _ttsEnabledKey = 'tts_enabled';
  static const String _ttsSpeedKey = 'tts_speed';
  static const String _ttsLanguageKey = 'tts_language';
  static const String _ttsPitchKey = 'tts_pitch';
  static const String _ttsVolumeKey = 'tts_volume';
  static const String _autoReadKey = 'auto_read';
  static const String _announceNavigationKey = 'announce_navigation';

  // Current settings
  bool _isTtsEnabled = false;
  TtsSpeed _ttsSpeed = TtsSpeed.normal;
  TtsLanguage _ttsLanguage = TtsLanguage.english;
  double _ttsPitch = 1.0;
  double _ttsVolume = 0.8;
  bool _autoRead = false;
  bool _announceNavigation = true;

  // TTS State
  bool _isSpeaking = false;
  bool _isInitialized = false;
  List<String> _availableLanguages = [];
  StreamController<bool>? _speakingController;

  // Getters
  bool get isTtsEnabled => _isTtsEnabled;
  TtsSpeed get ttsSpeed => _ttsSpeed;
  TtsLanguage get ttsLanguage => _ttsLanguage;
  double get ttsPitch => _ttsPitch;
  double get ttsVolume => _ttsVolume;
  bool get autoRead => _autoRead;
  bool get announceNavigation => _announceNavigation;
  bool get isSpeaking => _isSpeaking;
  bool get isInitialized => _isInitialized;
  List<String> get availableLanguages => _availableLanguages;
  Stream<bool> get speakingStream =>
      _speakingController?.stream ?? const Stream.empty();

  // Speed mappings
  static const Map<TtsSpeed, double> _speedValues = {
    TtsSpeed.verySlow: 0.3,
    TtsSpeed.slow: 0.5,
    TtsSpeed.normal: 0.7,
    TtsSpeed.fast: 0.9,
    TtsSpeed.veryFast: 1.0,
  };

  // Language mappings
  static const Map<TtsLanguage, String> _languageCodes = {
    TtsLanguage.arabic: 'ar',
    TtsLanguage.english: 'en',
    TtsLanguage.urdu: 'ur',
    TtsLanguage.french: 'fr',
    TtsLanguage.indonesian: 'id',
  };

  // Initialization
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      _speakingController = StreamController<bool>.broadcast();

      // Load settings
      await _loadSettings();

      // Initialize TTS
      await _initializeTts();

      // Get available languages
      _availableLanguages = await _flutterTts.getLanguages;

      _isInitialized = true;
      // AccessibilityService initialized successfully
    } catch (e) {
      // Error initializing AccessibilityService: $e
    }
  }

  Future<void> _initializeTts() async {
    // Set up TTS callbacks
    _flutterTts.setStartHandler(() {
      _isSpeaking = true;
      _speakingController?.add(true);
    });

    _flutterTts.setCompletionHandler(() {
      _isSpeaking = false;
      _speakingController?.add(false);
    });

    _flutterTts.setProgressHandler(
        (String text, int startOffset, int endOffset, String word) {
      // Progress handler for word highlighting (future enhancement)
    });

    _flutterTts.setErrorHandler((message) {
      // TTS Error: $message
      _isSpeaking = false;
      _speakingController?.add(false);
    });

    // Apply current settings
    await _applyTtsSettings();
  }

  Future<void> _applyTtsSettings() async {
    try {
      await _flutterTts.setLanguage(_languageCodes[_ttsLanguage] ?? 'en');
      await _flutterTts.setSpeechRate(_speedValues[_ttsSpeed] ?? 0.7);
      await _flutterTts.setPitch(_ttsPitch);
      await _flutterTts.setVolume(_ttsVolume);
    } catch (e) {
      // Error applying TTS settings: $e
    }
  }

  // Load settings from SharedPreferences
  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();

    _isTtsEnabled = prefs.getBool(_ttsEnabledKey) ?? false;
    _ttsSpeed =
        TtsSpeed.values[prefs.getInt(_ttsSpeedKey) ?? TtsSpeed.normal.index];
    _ttsLanguage = TtsLanguage
        .values[prefs.getInt(_ttsLanguageKey) ?? TtsLanguage.english.index];
    _ttsPitch = prefs.getDouble(_ttsPitchKey) ?? 1.0;
    _ttsVolume = prefs.getDouble(_ttsVolumeKey) ?? 0.8;
    _autoRead = prefs.getBool(_autoReadKey) ?? false;
    _announceNavigation = prefs.getBool(_announceNavigationKey) ?? true;
  }

  // Save settings to SharedPreferences
  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setBool(_ttsEnabledKey, _isTtsEnabled);
    await prefs.setInt(_ttsSpeedKey, _ttsSpeed.index);
    await prefs.setInt(_ttsLanguageKey, _ttsLanguage.index);
    await prefs.setDouble(_ttsPitchKey, _ttsPitch);
    await prefs.setDouble(_ttsVolumeKey, _ttsVolume);
    await prefs.setBool(_autoReadKey, _autoRead);
    await prefs.setBool(_announceNavigationKey, _announceNavigation);
  }

  // Main speak method
  Future<void> speak(String text, {bool force = false}) async {
    if (!_isInitialized) await initialize();

    if (!_isTtsEnabled && !force) return;
    if (text.trim().isEmpty) return;

    try {
      await stop();
      await _flutterTts.speak(text);
    } catch (e) {
      // Error speaking text: $e
    }
  }

  // Speak Arabic text with proper pronunciation
  Future<void> speakArabic(String arabicText, {bool force = false}) async {
    if (!_isInitialized) await initialize();

    if (!_isTtsEnabled && !force) return;
    if (arabicText.trim().isEmpty) return;

    try {
      // Temporarily switch to Arabic
      final currentLang = _languageCodes[_ttsLanguage] ?? 'en';
      await _flutterTts.setLanguage('ar');

      await stop();
      await _flutterTts.speak(arabicText);

      // Restore original language
      await _flutterTts.setLanguage(currentLang);
    } catch (e) {
      // Error speaking Arabic text: $e
    }
  }

  // Speak translation
  Future<void> speakTranslation(String translation,
      {bool force = false}) async {
    if (!_isInitialized) await initialize();

    if (!_isTtsEnabled && !force) return;
    if (translation.trim().isEmpty) return;

    try {
      await stop();
      await _flutterTts.speak(translation);
    } catch (e) {
      // Error speaking translation: $e
    }
  }

  // Stop speaking
  Future<void> stop() async {
    if (!_isInitialized) return;

    try {
      await _flutterTts.stop();
      _isSpeaking = false;
      _speakingController?.add(false);
    } catch (e) {
      // Error stopping TTS: $e
    }
  }

  // Pause/Resume
  Future<void> pause() async {
    if (!_isInitialized) return;
    await _flutterTts.pause();
  }

  // Settings methods
  Future<void> setTtsEnabled(bool enabled) async {
    _isTtsEnabled = enabled;
    await _saveSettings();

    if (!enabled) {
      await stop();
    }
  }

  Future<void> setTtsSpeed(TtsSpeed speed) async {
    _ttsSpeed = speed;
    await _flutterTts.setSpeechRate(_speedValues[speed] ?? 0.7);
    await _saveSettings();
  }

  Future<void> setTtsLanguage(TtsLanguage language) async {
    _ttsLanguage = language;
    await _flutterTts.setLanguage(_languageCodes[language] ?? 'en');
    await _saveSettings();
  }

  Future<void> setTtsPitch(double pitch) async {
    _ttsPitch = pitch.clamp(0.5, 2.0);
    await _flutterTts.setPitch(_ttsPitch);
    await _saveSettings();
  }

  Future<void> setTtsVolume(double volume) async {
    _ttsVolume = volume.clamp(0.0, 1.0);
    await _flutterTts.setVolume(_ttsVolume);
    await _saveSettings();
  }

  Future<void> setAutoRead(bool enabled) async {
    _autoRead = enabled;
    await _saveSettings();
  }

  Future<void> setAnnounceNavigation(bool enabled) async {
    _announceNavigation = enabled;
    await _saveSettings();
  }

  // Convenience methods for common scenarios
  Future<void> announceScreenChange(String screenName) async {
    if (!_announceNavigation) return;
    await speak('Navigated to $screenName');
  }

  Future<void> announceAction(String action) async {
    if (!_announceNavigation) return;
    await speak(action);
  }

  Future<void> announceError(String error) async {
    await speak('Error: $error', force: true);
  }

  Future<void> announceSuccess(String message) async {
    await speak('Success: $message');
  }

  // Screen reader helpers
  String getSemanticLabel(String text, {String? description}) {
    if (description != null) {
      return '$text, $description';
    }
    return text;
  }

  // Reading modes
  Future<void> readPage(List<String> content) async {
    if (!_autoRead) return;

    for (String text in content) {
      if (!_isSpeaking) break;
      await speak(text);
      await Future.delayed(const Duration(milliseconds: 500));
    }
  }

  Future<void> readVerse(String arabic, String translation) async {
    await speakArabic(arabic);
    await Future.delayed(const Duration(seconds: 1));
    await speakTranslation(translation);
  }

  // Accessibility preferences
  bool shouldUseLargeText() => _ttsPitch > 1.2;
  bool shouldUseHighContrast() => _ttsVolume > 0.9;

  // Test TTS functionality
  Future<void> testTts() async {
    await speak('Text to speech is working correctly.', force: true);
  }

  Future<void> testArabicTts() async {
    await speakArabic('بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ', force: true);
  }

  // Dispose
  void dispose() {
    _speakingController?.close();
    _flutterTts.stop();
  }
}

// TTS Extensions
extension TtsSpeedExtension on TtsSpeed {
  String get displayName {
    switch (this) {
      case TtsSpeed.verySlow:
        return 'Very Slow';
      case TtsSpeed.slow:
        return 'Slow';
      case TtsSpeed.normal:
        return 'Normal';
      case TtsSpeed.fast:
        return 'Fast';
      case TtsSpeed.veryFast:
        return 'Very Fast';
    }
  }
}

extension TtsLanguageExtension on TtsLanguage {
  String get displayName {
    switch (this) {
      case TtsLanguage.arabic:
        return 'العربية';
      case TtsLanguage.english:
        return 'English';
      case TtsLanguage.urdu:
        return 'اردو';
      case TtsLanguage.french:
        return 'Français';
      case TtsLanguage.indonesian:
        return 'Bahasa Indonesia';
    }
  }
}
 