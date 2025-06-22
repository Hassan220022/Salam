/// Pure business entity representing user preferences and settings
/// Contains no dependencies on frameworks or external libraries
class UserPreferences {
  final ThemeSettings theme;
  final ReadingSettings reading;
  final AccessibilitySettings accessibility;
  final NotificationSettings notifications;
  final AudioSettings audio;
  final LocationSettings location;

  const UserPreferences({
    required this.theme,
    required this.reading,
    required this.accessibility,
    required this.notifications,
    required this.audio,
    required this.location,
  });

  /// Create default user preferences
  static UserPreferences defaultSettings() {
    return UserPreferences(
      theme: ThemeSettings.defaultSettings(),
      reading: ReadingSettings.defaultSettings(),
      accessibility: AccessibilitySettings.defaultSettings(),
      notifications: NotificationSettings.defaultSettings(),
      audio: AudioSettings.defaultSettings(),
      location: LocationSettings.defaultSettings(),
    );
  }

  /// Copy with modified settings
  UserPreferences copyWith({
    ThemeSettings? theme,
    ReadingSettings? reading,
    AccessibilitySettings? accessibility,
    NotificationSettings? notifications,
    AudioSettings? audio,
    LocationSettings? location,
  }) {
    return UserPreferences(
      theme: theme ?? this.theme,
      reading: reading ?? this.reading,
      accessibility: accessibility ?? this.accessibility,
      notifications: notifications ?? this.notifications,
      audio: audio ?? this.audio,
      location: location ?? this.location,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UserPreferences &&
        other.theme == theme &&
        other.reading == reading &&
        other.accessibility == accessibility &&
        other.notifications == notifications &&
        other.audio == audio &&
        other.location == location;
  }

  @override
  int get hashCode {
    return Object.hash(
      theme,
      reading,
      accessibility,
      notifications,
      audio,
      location,
    );
  }
}

/// Theme and appearance settings
class ThemeSettings {
  final ThemeMode mode;
  final ThemeStyle style;
  final bool isDynamicColorEnabled;
  final bool isHighContrastEnabled;
  final double fontScale;

  const ThemeSettings({
    required this.mode,
    required this.style,
    required this.isDynamicColorEnabled,
    required this.isHighContrastEnabled,
    required this.fontScale,
  });

  static ThemeSettings defaultSettings() {
    return const ThemeSettings(
      mode: ThemeMode.system,
      style: ThemeStyle.islamic,
      isDynamicColorEnabled: true,
      isHighContrastEnabled: false,
      fontScale: 1.0,
    );
  }

  ThemeSettings copyWith({
    ThemeMode? mode,
    ThemeStyle? style,
    bool? isDynamicColorEnabled,
    bool? isHighContrastEnabled,
    double? fontScale,
  }) {
    return ThemeSettings(
      mode: mode ?? this.mode,
      style: style ?? this.style,
      isDynamicColorEnabled:
          isDynamicColorEnabled ?? this.isDynamicColorEnabled,
      isHighContrastEnabled:
          isHighContrastEnabled ?? this.isHighContrastEnabled,
      fontScale: fontScale ?? this.fontScale,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ThemeSettings &&
        other.mode == mode &&
        other.style == style &&
        other.isDynamicColorEnabled == isDynamicColorEnabled &&
        other.isHighContrastEnabled == isHighContrastEnabled &&
        other.fontScale == fontScale;
  }

  @override
  int get hashCode {
    return Object.hash(
      mode,
      style,
      isDynamicColorEnabled,
      isHighContrastEnabled,
      fontScale,
    );
  }
}

/// Reading experience settings
class ReadingSettings {
  final ArabicFont arabicFont;
  final double arabicFontSize;
  final double translationFontSize;
  final String preferredTranslation;
  final String preferredTafsir;
  final bool showTranslation;
  final bool showTafsir;
  final bool nightReadingMode;

  const ReadingSettings({
    required this.arabicFont,
    required this.arabicFontSize,
    required this.translationFontSize,
    required this.preferredTranslation,
    required this.preferredTafsir,
    required this.showTranslation,
    required this.showTafsir,
    required this.nightReadingMode,
  });

  static ReadingSettings defaultSettings() {
    return const ReadingSettings(
      arabicFont: ArabicFont.amiri,
      arabicFontSize: 20.0,
      translationFontSize: 16.0,
      preferredTranslation: 'en.sahih',
      preferredTafsir: 'en.jalalayn',
      showTranslation: true,
      showTafsir: false,
      nightReadingMode: false,
    );
  }

  ReadingSettings copyWith({
    ArabicFont? arabicFont,
    double? arabicFontSize,
    double? translationFontSize,
    String? preferredTranslation,
    String? preferredTafsir,
    bool? showTranslation,
    bool? showTafsir,
    bool? nightReadingMode,
  }) {
    return ReadingSettings(
      arabicFont: arabicFont ?? this.arabicFont,
      arabicFontSize: arabicFontSize ?? this.arabicFontSize,
      translationFontSize: translationFontSize ?? this.translationFontSize,
      preferredTranslation: preferredTranslation ?? this.preferredTranslation,
      preferredTafsir: preferredTafsir ?? this.preferredTafsir,
      showTranslation: showTranslation ?? this.showTranslation,
      showTafsir: showTafsir ?? this.showTafsir,
      nightReadingMode: nightReadingMode ?? this.nightReadingMode,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ReadingSettings &&
        other.arabicFont == arabicFont &&
        other.arabicFontSize == arabicFontSize &&
        other.translationFontSize == translationFontSize &&
        other.preferredTranslation == preferredTranslation &&
        other.preferredTafsir == preferredTafsir &&
        other.showTranslation == showTranslation &&
        other.showTafsir == showTafsir &&
        other.nightReadingMode == nightReadingMode;
  }

  @override
  int get hashCode {
    return Object.hash(
      arabicFont,
      arabicFontSize,
      translationFontSize,
      preferredTranslation,
      preferredTafsir,
      showTranslation,
      showTafsir,
      nightReadingMode,
    );
  }
}

/// Accessibility settings
class AccessibilitySettings {
  final bool isTtsEnabled;
  final double ttsSpeed;
  final double ttsPitch;
  final double ttsVolume;
  final String ttsLanguage;
  final bool autoReadEnabled;
  final bool hapticFeedbackEnabled;
  final bool reduceAnimations;
  final bool screenReaderOptimized;

  const AccessibilitySettings({
    required this.isTtsEnabled,
    required this.ttsSpeed,
    required this.ttsPitch,
    required this.ttsVolume,
    required this.ttsLanguage,
    required this.autoReadEnabled,
    required this.hapticFeedbackEnabled,
    required this.reduceAnimations,
    required this.screenReaderOptimized,
  });

  static AccessibilitySettings defaultSettings() {
    return const AccessibilitySettings(
      isTtsEnabled: false,
      ttsSpeed: 0.5,
      ttsPitch: 1.0,
      ttsVolume: 0.8,
      ttsLanguage: 'en-US',
      autoReadEnabled: false,
      hapticFeedbackEnabled: true,
      reduceAnimations: false,
      screenReaderOptimized: false,
    );
  }

  AccessibilitySettings copyWith({
    bool? isTtsEnabled,
    double? ttsSpeed,
    double? ttsPitch,
    double? ttsVolume,
    String? ttsLanguage,
    bool? autoReadEnabled,
    bool? hapticFeedbackEnabled,
    bool? reduceAnimations,
    bool? screenReaderOptimized,
  }) {
    return AccessibilitySettings(
      isTtsEnabled: isTtsEnabled ?? this.isTtsEnabled,
      ttsSpeed: ttsSpeed ?? this.ttsSpeed,
      ttsPitch: ttsPitch ?? this.ttsPitch,
      ttsVolume: ttsVolume ?? this.ttsVolume,
      ttsLanguage: ttsLanguage ?? this.ttsLanguage,
      autoReadEnabled: autoReadEnabled ?? this.autoReadEnabled,
      hapticFeedbackEnabled:
          hapticFeedbackEnabled ?? this.hapticFeedbackEnabled,
      reduceAnimations: reduceAnimations ?? this.reduceAnimations,
      screenReaderOptimized:
          screenReaderOptimized ?? this.screenReaderOptimized,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AccessibilitySettings &&
        other.isTtsEnabled == isTtsEnabled &&
        other.ttsSpeed == ttsSpeed &&
        other.ttsPitch == ttsPitch &&
        other.ttsVolume == ttsVolume &&
        other.ttsLanguage == ttsLanguage &&
        other.autoReadEnabled == autoReadEnabled &&
        other.hapticFeedbackEnabled == hapticFeedbackEnabled &&
        other.reduceAnimations == reduceAnimations &&
        other.screenReaderOptimized == screenReaderOptimized;
  }

  @override
  int get hashCode {
    return Object.hash(
      isTtsEnabled,
      ttsSpeed,
      ttsPitch,
      ttsVolume,
      ttsLanguage,
      autoReadEnabled,
      hapticFeedbackEnabled,
      reduceAnimations,
      screenReaderOptimized,
    );
  }
}

/// Notification settings
class NotificationSettings {
  final bool prayerNotificationsEnabled;
  final bool dailyAyahEnabled;
  final int prayerReminderMinutes;
  final bool soundEnabled;
  final bool vibrationEnabled;

  const NotificationSettings({
    required this.prayerNotificationsEnabled,
    required this.dailyAyahEnabled,
    required this.prayerReminderMinutes,
    required this.soundEnabled,
    required this.vibrationEnabled,
  });

  static NotificationSettings defaultSettings() {
    return const NotificationSettings(
      prayerNotificationsEnabled: true,
      dailyAyahEnabled: true,
      prayerReminderMinutes: 10,
      soundEnabled: true,
      vibrationEnabled: true,
    );
  }

  NotificationSettings copyWith({
    bool? prayerNotificationsEnabled,
    bool? dailyAyahEnabled,
    int? prayerReminderMinutes,
    bool? soundEnabled,
    bool? vibrationEnabled,
  }) {
    return NotificationSettings(
      prayerNotificationsEnabled:
          prayerNotificationsEnabled ?? this.prayerNotificationsEnabled,
      dailyAyahEnabled: dailyAyahEnabled ?? this.dailyAyahEnabled,
      prayerReminderMinutes:
          prayerReminderMinutes ?? this.prayerReminderMinutes,
      soundEnabled: soundEnabled ?? this.soundEnabled,
      vibrationEnabled: vibrationEnabled ?? this.vibrationEnabled,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is NotificationSettings &&
        other.prayerNotificationsEnabled == prayerNotificationsEnabled &&
        other.dailyAyahEnabled == dailyAyahEnabled &&
        other.prayerReminderMinutes == prayerReminderMinutes &&
        other.soundEnabled == soundEnabled &&
        other.vibrationEnabled == vibrationEnabled;
  }

  @override
  int get hashCode {
    return Object.hash(
      prayerNotificationsEnabled,
      dailyAyahEnabled,
      prayerReminderMinutes,
      soundEnabled,
      vibrationEnabled,
    );
  }
}

/// Audio settings
class AudioSettings {
  final String selectedReciter;
  final double volume;
  final double playbackSpeed;
  final bool autoPlayNext;
  final bool downloadHighQuality;

  const AudioSettings({
    required this.selectedReciter,
    required this.volume,
    required this.playbackSpeed,
    required this.autoPlayNext,
    required this.downloadHighQuality,
  });

  static AudioSettings defaultSettings() {
    return const AudioSettings(
      selectedReciter: 'ar.alafasy',
      volume: 0.8,
      playbackSpeed: 1.0,
      autoPlayNext: false,
      downloadHighQuality: true,
    );
  }

  AudioSettings copyWith({
    String? selectedReciter,
    double? volume,
    double? playbackSpeed,
    bool? autoPlayNext,
    bool? downloadHighQuality,
  }) {
    return AudioSettings(
      selectedReciter: selectedReciter ?? this.selectedReciter,
      volume: volume ?? this.volume,
      playbackSpeed: playbackSpeed ?? this.playbackSpeed,
      autoPlayNext: autoPlayNext ?? this.autoPlayNext,
      downloadHighQuality: downloadHighQuality ?? this.downloadHighQuality,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AudioSettings &&
        other.selectedReciter == selectedReciter &&
        other.volume == volume &&
        other.playbackSpeed == playbackSpeed &&
        other.autoPlayNext == autoPlayNext &&
        other.downloadHighQuality == downloadHighQuality;
  }

  @override
  int get hashCode {
    return Object.hash(
      selectedReciter,
      volume,
      playbackSpeed,
      autoPlayNext,
      downloadHighQuality,
    );
  }
}

/// Location settings
class LocationSettings {
  final bool autoDetectLocation;
  final double? latitude;
  final double? longitude;
  final String? manualCity;
  final String? manualCountry;
  final CalculationMethod calculationMethod;

  const LocationSettings({
    required this.autoDetectLocation,
    this.latitude,
    this.longitude,
    this.manualCity,
    this.manualCountry,
    required this.calculationMethod,
  });

  static LocationSettings defaultSettings() {
    return const LocationSettings(
      autoDetectLocation: true,
      calculationMethod: CalculationMethod.muslimWorldLeague,
    );
  }

  LocationSettings copyWith({
    bool? autoDetectLocation,
    double? latitude,
    double? longitude,
    String? manualCity,
    String? manualCountry,
    CalculationMethod? calculationMethod,
  }) {
    return LocationSettings(
      autoDetectLocation: autoDetectLocation ?? this.autoDetectLocation,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      manualCity: manualCity ?? this.manualCity,
      manualCountry: manualCountry ?? this.manualCountry,
      calculationMethod: calculationMethod ?? this.calculationMethod,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is LocationSettings &&
        other.autoDetectLocation == autoDetectLocation &&
        other.latitude == latitude &&
        other.longitude == longitude &&
        other.manualCity == manualCity &&
        other.manualCountry == manualCountry &&
        other.calculationMethod == calculationMethod;
  }

  @override
  int get hashCode {
    return Object.hash(
      autoDetectLocation,
      latitude,
      longitude,
      manualCity,
      manualCountry,
      calculationMethod,
    );
  }
}

// Enums for various settings
enum ThemeMode { light, dark, system }

enum ThemeStyle { islamic, oceanBlue, sunset, forest, royalPurple, elegantDark }

enum ArabicFont { amiri, scheherazadeNew, notoSansArabic, cairo, tajawal }

enum CalculationMethod {
  muslimWorldLeague,
  egyptian,
  karachi,
  ummAlQura,
  dubai,
  moon,
  north
}
