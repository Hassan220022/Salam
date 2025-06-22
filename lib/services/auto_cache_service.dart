import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class AutoCacheService {
  static const String _baseUrl = 'http://api.alquran.cloud/v1';

  // Cache keys
  static const String _surahListKey = 'cached_surah_list';
  static const String _surahPrefix = 'cached_surah_';

  // Get all Surahs with automatic caching (permanent storage)
  static Future<List<Map<String, dynamic>>> getSurahs() async {
    final prefs = await SharedPreferences.getInstance();
    final cacheKey = _surahListKey;

    // Check if cache exists (permanent until manually removed)
    final cachedData = prefs.getString(cacheKey);

    if (cachedData != null) {
      // Return cached data
      final List<dynamic> cached = json.decode(cachedData);
      return List<Map<String, dynamic>>.from(cached);
    }

    // Fetch from API only if not cached
    try {
      final response =
          await http.get(Uri.parse('$_baseUrl/quran/quran-uthmani'));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'OK') {
          final List<dynamic> surahs = data['data']['surahs'];

          // Cache the data permanently
          await prefs.setString(cacheKey, json.encode(surahs));

          return List<Map<String, dynamic>>.from(surahs);
        }
      }

      throw Exception('Failed to load surahs');
    } catch (e) {
      throw Exception('Error fetching surahs: $e');
    }
  }

  // Get specific Surah with automatic caching (permanent storage)
  static Future<Map<String, dynamic>> getSurah(int surahNumber) async {
    final prefs = await SharedPreferences.getInstance();
    final cacheKey = '$_surahPrefix$surahNumber';

    // Check if cache exists (permanent until manually removed)
    final cachedData = prefs.getString(cacheKey);

    if (cachedData != null) {
      // Return cached data
      return Map<String, dynamic>.from(json.decode(cachedData));
    }

    // Fetch from API only if not cached
    try {
      final response = await http
          .get(Uri.parse('$_baseUrl/surah/$surahNumber/quran-uthmani'));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'OK') {
          final surahData = data['data'];

          // Cache the data permanently
          await prefs.setString(cacheKey, json.encode(surahData));

          return Map<String, dynamic>.from(surahData);
        }
      }

      throw Exception('Failed to load surah');
    } catch (e) {
      throw Exception('Error fetching surah: $e');
    }
  }

  // Get cache information
  static Future<Map<String, dynamic>> getCacheInfo() async {
    final prefs = await SharedPreferences.getInstance();
    int cachedSurahs = 0;
    int totalCacheSize = 0;

    // Count cached surahs
    for (int i = 1; i <= 114; i++) {
      if (prefs.containsKey('$_surahPrefix$i')) {
        cachedSurahs++;
        final data = prefs.getString('$_surahPrefix$i');
        if (data != null) {
          totalCacheSize += data.length;
        }
      }
    }

    // Check if surah list is cached
    bool hasSurahList = prefs.containsKey(_surahListKey);
    if (hasSurahList) {
      final data = prefs.getString(_surahListKey);
      if (data != null) {
        totalCacheSize += data.length;
      }
    }

    return {
      'cached_surahs': cachedSurahs,
      'has_surah_list': hasSurahList,
      'cache_size_kb': (totalCacheSize / 1024).toStringAsFixed(2),
      'offline_status': cachedSurahs > 0
          ? 'Permanent offline content ($cachedSurahs/114 surahs)'
          : 'No offline content',
    };
  }

  // Clear all cache
  static Future<void> clearAllCache() async {
    final prefs = await SharedPreferences.getInstance();

    // Remove surah list cache
    await prefs.remove(_surahListKey);

    // Remove individual surah caches
    for (int i = 1; i <= 114; i++) {
      await prefs.remove('$_surahPrefix$i');
    }
  }

  // Check if offline content is available
  static Future<bool> hasOfflineContent() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey(_surahListKey);
  }

  // Check if specific surah is cached
  static Future<bool> isSurahCached(int surahNumber) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey('$_surahPrefix$surahNumber');
  }

  // Get list of all cached surah numbers
  static Future<List<int>> getCachedSurahNumbers() async {
    final prefs = await SharedPreferences.getInstance();
    List<int> cachedNumbers = [];

    for (int i = 1; i <= 114; i++) {
      if (prefs.containsKey('$_surahPrefix$i')) {
        cachedNumbers.add(i);
      }
    }

    return cachedNumbers;
  }

  // Preload popular surahs for offline access
  static Future<void> preloadPopularSurahs() async {
    final popularSurahs = [
      1,
      2,
      18,
      36,
      55,
      67,
      112,
      113,
      114
    ]; // Common surahs

    for (int surahNumber in popularSurahs) {
      try {
        await getSurah(surahNumber);
        // Small delay to avoid overwhelming the API
        await Future.delayed(const Duration(milliseconds: 500));
      } catch (e) {
        // Continue with next surah if one fails
        continue;
      }
    }
  }

  // Cache all 114 surahs for complete offline access
  static Future<void> cacheAllSurahs({Function(int, int)? onProgress}) async {
    for (int surahNumber = 1; surahNumber <= 114; surahNumber++) {
      try {
        await getSurah(surahNumber);

        // Call progress callback if provided
        onProgress?.call(surahNumber, 114);

        // Small delay to avoid overwhelming the API
        await Future.delayed(const Duration(milliseconds: 300));
      } catch (e) {
        // Continue with next surah if one fails
        continue;
      }
    }
  }

  // Cache specific range of surahs
  static Future<void> cacheSurahRange(int startSurah, int endSurah,
      {Function(int, int)? onProgress}) async {
    final totalSurahs = endSurah - startSurah + 1;
    int currentIndex = 0;

    for (int surahNumber = startSurah; surahNumber <= endSurah; surahNumber++) {
      try {
        await getSurah(surahNumber);
        currentIndex++;

        // Call progress callback if provided
        onProgress?.call(currentIndex, totalSurahs);

        // Small delay to avoid overwhelming the API
        await Future.delayed(const Duration(milliseconds: 300));
      } catch (e) {
        // Continue with next surah if one fails
        currentIndex++;
        continue;
      }
    }
  }

  // Cache the most commonly read surahs (more than just 9)
  static Future<void> cacheCommonSurahs(
      {Function(int, int)? onProgress}) async {
    final commonSurahs = [
      1, // Al-Fatiha
      2, // Al-Baqarah
      3, // Ali 'Imran
      4, // An-Nisa
      18, // Al-Kahf
      24, // An-Nur
      36, // Ya-Sin
      55, // Ar-Rahman
      56, // Al-Waqi'ah
      67, // Al-Mulk
      78, // An-Naba
      112, // Al-Ikhlas
      113, // Al-Falaq
      114, // An-Nas
    ];

    for (int i = 0; i < commonSurahs.length; i++) {
      try {
        await getSurah(commonSurahs[i]);

        // Call progress callback if provided
        onProgress?.call(i + 1, commonSurahs.length);

        // Small delay to avoid overwhelming the API
        await Future.delayed(const Duration(milliseconds: 400));
      } catch (e) {
        // Continue with next surah if one fails
        continue;
      }
    }
  }
}
