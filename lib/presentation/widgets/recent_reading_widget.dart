import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/reading_progress_provider.dart';
import '../providers/preference_settings_provider.dart';
import '../screens/surah_reader.dart';

class RecentReadingWidget extends StatelessWidget {
  const RecentReadingWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final progressProvider = Provider.of<ReadingProgressProvider>(context);
    final prefProvider = Provider.of<PreferenceSettingsProvider>(context);
    final recentlyRead = progressProvider.getRecentlyRead();
    final isDarkTheme = prefProvider.isDarkTheme;

    if (recentlyRead.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.all(16.0),
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDarkTheme
              ? [const Color(0xFF2a2a3e), const Color(0xFF1e1e2e)]
              : [const Color(0xFFfafafa), Colors.white],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20.0),
        boxShadow: [
          BoxShadow(
            color: isDarkTheme
                ? Colors.black.withValues(alpha: 0.4)
                : Colors.grey.withValues(alpha: 0.15),
            blurRadius: 15,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [const Color(0xFF667eea), const Color(0xFF764ba2)],
                  ),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: const Icon(
                  Icons.history,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 16),
              Text(
                'Continue Reading',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: isDarkTheme ? Colors.white : const Color(0xFF1a1a2e),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ...recentlyRead
              .take(3)
              .map((progress) => Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => SurahReaderScreen(
                                surahNumber: progress.surahNumber,
                                surahName: progress.surahName,
                                highlightAyah: progress.lastReadAyah,
                              ),
                            ),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: isDarkTheme
                                  ? [
                                      const Color(0xFF3a3a4e),
                                      const Color(0xFF2e2e3e)
                                    ]
                                  : [Colors.white, const Color(0xFFf8f9fa)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isDarkTheme
                                  ? Colors.white.withValues(alpha: 0.1)
                                  : Colors.grey.withValues(alpha: 0.2),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 50,
                                height: 50,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      const Color(0xFF667eea),
                                      const Color(0xFF764ba2)
                                    ],
                                  ),
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFF667eea)
                                          .withValues(alpha: 0.3),
                                      blurRadius: 8,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Center(
                                  child: Text(
                                    progress.surahNumber.toString(),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      progress.surahName,
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 17,
                                        color: isDarkTheme
                                            ? Colors.white
                                            : const Color(0xFF1a1a2e),
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      'Ayah ${progress.lastReadAyah} of ${progress.totalAyahs}',
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: isDarkTheme
                                            ? Colors.white70
                                            : Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Column(
                                children: [
                                  Text(
                                    '${progress.progressPercentage.toStringAsFixed(0)}%',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                      color: isDarkTheme
                                          ? Colors.white
                                          : const Color(0xFF667eea),
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Container(
                                    width: 60,
                                    height: 4,
                                    decoration: BoxDecoration(
                                      color: isDarkTheme
                                          ? Colors.grey[700]
                                          : Colors.grey[300],
                                      borderRadius: BorderRadius.circular(2),
                                    ),
                                    child: FractionallySizedBox(
                                      alignment: Alignment.centerLeft,
                                      widthFactor:
                                          progress.progressPercentage / 100,
                                      child: Container(
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            colors: [
                                              const Color(0xFF667eea),
                                              const Color(0xFF764ba2)
                                            ],
                                          ),
                                          borderRadius:
                                              BorderRadius.circular(2),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ))
              .toList(),
        ],
      ),
    );
  }
}
