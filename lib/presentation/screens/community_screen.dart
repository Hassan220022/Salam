import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/community_service.dart';
import '../providers/preference_settings_provider.dart';

class CommunityScreen extends StatefulWidget {
  const CommunityScreen({super.key});

  @override
  State<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen>
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
          'Community',
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
            Tab(text: 'Daily Ayah', icon: Icon(Icons.auto_awesome)),
            Tab(text: 'Statistics', icon: Icon(Icons.analytics)),
            Tab(text: 'Share', icon: Icon(Icons.share)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildDailyAyahTab(isDarkTheme),
          _buildStatisticsTab(isDarkTheme),
          _buildShareTab(isDarkTheme),
        ],
      ),
    );
  }

  Widget _buildDailyAyahTab(bool isDarkTheme) {
    final dailyAyah = CommunityService.getDailyAyah();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Daily ayah card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
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
                  Icons.auto_awesome,
                  color: Colors.white,
                  size: 32,
                ),
                const SizedBox(height: 12),
                const Text(
                  'Daily Ayah',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 20),

                // Arabic text
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    dailyAyah['arabic'],
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                      height: 1.8,
                    ),
                    textAlign: TextAlign.center,
                    textDirection: TextDirection.rtl,
                  ),
                ),
                const SizedBox(height: 16),

                // Translation
                Text(
                  dailyAyah['translation'],
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.white,
                    height: 1.6,
                    fontStyle: FontStyle.italic,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),

                // Reference
                Text(
                  '— ${dailyAyah['surah']} ${dailyAyah['surahNumber']}:${dailyAyah['ayahNumber']}',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.white70,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Share button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _shareAyah(dailyAyah),
              icon: const Icon(Icons.share),
              label: const Text('Share Daily Ayah'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF667eea),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatisticsTab(bool isDarkTheme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.analytics,
              size: 64,
              color: isDarkTheme ? Colors.white54 : Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              'Reading Statistics',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: isDarkTheme ? Colors.white : const Color(0xFF091945),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Track your reading progress, streaks, and sharing activity.',
              style: TextStyle(
                fontSize: 16,
                color: isDarkTheme ? Colors.white70 : Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Text(
              'Statistics will appear here as you read and share ayahs.',
              style: TextStyle(
                fontSize: 14,
                color: isDarkTheme ? Colors.white54 : Colors.grey.shade500,
                fontStyle: FontStyle.italic,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShareTab(bool isDarkTheme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Share Features',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: isDarkTheme ? Colors.white : const Color(0xFF091945),
            ),
          ),
          const SizedBox(height: 16),

          // Share platforms
          _buildSharePlatforms(isDarkTheme),
          const SizedBox(height: 24),

          // How to share guide
          _buildShareGuide(isDarkTheme),
        ],
      ),
    );
  }

  Widget _buildSharePlatforms(bool isDarkTheme) {
    final platforms = [
      {'name': 'WhatsApp', 'icon': Icons.message, 'color': Colors.green},
      {'name': 'Twitter', 'icon': Icons.alternate_email, 'color': Colors.blue},
      {'name': 'Facebook', 'icon': Icons.facebook, 'color': Colors.indigo},
      {'name': 'General Share', 'icon': Icons.share, 'color': Colors.orange},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Available Platforms',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: isDarkTheme ? Colors.white : const Color(0xFF091945),
          ),
        ),
        const SizedBox(height: 16),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: 1.5,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          children: platforms
              .map((platform) => Container(
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
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                  '${platform['name']} sharing available in reading mode'),
                              backgroundColor: platform['color'] as Color,
                            ),
                          );
                        },
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              platform['icon'] as IconData,
                              color: platform['color'] as Color,
                              size: 32,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              platform['name'] as String,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: isDarkTheme
                                    ? Colors.white
                                    : const Color(0xFF091945),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ))
              .toList(),
        ),
      ],
    );
  }

  Widget _buildShareGuide(bool isDarkTheme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.info_outline,
                color: Colors.blue.shade700,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'How to Share Ayahs',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue.shade700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '1. While reading any surah, tap and hold on an ayah\n'
            '2. Select "Share" from the context menu\n'
            '3. Choose your preferred platform\n'
            '4. Add a personal message if desired\n'
            '5. Share the beautiful verse with others!',
            style: TextStyle(
              fontSize: 14,
              height: 1.5,
              color: Colors.blue.shade800,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _shareAyah(Map<String, dynamic> ayah) async {
    try {
      await CommunityService.shareAyah(
        ayahText: ayah['arabic'],
        ayahTranslation: ayah['translation'],
        surahName: ayah['surah'],
        surahNumber: ayah['surahNumber'],
        ayahNumber: ayah['ayahNumber'],
        customMessage: 'Today\'s inspiration from the Quran:',
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error sharing ayah: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
