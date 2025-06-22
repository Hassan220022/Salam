import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../core/constants/app_constants.dart';
import '../../core/errors/failures.dart';

/// Remote data source for Quran API operations
/// Handles all external API calls for Quran data
class QuranRemoteDataSource {
  final http.Client client;

  const QuranRemoteDataSource({required this.client});

  // ========================= SURAH OPERATIONS =========================

  /// Fetch all surahs metadata from API (using /surah endpoint per API docs)
  Future<List<Map<String, dynamic>>> getAllSurahs() async {
    try {
      final response = await client.get(
        Uri.parse('${AppConstants.quranApiBaseUrl}/surah'),
        headers: {'Accept': 'application/json'},
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'OK' && data['data'] != null) {
          return List<Map<String, dynamic>>.from(data['data']);
        } else {
          throw ServerFailure(
            message: 'Invalid API response format',
            code: response.statusCode,
          );
        }
      } else {
        throw ServerFailure(
          message: 'Failed to fetch surahs: ${response.reasonPhrase}',
          code: response.statusCode,
        );
      }
    } on TimeoutException {
      throw const TimeoutFailure();
    } on http.ClientException catch (e) {
      throw NetworkFailure(message: 'Network error: ${e.message}');
    } catch (e) {
      if (e is Failure) rethrow;
      throw ServerFailure(message: 'Unexpected error: $e');
    }
  }

  /// Fetch specific surah with verses from API (per official API docs)
  Future<Map<String, dynamic>> getSurah(int surahNumber) async {
    try {
      final response = await client.get(
        Uri.parse('${AppConstants.quranApiBaseUrl}/surah/$surahNumber'),
        headers: {'Accept': 'application/json'},
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['status'] == 'OK' && data['data'] != null) {
          final surahData = data['data'];

          // Validate that we have the required structure
          if (surahData['ayahs'] == null || surahData['ayahs'].isEmpty) {
            throw ServerFailure(
              message: 'Surah $surahNumber returned without verses',
              code: 422,
            );
          }

          return surahData;
        } else {
          throw ServerFailure(
            message: 'Invalid API response format for surah $surahNumber',
            code: response.statusCode,
          );
        }
      } else if (response.statusCode == 404) {
        throw SurahNotFoundFailure(surahNumber: surahNumber);
      } else {
        throw ServerFailure(
          message:
              'Failed to fetch surah $surahNumber: ${response.reasonPhrase}',
          code: response.statusCode,
        );
      }
    } on TimeoutException {
      throw const TimeoutFailure();
    } on http.ClientException catch (e) {
      throw NetworkFailure(message: 'Network error: ${e.message}');
    } catch (e) {
      if (e is Failure) rethrow;
      throw ServerFailure(message: 'Unexpected error: $e');
    }
  }

  /// Fetch specific verse from API
  Future<Map<String, dynamic>> getVerse(
      int surahNumber, int verseNumber) async {
    try {
      final response = await client.get(
        Uri.parse(
            '${AppConstants.quranApiBaseUrl}/surah/$surahNumber/$verseNumber'),
        headers: {'Accept': 'application/json'},
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'OK' && data['data'] != null) {
          return data['data'];
        } else {
          throw ServerFailure(
            message:
                'Invalid API response format for verse $surahNumber:$verseNumber',
            code: response.statusCode,
          );
        }
      } else if (response.statusCode == 404) {
        throw VerseNotFoundFailure(
          surahNumber: surahNumber,
          verseNumber: verseNumber,
        );
      } else {
        throw ServerFailure(
          message:
              'Failed to fetch verse $surahNumber:$verseNumber: ${response.reasonPhrase}',
          code: response.statusCode,
        );
      }
    } on TimeoutException {
      throw const TimeoutFailure();
    } on http.ClientException catch (e) {
      throw NetworkFailure(message: 'Network error: ${e.message}');
    } catch (e) {
      if (e is Failure) rethrow;
      throw ServerFailure(message: 'Unexpected error: $e');
    }
  }

  // ========================= TRANSLATION OPERATIONS =========================

  /// Fetch available translations from API
  Future<List<Map<String, dynamic>>> getAvailableTranslations() async {
    try {
      final response = await client.get(
        Uri.parse('${AppConstants.quranApiBaseUrl}/edition/format/translation'),
        headers: {'Accept': 'application/json'},
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'OK' && data['data'] != null) {
          return List<Map<String, dynamic>>.from(data['data']);
        } else {
          throw ServerFailure(
            message: 'Invalid API response format for translations',
            code: response.statusCode,
          );
        }
      } else {
        throw ServerFailure(
          message: 'Failed to fetch translations: ${response.reasonPhrase}',
          code: response.statusCode,
        );
      }
    } on TimeoutException {
      throw const TimeoutFailure();
    } on http.ClientException catch (e) {
      throw NetworkFailure(message: 'Network error: ${e.message}');
    } catch (e) {
      if (e is Failure) rethrow;
      throw ServerFailure(message: 'Unexpected error: $e');
    }
  }

  /// Fetch surah with specific translation
  Future<Map<String, dynamic>> getSurahWithTranslation(
    int surahNumber,
    String translationKey,
  ) async {
    try {
      final response = await client.get(
        Uri.parse(
            '${AppConstants.quranApiBaseUrl}/surah/$surahNumber/$translationKey'),
        headers: {'Accept': 'application/json'},
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'OK' && data['data'] != null) {
          return data['data'];
        } else {
          throw ServerFailure(
            message: 'Invalid API response format for translation',
            code: response.statusCode,
          );
        }
      } else if (response.statusCode == 404) {
        throw TranslationNotFoundFailure(translationKey: translationKey);
      } else {
        throw ServerFailure(
          message: 'Failed to fetch translation: ${response.reasonPhrase}',
          code: response.statusCode,
        );
      }
    } on TimeoutException {
      throw const TimeoutFailure();
    } on http.ClientException catch (e) {
      throw NetworkFailure(message: 'Network error: ${e.message}');
    } catch (e) {
      if (e is Failure) rethrow;
      throw ServerFailure(message: 'Unexpected error: $e');
    }
  }

  // ========================= SEARCH OPERATIONS =========================

  /// Search for verses containing specific text
  Future<List<Map<String, dynamic>>> searchVerses(String query,
      {String? translation}) async {
    try {
      String endpoint = '${AppConstants.quranApiBaseUrl}/search/$query/all';
      if (translation != null) {
        endpoint += '/$translation';
      }

      final response = await client.get(
        Uri.parse(endpoint),
        headers: {'Accept': 'application/json'},
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'OK' && data['data'] != null) {
          return List<Map<String, dynamic>>.from(data['data']['matches']);
        } else {
          throw ServerFailure(
            message: 'Invalid API response format for search',
            code: response.statusCode,
          );
        }
      } else {
        throw ServerFailure(
          message: 'Search failed: ${response.reasonPhrase}',
          code: response.statusCode,
        );
      }
    } on TimeoutException {
      throw const TimeoutFailure();
    } on http.ClientException catch (e) {
      throw NetworkFailure(message: 'Network error: ${e.message}');
    } catch (e) {
      if (e is Failure) rethrow;
      throw ServerFailure(message: 'Unexpected error: $e');
    }
  }

  // ========================= AUDIO OPERATIONS =========================

  /// Get audio URL for specific verse
  String getVerseAudioUrl(int surahNumber, int verseNumber, String reciterKey) {
    final paddedSurah = surahNumber.toString().padLeft(3, '0');
    final paddedVerse = verseNumber.toString().padLeft(3, '0');
    return '${AppConstants.audioBaseUrl}/$reciterKey/$paddedSurah$paddedVerse.mp3';
  }

  /// Get audio URL for entire surah
  String getSurahAudioUrl(int surahNumber, String reciterKey) {
    final paddedSurah = surahNumber.toString().padLeft(3, '0');
    return '${AppConstants.audioBaseUrl}/$reciterKey/$paddedSurah.mp3';
  }

  /// Fetch available reciters from API
  Future<List<Map<String, dynamic>>> getAvailableReciters() async {
    try {
      final response = await client.get(
        Uri.parse('${AppConstants.quranApiBaseUrl}/edition/format/audio'),
        headers: {'Accept': 'application/json'},
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'OK' && data['data'] != null) {
          return List<Map<String, dynamic>>.from(data['data']);
        } else {
          throw ServerFailure(
            message: 'Invalid API response format for reciters',
            code: response.statusCode,
          );
        }
      } else {
        throw ServerFailure(
          message: 'Failed to fetch reciters: ${response.reasonPhrase}',
          code: response.statusCode,
        );
      }
    } on TimeoutException {
      throw const TimeoutFailure();
    } on http.ClientException catch (e) {
      throw NetworkFailure(message: 'Network error: ${e.message}');
    } catch (e) {
      if (e is Failure) rethrow;
      throw ServerFailure(message: 'Unexpected error: $e');
    }
  }

  // ========================= VALIDATION HELPERS =========================

//   /// Validate API response structure
//   bool _isValidResponse(Map<String, dynamic> data) {
//     return data.containsKey('status') &&
//         data['status'] == 'OK' &&
//         data.containsKey('data');
//   }

//   /// Extract error message from API response
//   String _extractErrorMessage(Map<String, dynamic> data) {
//     if (data.containsKey('message')) {
//       return data['message'];
//     }
//     return 'Unknown API error';
//   }
}
