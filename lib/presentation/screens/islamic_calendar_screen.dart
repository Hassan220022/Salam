import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/preference_settings_provider.dart';

class IslamicCalendarScreen extends StatefulWidget {
  const IslamicCalendarScreen({super.key});

  @override
  State<IslamicCalendarScreen> createState() => _IslamicCalendarScreenState();
}

class _IslamicCalendarScreenState extends State<IslamicCalendarScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkTheme =
        Provider.of<PreferenceSettingsProvider>(context).isDarkTheme;

    return Scaffold(
      backgroundColor: isDarkTheme ? const Color(0xFF091945) : Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Islamic Calendar',
          style: TextStyle(
            color: isDarkTheme ? Colors.white : const Color(0xFF091945),
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: isDarkTheme ? Colors.white : const Color(0xFF091945),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFF667eea),
          labelColor: isDarkTheme ? Colors.white : const Color(0xFF091945),
          unselectedLabelColor:
              isDarkTheme ? Colors.white70 : Colors.grey.shade600,
          tabs: const [
            Tab(text: 'Today', icon: Icon(Icons.today)),
            Tab(text: 'Events', icon: Icon(Icons.event)),
            Tab(text: 'Ramadan', icon: Icon(Icons.nights_stay)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildTodayTab(isDarkTheme),
          _buildEventsTab(isDarkTheme),
          _buildRamadanTab(isDarkTheme),
        ],
      ),
    );
  }

  Widget _buildTodayTab(bool isDarkTheme) {
    // Simplified version without hijri package
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Current date card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF667eea), Color(0xFF764ba2)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Column(
              children: [
                Text(
                  'Today\'s Date',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  DateFormat('EEEE, MMMM d, yyyy').format(DateTime.now()),
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.white70,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Placeholder for hijri features
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDarkTheme
                  ? Colors.white.withOpacity(0.05)
                  : Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDarkTheme
                    ? Colors.white.withOpacity(0.1)
                    : Colors.grey.shade200,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color:
                          isDarkTheme ? Colors.white : const Color(0xFF091945),
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Islamic Calendar Features',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isDarkTheme
                            ? Colors.white
                            : const Color(0xFF091945),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  'Islamic calendar features will be available once dependencies are properly installed.',
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.5,
                    color: isDarkTheme ? Colors.white70 : Colors.grey.shade700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEventsTab(bool isDarkTheme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Important Islamic Events',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: isDarkTheme ? Colors.white : const Color(0xFF091945),
            ),
          ),
          const SizedBox(height: 16),

          // Sample events
          _buildEventCard('Ramadan begins',
              DateTime.now().add(const Duration(days: 30)), isDarkTheme),
          _buildEventCard('Eid al-Fitr',
              DateTime.now().add(const Duration(days: 60)), isDarkTheme),
          _buildEventCard('Hajj begins',
              DateTime.now().add(const Duration(days: 120)), isDarkTheme),
          _buildEventCard('Eid al-Adha',
              DateTime.now().add(const Duration(days: 125)), isDarkTheme),
        ],
      ),
    );
  }

  Widget _buildRamadanTab(bool isDarkTheme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF667eea), Color(0xFF764ba2)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Column(
              children: [
                const Icon(
                  Icons.nights_stay,
                  color: Colors.white,
                  size: 40,
                ),
                const SizedBox(height: 12),
                const Text(
                  'Ramadan Information',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'The holy month of fasting',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDarkTheme
                  ? Colors.white.withOpacity(0.05)
                  : Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDarkTheme
                    ? Colors.white.withOpacity(0.1)
                    : Colors.grey.shade200,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color:
                          isDarkTheme ? Colors.white : const Color(0xFF091945),
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'About Ramadan',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isDarkTheme
                            ? Colors.white
                            : const Color(0xFF091945),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  'Ramadan is the ninth month of the Islamic calendar and is the holy month of fasting for Muslims. During this month, Muslims fast from dawn (Fajr) to sunset (Maghrib), abstaining from food, drink, and other physical pleasures.',
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.5,
                    color: isDarkTheme ? Colors.white70 : Colors.grey.shade700,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Key practices during Ramadan:\n• Fasting (Sawm)\n• Increased prayer and Quran reading\n• Charity (Zakat)\n• Night prayers (Tarawih)\n• Seeking Laylat al-Qadr',
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.5,
                    color: isDarkTheme ? Colors.white70 : Colors.grey.shade700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEventCard(String name, DateTime date, bool isDarkTheme) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color:
            isDarkTheme ? Colors.white.withOpacity(0.05) : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDarkTheme
              ? Colors.white.withOpacity(0.1)
              : Colors.grey.shade200,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF667eea),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.event,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: isDarkTheme ? Colors.white : const Color(0xFF091945),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  DateFormat('MMM d, yyyy').format(date),
                  style: TextStyle(
                    fontSize: 14,
                    color: isDarkTheme ? Colors.white70 : Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
