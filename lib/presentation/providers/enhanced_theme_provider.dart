import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/utils/app_theme.dart';

enum ReadingMode {
  normal('Normal'),
  night('Night Reading'),
  comfort('Comfort Reading');

  const ReadingMode(this.displayName);
  final String displayName;
}

class EnhancedThemeProvider with ChangeNotifier {
  static const String _themeModeKey = 'theme_mode';
  static const String _themeStyleKey = 'theme_style';
  static const String _arabicFontKey = 'arabic_font';
  static const String _fontScaleKey = 'font_scale';
  static const String _isHighContrastKey = 'is_high_contrast';
  static const String _reduceAnimationsKey = 'reduce_animations';
  static const String _enableHapticsKey = 'enable_haptics';
  static const String _autoThemeKey = 'auto_theme';
  static const String _readingModeKey = 'reading_mode';
  static const String _arabicFontSizeKey = 'arabic_font_size';

  // Current settings
  ThemeMode _themeMode = ThemeMode.system;
  AppThemeStyle _themeStyle = AppThemeStyle.islamic;
  ArabicFontFamily _arabicFont = ArabicFontFamily.cairo;
  double _fontScale = 1.0;
  bool _isHighContrast = false;
  bool _reduceAnimations = false;
  bool _enableHaptics = true;
  bool _autoTheme = false;
  ReadingMode _readingMode = ReadingMode.normal;
  double _arabicFontSize = 20.0;

  // Getters
  ThemeMode get themeMode => _themeMode;
  AppThemeStyle get themeStyle => _themeStyle;
  ArabicFontFamily get arabicFont => _arabicFont;
  double get fontScale => _fontScale;
  bool get isHighContrast => _isHighContrast;
  bool get reduceAnimations => _reduceAnimations;
  bool get enableHaptics => _enableHaptics;
  bool get autoTheme => _autoTheme;
  ReadingMode get readingMode => _readingMode;
  double get arabicFontSize => _arabicFontSize;

  // Convenience getters for reading modes
  bool get isNightReadingMode => _readingMode == ReadingMode.night;
  bool get isComfortReadingMode => _readingMode == ReadingMode.comfort;

  // Theme data getters
  ThemeData get lightTheme => AppTheme.lightTheme(
        style: _themeStyle,
        arabicFont: _arabicFont,
        fontScale: _fontScale,
        isHighContrast: _isHighContrast,
      );

  ThemeData get darkTheme => AppTheme.darkTheme(
        style: _themeStyle,
        arabicFont: _arabicFont,
        fontScale: _fontScale,
        isHighContrast: _isHighContrast,
      );

  TextTheme get arabicTextTheme => AppTheme.arabicTextTheme(
        arabicFont: _arabicFont,
        fontScale: _fontScale,
      );

  // Get reading mode specific colors
  Color getReadingModeBackgroundColor(BuildContext context) {
    final isDarkTheme = this.isDarkTheme(context);
    
    switch (_readingMode) {
      case ReadingMode.night:
        return const Color(0xFF0D1B2A); // Deep blue for night reading
      case ReadingMode.comfort:
        return isDarkTheme 
            ? const Color(0xFF1A1A1A) // Warm dark gray
            : const Color(0xFFFFF8E1); // Warm cream
      case ReadingMode.normal:
        return isDarkTheme 
            ? darkTheme.scaffoldBackgroundColor 
            : lightTheme.scaffoldBackgroundColor;
    }
  }

  Color getReadingModeTextColor(BuildContext context) {
    final isDarkTheme = this.isDarkTheme(context);
    
    switch (_readingMode) {
      case ReadingMode.night:
        return const Color(0xFFE8F4FD); // Soft blue-white for night reading
      case ReadingMode.comfort:
        return isDarkTheme 
            ? const Color(0xFFE0E0E0) // Warm light gray
            : const Color(0xFF3E2723); // Warm dark brown
      case ReadingMode.normal:
        return isDarkTheme 
            ? darkTheme.colorScheme.onSurface 
            : lightTheme.colorScheme.onSurface;
    }
  }

  Color getReadingModeCardColor(BuildContext context) {
    final isDarkTheme = this.isDarkTheme(context);
    
    switch (_readingMode) {
      case ReadingMode.night:
        return const Color(0xFF1E3A5F); // Darker blue for cards
      case ReadingMode.comfort:
        return isDarkTheme 
            ? const Color(0xFF2A2A2A) // Warm dark card
            : const Color(0xFFFFFDE7); // Very light cream
      case ReadingMode.normal:
        return isDarkTheme 
            ? darkTheme.cardColor 
            : lightTheme.cardColor;
    }
  }

  // Animation duration based on accessibility settings
  Duration get animationDuration => _reduceAnimations
      ? const Duration(milliseconds: 100)
      : AppTheme.mediumAnimation;

  Duration get longAnimationDuration => _reduceAnimations
      ? const Duration(milliseconds: 150)
      : AppTheme.longAnimation;

  // Initialization
  Future<void> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();

    _themeMode =
        ThemeMode.values[prefs.getInt(_themeModeKey) ?? ThemeMode.system.index];
    _themeStyle = AppThemeStyle
        .values[prefs.getInt(_themeStyleKey) ?? AppThemeStyle.islamic.index];
    _arabicFont = ArabicFontFamily
        .values[prefs.getInt(_arabicFontKey) ?? ArabicFontFamily.cairo.index];
    _fontScale = prefs.getDouble(_fontScaleKey) ?? 1.0;
    _isHighContrast = prefs.getBool(_isHighContrastKey) ?? false;
    _reduceAnimations = prefs.getBool(_reduceAnimationsKey) ?? false;
    _enableHaptics = prefs.getBool(_enableHapticsKey) ?? true;
    _autoTheme = prefs.getBool(_autoThemeKey) ?? false;
    _readingMode = ReadingMode.values[prefs.getInt(_readingModeKey) ?? ReadingMode.normal.index];
    _arabicFontSize = prefs.getDouble(_arabicFontSizeKey) ?? 20.0;

    notifyListeners();
  }

  // Theme mode
  Future<void> setThemeMode(ThemeMode mode) async {
    if (_themeMode == mode) return;

    _themeMode = mode;
    await _savePreference(_themeModeKey, mode.index);
    _triggerHaptic();
    notifyListeners();
  }

  // Theme style
  Future<void> setThemeStyle(AppThemeStyle style) async {
    if (_themeStyle == style) return;

    _themeStyle = style;
    await _savePreference(_themeStyleKey, style.index);
    _triggerHaptic();
    notifyListeners();
  }

  // Arabic font
  Future<void> setArabicFont(ArabicFontFamily font) async {
    if (_arabicFont == font) return;

    _arabicFont = font;
    await _savePreference(_arabicFontKey, font.index);
    _triggerHaptic();
    notifyListeners();
  }

  // Font scale
  Future<void> setFontScale(double scale) async {
    scale = scale.clamp(0.7, 2.0);
    if (_fontScale == scale) return;

    _fontScale = scale;
    await _savePreference(_fontScaleKey, scale);
    _triggerHaptic();
    notifyListeners();
  }

  // Arabic font size
  Future<void> setArabicFontSize(double size) async {
    size = size.clamp(14.0, 32.0);
    if (_arabicFontSize == size) return;

    _arabicFontSize = size;
    await _savePreference(_arabicFontSizeKey, size);
    _triggerHaptic();
    notifyListeners();
  }

  // Reading mode
  Future<void> setReadingMode(ReadingMode mode) async {
    if (_readingMode == mode) return;

    _readingMode = mode;
    await _savePreference(_readingModeKey, mode.index);
    _triggerHaptic();
    notifyListeners();
  }

  // Convenience methods for reading modes
  Future<void> enableNightReadingMode(bool enabled) async {
    await setReadingMode(enabled ? ReadingMode.night : ReadingMode.normal);
  }

  Future<void> enableComfortReadingMode(bool enabled) async {
    await setReadingMode(enabled ? ReadingMode.comfort : ReadingMode.normal);
  }

  // High contrast
  Future<void> setHighContrast(bool enabled) async {
    if (_isHighContrast == enabled) return;

    _isHighContrast = enabled;
    await _savePreference(_isHighContrastKey, enabled);
    _triggerHaptic();
    notifyListeners();
  }

  // Reduce animations
  Future<void> setReduceAnimations(bool enabled) async {
    if (_reduceAnimations == enabled) return;

    _reduceAnimations = enabled;
    await _savePreference(_reduceAnimationsKey, enabled);
    _triggerHaptic();
    notifyListeners();
  }

  // Enable haptics
  Future<void> setEnableHaptics(bool enabled) async {
    if (_enableHaptics == enabled) return;

    _enableHaptics = enabled;
    await _savePreference(_enableHapticsKey, enabled);
    if (enabled) _triggerHaptic();
    notifyListeners();
  }

  // Auto theme (dynamic color)
  Future<void> setAutoTheme(bool enabled) async {
    if (_autoTheme == enabled) return;

    _autoTheme = enabled;
    await _savePreference(_autoThemeKey, enabled);
    _triggerHaptic();
    notifyListeners();
  }

  // Quick preset methods
  Future<void> applyIslamicPreset() async {
    await setThemeStyle(AppThemeStyle.islamic);
    await setArabicFont(ArabicFontFamily.cairo);
  }

  Future<void> applyElegantPreset() async {
    await setThemeStyle(AppThemeStyle.elegant);
    await setArabicFont(ArabicFontFamily.amiri);
  }

  Future<void> applyModernPreset() async {
    await setThemeStyle(AppThemeStyle.ocean);
    await setArabicFont(ArabicFontFamily.notoSansArabic);
  }

  // Accessibility helpers
  Future<void> enableAccessibilityMode() async {
    await setHighContrast(true);
    await setReduceAnimations(true);
    await setFontScale(1.2);
  }

  Future<void> disableAccessibilityMode() async {
    await setHighContrast(false);
    await setReduceAnimations(false);
    await setFontScale(1.0);
  }

  // Reset to defaults
  Future<void> resetToDefaults() async {
    await setThemeMode(ThemeMode.system);
    await setThemeStyle(AppThemeStyle.islamic);
    await setArabicFont(ArabicFontFamily.cairo);
    await setFontScale(1.0);
    await setHighContrast(false);
    await setReduceAnimations(false);
    await setEnableHaptics(true);
    await setAutoTheme(false);
    await setReadingMode(ReadingMode.normal);
    await setArabicFontSize(20.0);
  }

  // Helper methods
  Future<void> _savePreference(String key, dynamic value) async {
    final prefs = await SharedPreferences.getInstance();
    if (value is bool) {
      await prefs.setBool(key, value);
    } else if (value is int) {
      await prefs.setInt(key, value);
    } else if (value is double) {
      await prefs.setDouble(key, value);
    } else if (value is String) {
      await prefs.setString(key, value);
    }
  }

  void _triggerHaptic() {
    if (_enableHaptics) {
      HapticFeedback.lightImpact();
    }
  }

  // Getters for theme-specific colors and gradients
  Gradient get currentGradient {
    switch (_themeStyle) {
      case AppThemeStyle.islamic:
        return AppTheme.islamicGradient;
      case AppThemeStyle.ocean:
        return AppTheme.oceanGradient;
      case AppThemeStyle.sunset:
        return AppTheme.sunsetGradient;
      case AppThemeStyle.forest:
        return AppTheme.forestGradient;
      case AppThemeStyle.royal:
        return AppTheme.islamicGradient; // Default fallback
      case AppThemeStyle.elegant:
        return AppTheme.islamicGradient; // Default fallback
    }
  }

  // Check if current theme is dark
  bool isDarkTheme(BuildContext context) {
    if (_themeMode == ThemeMode.system) {
      return MediaQuery.of(context).platformBrightness == Brightness.dark;
    }
    return _themeMode == ThemeMode.dark;
  }

  // Get contrast ratio for accessibility
  double getContrastRatio(Color foreground, Color background) {
    final fLuminance = _calculateLuminance(foreground);
    final bLuminance = _calculateLuminance(background);
    final lighter = math.max(fLuminance, bLuminance);
    final darker = math.min(fLuminance, bLuminance);
    return (lighter + 0.05) / (darker + 0.05);
  }

  double _calculateLuminance(Color color) {
    final r = _linearize(color.r / 255.0);
    final g = _linearize(color.g / 255.0);
    final b = _linearize(color.b / 255.0);
    return 0.2126 * r + 0.7152 * g + 0.0722 * b;
  }

  double _linearize(double colorChannel) {
    if (colorChannel <= 0.03928) {
      return colorChannel / 12.92;
    } else {
      return math.pow((colorChannel + 0.055) / 1.055, 2.4).toDouble();
    }
  }
}
