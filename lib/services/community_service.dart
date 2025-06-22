import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:math' as math;

class CommunityService {
  /// Share an ayah with social media integration
  static Future<void> shareAyah({
    required String ayahText,
    required String ayahTranslation,
    required String surahName,
    required int surahNumber,
    required int ayahNumber,
    String? customMessage,
  }) async {
    final message = _formatAyahForSharing(
      ayahText: ayahText,
      ayahTranslation: ayahTranslation,
      surahName: surahName,
      surahNumber: surahNumber,
      ayahNumber: ayahNumber,
      customMessage: customMessage,
    );

    await Share.share(
      message,
      subject: 'Ayah from Surah $surahName',
    );

    // Track sharing activity
    await _trackSharingActivity(surahNumber, ayahNumber);
  }

  /// Format ayah text for sharing
  static String _formatAyahForSharing({
    required String ayahText,
    required String ayahTranslation,
    required String surahName,
    required int surahNumber,
    required int ayahNumber,
    String? customMessage,
  }) {
    final buffer = StringBuffer();

    if (customMessage != null && customMessage.isNotEmpty) {
      buffer.writeln(customMessage);
      buffer.writeln();
    }

    // Arabic text
    buffer.writeln('🌙 $ayahText');
    buffer.writeln();

    // Translation
    buffer.writeln('📖 $ayahTranslation');
    buffer.writeln();

    // Reference
    buffer.writeln('— Quran $surahNumber:$ayahNumber (Surah $surahName)');
    buffer.writeln();

    // App attribution
    buffer.writeln('Shared from Quran Mobile App 📱');

    return buffer.toString();
  }

  /// Share on specific social media platforms
  static Future<void> shareOnPlatform({
    required String platform,
    required String ayahText,
    required String ayahTranslation,
    required String surahName,
    required int surahNumber,
    required int ayahNumber,
  }) async {
    final message = _formatAyahForSharing(
      ayahText: ayahText,
      ayahTranslation: ayahTranslation,
      surahName: surahName,
      surahNumber: surahNumber,
      ayahNumber: ayahNumber,
    );

    final encodedMessage = Uri.encodeComponent(message);
    String url;

    switch (platform.toLowerCase()) {
      case 'twitter':
        url = 'https://twitter.com/intent/tweet?text=$encodedMessage';
        break;
      case 'facebook':
        url =
            'https://www.facebook.com/sharer/sharer.php?quote=$encodedMessage';
        break;
      case 'whatsapp':
        url = 'https://wa.me/?text=$encodedMessage';
        break;
      case 'telegram':
        url = 'https://t.me/share/url?text=$encodedMessage';
        break;
      default:
        await Share.share(message);
        return;
    }

    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } else {
      await Share.share(message);
    }

    await _trackSharingActivity(surahNumber, ayahNumber);
  }

  /// Track sharing activity for statistics
  static Future<void> _trackSharingActivity(
      int surahNumber, int ayahNumber) async {
    final prefs = await SharedPreferences.getInstance();

    // Update total shares count
    final totalShares = prefs.getInt('total_shares') ?? 0;
    await prefs.setInt('total_shares', totalShares + 1);

    // Track shares by surah
    final surahSharesKey = 'surah_${surahNumber}_shares';
    final surahShares = prefs.getInt(surahSharesKey) ?? 0;
    await prefs.setInt(surahSharesKey, surahShares + 1);

    // Track most shared ayahs
    final ayahKey = '${surahNumber}_$ayahNumber';
    final mostSharedJson = prefs.getString('most_shared_ayahs') ?? '{}';
    final mostShared = Map<String, int>.from(json.decode(mostSharedJson));
    mostShared[ayahKey] = (mostShared[ayahKey] ?? 0) + 1;
    await prefs.setString('most_shared_ayahs', json.encode(mostShared));

    // Update last share date
    await prefs.setString('last_share_date', DateTime.now().toIso8601String());
  }

  /// Get daily Ayah for notifications
  static Map<String, dynamic> getDailyAyah() {
    final now = DateTime.now();
    final dayOfYear = now.difference(DateTime(now.year, 1, 1)).inDays;

    // Rotate through a curated list of inspirational ayahs
    final dailyAyahs = [
      {
        'arabic': 'وَمَن يَتَّقِ اللَّهَ يَجْعَل لَّهُ مَخْرَجًا',
        'translation':
            'And whoever fears Allah - He will make for him a way out.',
        'surah': 'At-Talaq',
        'surahNumber': 65,
        'ayahNumber': 2,
      },
      {
        'arabic': 'وَلَا تَيْأَسُوا مِن رَّوْحِ اللَّهِ',
        'translation': 'And do not despair of relief from Allah.',
        'surah': 'Yusuf',
        'surahNumber': 12,
        'ayahNumber': 87,
      },
      {
        'arabic': 'فَإِنَّ مَعَ الْعُسْرِ يُسْرًا',
        'translation': 'Indeed, with hardship comes ease.',
        'surah': 'Ash-Sharh',
        'surahNumber': 94,
        'ayahNumber': 6,
      },
      {
        'arabic': 'وَبَشِّرِ الصَّابِرِينَ',
        'translation': 'And give good tidings to the patient.',
        'surah': 'Al-Baqarah',
        'surahNumber': 2,
        'ayahNumber': 155,
      },
      {
        'arabic': 'وَهُوَ مَعَكُمْ أَيْنَ مَا كُنتُمْ',
        'translation': 'And He is with you wherever you are.',
        'surah': 'Al-Hadid',
        'surahNumber': 57,
        'ayahNumber': 4,
      },
    ];

    return dailyAyahs[dayOfYear % dailyAyahs.length];
  }

  /// Get reading statistics
  static Future<Map<String, dynamic>> getReadingStatistics() async {
    final prefs = await SharedPreferences.getInstance();

    // Get reading streak
    final streakData = await _calculateReadingStreak();

    // Get sharing statistics
    final totalShares = prefs.getInt('total_shares') ?? 0;
    final mostSharedJson = prefs.getString('most_shared_ayahs') ?? '{}';
    final mostShared = Map<String, int>.from(json.decode(mostSharedJson));

    // Get most read surahs
    final readingSessions = prefs.getStringList('reading_sessions') ?? [];
    final surahReadCount = <String, int>{};

    for (final session in readingSessions) {
      try {
        final sessionData = json.decode(session);
        final surahNumber = sessionData['surah_number'].toString();
        surahReadCount[surahNumber] = (surahReadCount[surahNumber] ?? 0) + 1;
      } catch (e) {
        // Skip invalid session data
      }
    }

    return {
      'currentStreak': streakData['currentStreak'],
      'longestStreak': streakData['longestStreak'],
      'totalReadingSessions': readingSessions.length,
      'totalShares': totalShares,
      'mostSharedAyahs': _formatMostSharedAyahs(mostShared),
      'mostReadSurahs': _formatMostReadSurahs(surahReadCount),
      'weeklyProgress': await _getWeeklyProgress(),
      'monthlyProgress': await _getMonthlyProgress(),
    };
  }

  /// Calculate reading streak
  static Future<Map<String, int>> _calculateReadingStreak() async {
    final prefs = await SharedPreferences.getInstance();
    final readingDates = prefs.getStringList('reading_dates') ?? [];

    if (readingDates.isEmpty) {
      return {'currentStreak': 0, 'longestStreak': 0};
    }

    final dates =
        readingDates.map((dateStr) => DateTime.parse(dateStr)).toList()..sort();

    int currentStreak = 0;
    int longestStreak = 0;
    int tempStreak = 1;

    final today = DateTime.now();

    // Check if read today or yesterday for current streak
    final lastReadDate = dates.last;
    final daysDifference = today.difference(lastReadDate).inDays;

    if (daysDifference <= 1) {
      currentStreak = 1;

      // Calculate backwards from last read date
      for (int i = dates.length - 2; i >= 0; i--) {
        final diff = dates[i + 1].difference(dates[i]).inDays;
        if (diff == 1) {
          currentStreak++;
        } else {
          break;
        }
      }
    }

    // Calculate longest streak
    for (int i = 1; i < dates.length; i++) {
      final diff = dates[i].difference(dates[i - 1]).inDays;
      if (diff == 1) {
        tempStreak++;
      } else {
        longestStreak = math.max(longestStreak, tempStreak);
        tempStreak = 1;
      }
    }
    longestStreak = math.max(longestStreak, tempStreak);

    return {'currentStreak': currentStreak, 'longestStreak': longestStreak};
  }

  /// Record reading session
  static Future<void> recordReadingSession({
    required int surahNumber,
    required int startAyah,
    required int endAyah,
    required Duration readingTime,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    final today = DateTime.now();
    final dateStr =
        '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

    // Add to reading dates for streak calculation
    final readingDates = prefs.getStringList('reading_dates') ?? [];
    if (!readingDates.contains(dateStr)) {
      readingDates.add(dateStr);
      await prefs.setStringList('reading_dates', readingDates);
    }

    // Add to reading sessions
    final readingSessions = prefs.getStringList('reading_sessions') ?? [];
    final sessionData = {
      'date': today.toIso8601String(),
      'surah_number': surahNumber,
      'start_ayah': startAyah,
      'end_ayah': endAyah,
      'reading_time_seconds': readingTime.inSeconds,
    };

    readingSessions.add(json.encode(sessionData));
    await prefs.setStringList('reading_sessions', readingSessions);

    // Update total reading time
    final totalReadingTime = prefs.getInt('total_reading_time_seconds') ?? 0;
    await prefs.setInt(
        'total_reading_time_seconds', totalReadingTime + readingTime.inSeconds);
  }

  /// Format most shared ayahs for display
  static List<Map<String, dynamic>> _formatMostSharedAyahs(
      Map<String, int> mostShared) {
    final sorted = mostShared.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return sorted.take(5).map((entry) {
      final parts = entry.key.split('_');
      return {
        'surahNumber': int.parse(parts[0]),
        'ayahNumber': int.parse(parts[1]),
        'shareCount': entry.value,
      };
    }).toList();
  }

  /// Format most read surahs for display
  static List<Map<String, dynamic>> _formatMostReadSurahs(
      Map<String, int> surahReadCount) {
    final sorted = surahReadCount.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return sorted
        .take(5)
        .map((entry) => {
              'surahNumber': int.parse(entry.key),
              'readCount': entry.value,
            })
        .toList();
  }

  /// Get weekly reading progress
  static Future<List<int>> _getWeeklyProgress() async {
    final prefs = await SharedPreferences.getInstance();
    final readingSessions = prefs.getStringList('reading_sessions') ?? [];

    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    final weekProgress = List.filled(7, 0);

    for (final session in readingSessions) {
      try {
        final sessionData = json.decode(session);
        final sessionDate = DateTime.parse(sessionData['date']);

        if (sessionDate.isAfter(weekStart.subtract(const Duration(days: 1)))) {
          final dayIndex = sessionDate.difference(weekStart).inDays;
          if (dayIndex >= 0 && dayIndex < 7) {
            weekProgress[dayIndex]++;
          }
        }
      } catch (e) {
        // Skip invalid session data
      }
    }

    return weekProgress;
  }

  /// Get monthly reading progress
  static Future<List<int>> _getMonthlyProgress() async {
    final prefs = await SharedPreferences.getInstance();
    final readingSessions = prefs.getStringList('reading_sessions') ?? [];

    final now = DateTime.now();
    final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
    final monthProgress = List.filled(daysInMonth, 0);

    for (final session in readingSessions) {
      try {
        final sessionData = json.decode(session);
        final sessionDate = DateTime.parse(sessionData['date']);

        if (sessionDate.month == now.month && sessionDate.year == now.year) {
          final dayIndex = sessionDate.day - 1;
          if (dayIndex >= 0 && dayIndex < daysInMonth) {
            monthProgress[dayIndex]++;
          }
        }
      } catch (e) {
        // Skip invalid session data
      }
    }

    return monthProgress;
  }
}
 