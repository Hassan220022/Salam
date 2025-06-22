import 'package:http/http.dart' as http;
import 'dart:convert';
import '../data/models/translation.dart';
import '../data/models/tafsir.dart';
import '../domain/repositories/quran_repository_interface.dart';
import '../domain/entities/surah_entity.dart';
import 'package:flutter/foundation.dart';

class QuranService {
  static const String baseUrl = 'http://api.alquran.cloud/v1';
  final QuranRepositoryInterface? _repository;

  QuranService({QuranRepositoryInterface? repository})
      : _repository = repository;

  Future<TranslationSet> getTranslations(
      int surahNumber, List<String> editions) async {
    try {
      final editionsParam = editions.join(',');
      final url = '$baseUrl/surah/$surahNumber/editions/$editionsParam';

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['status'] == 'OK') {
          List<Translation> translations = [];

          // Handle multiple editions
          if (data['data'] is List) {
            for (var editionData in data['data']) {
              if (editionData['ayahs'] != null) {
                for (var ayah in editionData['ayahs']) {
                  translations.add(Translation.fromJson(
                      {...ayah, 'edition': editionData['edition']}));
                }
              }
            }
          }

          return TranslationSet(
            translations: translations,
            surahName: data['data'][0]['englishName'] ?? '',
            surahNumber: surahNumber,
          );
        }
      }

      throw Exception('Failed to load translations');
    } catch (e) {
      throw Exception('Error fetching translations: $e');
    }
  }

  Future<TafsirSet> getTafsir(int surahNumber, String edition) async {
    try {
      if (kDebugMode) {
        debugPrint(
            '🔍 Loading tafsir for surah $surahNumber with edition: $edition');
      }

      final url = '$baseUrl/surah/$surahNumber/$edition';

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['status'] == 'OK' && data['data'] != null) {
          List<Tafsir> tafasir = [];

          if (data['data']['ayahs'] != null) {
            for (var ayah in data['data']['ayahs']) {
              // Only add tafsir if the text is meaningful and different from Quran
              String ayahText = ayah['text']?.toString() ?? '';

              // Skip if the text is empty or just numbers/symbols
              if (ayahText.isNotEmpty && ayahText.length > 10) {
                tafasir.add(Tafsir.fromJson({
                  'ayahNumber': ayah['numberInSurah'],
                  'text': ayahText,
                  'edition': data['data']['edition']
                }));
              }
            }
          }

          if (kDebugMode) {
            debugPrint(
                '✅ Loaded ${tafasir.length} tafsir entries for surah $surahNumber');
          }

          return TafsirSet(
            tafasir: tafasir,
            surahName: data['data']['englishName'] ?? 'Surah $surahNumber',
            surahNumber: surahNumber,
          );
        } else {
          if (kDebugMode) {
            debugPrint('⚠️ API returned OK but no valid data for tafsir');
          }
        }
      } else {
        if (kDebugMode) {
          debugPrint('❌ HTTP ${response.statusCode} for tafsir request');
        }
      }

      // Return empty tafsir set instead of throwing error
      return TafsirSet(
        tafasir: [],
        surahName: 'Surah $surahNumber',
        surahNumber: surahNumber,
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error fetching tafsir: $e');
      }

      // Return empty tafsir set to prevent UI crash
      return TafsirSet(
        tafasir: [],
        surahName: 'Surah $surahNumber',
        surahNumber: surahNumber,
      );
    }
  }

  Future<Map<String, dynamic>> getSurahInfo(int surahNumber) async {
    try {
      final url = '$baseUrl/surah/$surahNumber';

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['status'] == 'OK') {
          return {
            'name': data['data']['name'],
            'englishName': data['data']['englishName'],
            'numberOfAyahs': data['data']['numberOfAyahs'],
            'revelationType': data['data']['revelationType'],
          };
        }
      }

      throw Exception('Failed to load surah info');
    } catch (e) {
      throw Exception('Error fetching surah info: $e');
    }
  }

  // Repository-enhanced methods using clean architecture
  Future<List<Map<String, dynamic>>> getSurahs() async {
    if (_repository != null) {
      final result = await _repository!.getAllSurahs();
      if (result is Success<List<Surah>>) {
        return result.data
            .map((surah) => {
                  'number': surah.number,
                  'name': surah.name,
                  'englishName': surah.englishName,
                  'englishNameTranslation': surah.englishNameTranslation,
                  'revelationType': surah.revelationType,
                  'numberOfAyahs': surah.numberOfAyahs,
                })
            .toList();
      }
    }

    // Fallback to direct API call
    return await getSurahsFromAPI();
  }

  Future<Map<String, dynamic>> getSurah(int surahNumber) async {
    if (_repository != null) {
      final result = await _repository!.getSurah(surahNumber);
      if (result is Success<Surah>) {
        final surah = result.data;
        return {
          'number': surah.number,
          'name': surah.name,
          'englishName': surah.englishName,
          'englishNameTranslation': surah.englishNameTranslation,
          'revelationType': surah.revelationType,
          'numberOfAyahs': surah.numberOfAyahs,
          'ayahs': surah.verses
              .map((verse) => {
                    'numberInSurah': verse.number,
                    'text': verse.arabicText,
                  })
              .toList(),
        };
      }
    }

    // Fallback to direct API call
    return await getSurahFromAPI(surahNumber);
  }

  // Audio URL generation (no caching in new architecture)
  String? getAudioUrl(int surahNumber, int ayahNumber, String reciterKey) {
    // Generate audio URL based on reciter and ayah numbers
    String surahStr = surahNumber.toString().padLeft(3, '0');
    String ayahStr = ayahNumber.toString().padLeft(3, '0');

    // Default reciter URL pattern
    return 'https://everyayah.com/data/AbdulSamad_64kbps_QuranExplorer.Com/$surahStr$ayahStr.mp3';
  }

  // Static methods for direct API access (backward compatibility)
  static Future<List<Map<String, dynamic>>> getSurahsFromAPI() async {
    try {
      final response =
          await http.get(Uri.parse('$baseUrl/quran/quran-uthmani'));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'OK') {
          return List<Map<String, dynamic>>.from(data['data']['surahs']);
        }
      }
      throw Exception('Failed to load surahs');
    } catch (e) {
      throw Exception('Error fetching surahs: $e');
    }
  }

  static Future<Map<String, dynamic>> getSurahFromAPI(int surahNumber) async {
    try {
      final response = await http
          .get(Uri.parse('$baseUrl/surah/$surahNumber/quran-uthmani'));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'OK') {
          return data['data'];
        }
      }
      throw Exception('Failed to load surah');
    } catch (e) {
      throw Exception('Error fetching surah: $e');
    }
  }
}
