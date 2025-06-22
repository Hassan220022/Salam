import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/preference_settings_provider.dart';
import '../providers/enhanced_theme_provider.dart';
import 'bookmark.dart';
import 'surah_list.dart';
import 'prayer.dart';
import 'settings_screen.dart';
import 'islamic_ai_assistant_screen.dart';
import '../../core/utils/route_observer.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> with RouteAware {
  int _selectedIndex = 0;

  // List of screens for navigation
  final List<Widget> _screens = [
    const SurahListScreen(),
    const BookmarkScreen(),
    const PrayerTimesWidget(),
    const IslamicAIAssistantScreen(),
    const SettingsScreen(),
  ];

  final List<String> _titles = [
    'Holy Quran',
    'Bookmarks',
    'Prayers',
    'AI Assistant',
    'Settings',
  ];

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route is PageRoute) {
      routeObserver.subscribe(this, route);
    }
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    super.dispose();
  }

  // Handle bottom navigation item tap
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<PreferenceSettingsProvider, EnhancedThemeProvider>(
      builder: (context, prefProvider, themeProvider, child) {
        final isDarkTheme = themeProvider.isDarkTheme(context);
        final colorScheme = Theme.of(context).colorScheme;

        return Scaffold(
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            title: Text(
              _titles[_selectedIndex],
              style: TextStyle(
                color: colorScheme.onSurface,
                fontWeight: FontWeight.bold,
              ),
            ),
            leading: Padding(
              padding: const EdgeInsets.only(left: 16.0),
              child: Image.asset(
                isDarkTheme
                    ? 'assets/icon_quran_white.png'
                    : 'assets/icon_quran.png',
                width: 28.0,
              ),
            ),
            actions: [
              IconButton(
                icon: Icon(
                  isDarkTheme ? Icons.light_mode : Icons.dark_mode,
                  color: colorScheme.onSurface,
                ),
                onPressed: () {
                  final newMode =
                      isDarkTheme ? ThemeMode.light : ThemeMode.dark;
                  themeProvider.setThemeMode(newMode);
                },
              ),
            ],
          ),
          body: _screens[_selectedIndex],
          bottomNavigationBar: Container(
            decoration: BoxDecoration(
              boxShadow: [
                BoxShadow(
                  color: colorScheme.shadow.withValues(alpha: 0.1),
                  blurRadius: 8,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: BottomNavigationBar(
              selectedItemColor: colorScheme.primary,
              unselectedItemColor: colorScheme.onSurfaceVariant,
              backgroundColor: colorScheme.surface,
              currentIndex: _selectedIndex,
              type: BottomNavigationBarType.fixed,
              elevation: 0,
              selectedFontSize: 12,
              unselectedFontSize: 12,
              onTap: _onItemTapped,
              items: const [
                BottomNavigationBarItem(
                  icon: Icon(Icons.menu_book_rounded),
                  label: 'Quran',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.bookmark_rounded),
                  label: 'Bookmarks',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.access_time_rounded),
                  label: 'Prayers',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.auto_awesome_rounded),
                  label: 'Assistant',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.settings_rounded),
                  label: 'Settings',
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
