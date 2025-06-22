class AppConstants {
  // App Information
  static const String appName = 'Quran App - القرآن الكريم';
  static const String appVersion = '2.0.0';
  static const String appDescription =
      'A beautiful and comprehensive Quran reading app';

  // API Configuration
  static const String quranApiBaseUrl = 'https://api.alquran.cloud/v1';
  static const String prayerTimesApiBaseUrl = 'https://api.aladhan.com/v1';
  static const String audioBaseUrl = 'https://cdn.islamic.network/quran/audio';

  // Quran Data
  static const int totalSurahs = 114;
  static const int totalVerses = 6236;
  static const int totalPages = 604;
  static const int totalParas = 30;

  // Cache Configuration
  static const int maxCacheSize = 100; // MB
  static const Duration cacheExpiry = Duration(days: 7);
  static const Duration audioTokenExpiry = Duration(hours: 24);

  // UI Configuration
  static const double defaultArabicFontSize = 20.0;
  static const double minArabicFontSize = 14.0;
  static const double maxArabicFontSize = 32.0;
  static const double defaultFontScale = 1.0;
  static const double minFontScale = 0.7;
  static const double maxFontScale = 2.0;

  // Notification Configuration
  static const int prayerNotificationId = 1001;
  static const int dailyAyahNotificationId = 1002;
  static const String notificationChannelId = 'quran_app_channel';
  static const String notificationChannelName = 'Quran App Notifications';

  // Storage Keys
  static const String keyOnboardingCompleted = 'onboarding_completed';
  static const String keyThemeMode = 'theme_mode';
  static const String keyArabicFont = 'arabic_font';
  static const String keySelectedReciter = 'selected_reciter';
  static const String keyPreferredTranslation = 'preferred_translation';
  static const String keyLastReadSurah = 'last_read_surah';
  static const String keyLastReadVerse = 'last_read_verse';

  // Default Values
  static const String defaultReciter = 'ar.alafasy';
  static const String defaultTranslation = 'en.sahih';
  static const String defaultTafsir = 'en.jalalayn';
}
