import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:screen_brightness/screen_brightness.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:dynamic_color/dynamic_color.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'core/utils/dependency_injection.dart';
import 'core/utils/app_theme.dart';
import 'core/utils/route_observer.dart';
import 'data/models/cached_surah.dart';
import 'data/models/bookmark.dart';
import 'presentation/providers/preference_settings_provider.dart';
import 'presentation/providers/reading_progress_provider.dart';
import 'presentation/providers/enhanced_theme_provider.dart';
import 'presentation/providers/chat_history_provider.dart';
import 'presentation/screens/main_screen.dart';
import 'presentation/screens/onboarding_screen.dart';
import 'presentation/providers/cache_provider.dart';
import 'services/auto_cache_service.dart';
import 'services/prayer_notification_service.dart';
import 'services/accessibility_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables
  await dotenv.load(fileName: ".env");

  // Initialize Hive for local storage
  await Hive.initFlutter();

  // Register Hive adapters for cached models
  Hive.registerAdapter(CachedSurahAdapter());
  Hive.registerAdapter(CachedAyahAdapter());
  Hive.registerAdapter(BookmarkAdapter());

  // Initialize clean architecture dependencies
  await DependencyInjection.init();

  // Initialize auto-preloading of popular surahs in background
  _initializeCache();

  // Initialize prayer notification service
  _initializeServices();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => PreferenceSettingsProvider()),
        ChangeNotifierProvider.value(
            value: DependencyInjection.bookmarksProvider),
        ChangeNotifierProvider.value(value: DependencyInjection.surahProvider),
        ChangeNotifierProvider(create: (_) => ReadingProgressProvider()),
        ChangeNotifierProvider(create: (_) => EnhancedThemeProvider()),
        ChangeNotifierProvider(create: (_) => ChatHistoryProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

void _initializeCache() {
  // Cache common surahs in background for permanent offline access
  Future.delayed(const Duration(seconds: 2), () {
    AutoCacheService.cacheCommonSurahs();
  });
}

void _initializeServices() {
  // Initialize prayer notifications and daily ayah
  Future.delayed(const Duration(seconds: 3), () async {
    try {
      await PrayerNotificationService.initialize();
      await PrayerNotificationService.scheduleDailyAyahNotification();

      // Initialize accessibility service
      await AccessibilityService().initialize();
    } catch (e) {
      // Failed to initialize services: $e
    }
  });
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
    // Load theme settings
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<EnhancedThemeProvider>().loadSettings();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<EnhancedThemeProvider>(
      builder: (context, themeProvider, _) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Quran App - القرآن الكريم',

          // Material 3 themes with enhanced customization
          theme: themeProvider.lightTheme,
          darkTheme: themeProvider.darkTheme,
          themeMode: themeProvider.themeMode,

          // Localization support
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [
            Locale('en', ''), // English
            Locale('ar', ''), // Arabic
            Locale('ur', ''), // Urdu
            Locale('fr', ''), // French
            Locale('id', ''), // Indonesian
          ],

          // Use system locale by default
          locale: const Locale('en', ''),

          home: const AppInitializer(),
        );
      },
    );
  }
}

class AppInitializer extends StatefulWidget {
  const AppInitializer({super.key});

  @override
  State<AppInitializer> createState() => _AppInitializerState();
}

class _AppInitializerState extends State<AppInitializer> {
  bool _isLoading = true;
  bool _showOnboarding = false;

  @override
  void initState() {
    super.initState();
    _checkOnboardingStatus();
  }

  Future<void> _checkOnboardingStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final hasCompletedOnboarding =
        prefs.getBool('onboarding_completed') ?? false;

    await Future.delayed(const Duration(seconds: 1)); // Splash delay

    setState(() {
      _showOnboarding = !hasCompletedOnboarding;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image(
                image: AssetImage('assets/icon_quran.png'),
                width: 100,
                height: 100,
              ),
              SizedBox(height: 24),
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF667eea)),
              ),
              SizedBox(height: 16),
              Text(
                'Quran App',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF667eea),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return _showOnboarding ? const OnboardingScreen() : const MainScreen();
  }
}
