import 'package:hive/hive.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
// import 'package:path_provider/path_provider.dart';
// import 'dart:io';
import '../../core/errors/failures.dart';
import '../../domain/entities/surah_entity.dart';
import '../../domain/repositories/quran_repository_interface.dart';
import '../datasources/quran_remote_datasource.dart';
import '../models/cached_surah.dart';
import '../models/bookmark.dart';
import '../models/reading_progress.dart' as data_models;
import 'package:flutter/foundation.dart';

/// Implementation of QuranRepositoryInterface following clean architecture
/// Handles data persistence, caching, and coordination between local and remote sources
class QuranRepository implements QuranRepositoryInterface {
  final QuranRemoteDataSource remoteDataSource;
  final Connectivity connectivity;

  // Hive boxes for local storage
  late Box<CachedSurah> _surahBox;
  late Box<Bookmark> _bookmarkBox;
  late Box<data_models.ReadingProgress> _progressBox;

  QuranRepository({
    required this.remoteDataSource,
    required this.connectivity,
  });

  /// Initialize local storage boxes
  Future<void> initialize() async {
    try {
      _surahBox = await Hive.openBox<CachedSurah>('surahs');
      _bookmarkBox = await Hive.openBox<Bookmark>('bookmarks');
      _progressBox =
          await Hive.openBox<data_models.ReadingProgress>('reading_progress');
    } catch (e) {
      throw StorageFailure(message: 'Failed to initialize storage: $e');
    }
  }

  /// Check if device has internet connection
  Future<bool> get _hasInternetConnection async {
    try {
      final result = await connectivity.checkConnectivity();
      return result != ConnectivityResult.none;
    } catch (e) {
      return false;
    }
  }

  // ========================= SURAH OPERATIONS =========================

  @override
  Future<Result<List<Surah>>> getAllSurahs() async {
    try {
      // Check cache first
      final cachedSurahs = _surahBox.values.toList();
      if (cachedSurahs.isNotEmpty && !cachedSurahs.first.isExpired) {
        final surahs = cachedSurahs.map(_convertCachedSurahToEntity).toList();
        return Success(surahs);
      }

      // Check internet connection
      if (!await _hasInternetConnection) {
        if (cachedSurahs.isNotEmpty) {
          // Return expired cache if no internet
          final surahs = cachedSurahs.map(_convertCachedSurahToEntity).toList();
          return Success(surahs);
        }
        return ResultError(const NetworkFailure(
            message: 'No internet connection and no cached data'));
      }

      // Fetch from remote
      final surahsData = await remoteDataSource.getAllSurahs();

      // Convert and cache
      final surahs = <Surah>[];
      await _surahBox.clear();

      for (final surahData in surahsData) {
        final surah = _convertApiDataToSurah(surahData);
        surahs.add(surah);

        // Cache the surah
        final cachedSurah = _convertSurahToCached(surah);
        await _surahBox.put(surah.number, cachedSurah);
      }

      return Success(surahs);
    } on Failure catch (failure) {
      return ResultError(failure);
    } catch (e) {
      return ResultError(ServerFailure(message: 'Unexpected error: $e'));
    }
  }

  @override
  Future<Result<Surah>> getSurah(int surahNumber) async {
    try {
      // Check cache first, but only use it if it has verses
      final cached = _surahBox.get(surahNumber);
      if (cached != null && !cached.isExpired && cached.ayahs.isNotEmpty) {
        return Success(_convertCachedSurahToEntity(cached));
      }

      // Check internet connection
      if (!await _hasInternetConnection) {
        if (cached != null && cached.ayahs.isNotEmpty) {
          // Return expired cache if no internet but has verses
          return Success(_convertCachedSurahToEntity(cached));
        }
        return ResultError(const NetworkFailure(
            message: 'No internet connection and no complete cached data'));
      }

      // Fetch complete surah with verses from remote
      final surahData = await remoteDataSource.getSurah(surahNumber);
      final surah = _convertApiDataToSurah(surahData);

      // Only cache if we got verses
      if (surah.verses.isNotEmpty) {
        final cachedSurah = _convertSurahToCached(surah);
        await _surahBox.put(surahNumber, cachedSurah);
      }

      return Success(surah);
    } on Failure catch (failure) {
      return ResultError(failure);
    } catch (e) {
      return ResultError(ServerFailure(message: 'Unexpected error: $e'));
    }
  }

  @override
  Future<Result<Verse>> getVerse(int surahNumber, int verseNumber) async {
    return ResultError(const ServerFailure(message: 'Not implemented yet'));
  }

  @override
  Future<Result<List<Verse>>> getVerses(
    int surahNumber, {
    int? startVerse,
    int? endVerse,
  }) async {
    return ResultError(const ServerFailure(message: 'Not implemented yet'));
  }

  // ========================= SEARCH OPERATIONS =========================

  @override
  Future<Result<List<Verse>>> searchArabicText(String query) async {
    return ResultError(const ServerFailure(message: 'Not implemented yet'));
  }

  @override
  Future<Result<List<Verse>>> searchTranslation(
      String query, String translationKey) async {
    return ResultError(const ServerFailure(message: 'Not implemented yet'));
  }

  @override
  Future<Result<List<Surah>>> searchSurahs(String query) async {
    return ResultError(const ServerFailure(message: 'Not implemented yet'));
  }

  // ========================= TRANSLATION OPERATIONS =========================

  @override
  Future<Result<List<TranslationInfo>>> getAvailableTranslations() async {
    return ResultError(const ServerFailure(message: 'Not implemented yet'));
  }

  @override
  Future<Result<String>> getVerseTranslation(
    int surahNumber,
    int verseNumber,
    String translationKey,
  ) async {
    return ResultError(const ServerFailure(message: 'Not implemented yet'));
  }

  @override
  Future<Result<List<String>>> getSurahTranslations(
    int surahNumber,
    String translationKey,
  ) async {
    return ResultError(const ServerFailure(message: 'Not implemented yet'));
  }

  // ========================= TAFSIR OPERATIONS =========================

  @override
  Future<Result<List<TafsirInfo>>> getAvailableTafsirs() async {
    return ResultError(const ServerFailure(message: 'Not implemented yet'));
  }

  @override
  Future<Result<String>> getVerseTafsir(
    int surahNumber,
    int verseNumber,
    String tafsirKey,
  ) async {
    return ResultError(const ServerFailure(message: 'Not implemented yet'));
  }

  // ========================= AUDIO OPERATIONS =========================

  @override
  Future<Result<List<ReciterInfo>>> getAvailableReciters() async {
    return ResultError(const ServerFailure(message: 'Not implemented yet'));
  }

  @override
  Future<Result<String>> getVerseAudioUrl(
    int surahNumber,
    int verseNumber,
    String reciterKey,
  ) async {
    return ResultError(const ServerFailure(message: 'Not implemented yet'));
  }

  @override
  Future<Result<String>> getSurahAudioUrl(
      int surahNumber, String reciterKey) async {
    return ResultError(const ServerFailure(message: 'Not implemented yet'));
  }

  // ========================= BOOKMARK OPERATIONS =========================

  @override
  Future<Result<List<BookmarkedVerse>>> getBookmarkedVerses() async {
    try {
      final bookmarks = _bookmarkBox.values.toList();
      final bookmarkedVerses = <BookmarkedVerse>[];

      for (final bookmark in bookmarks) {
        // Get the verse details from cache or API
        final surahResult = await getSurah(bookmark.surahNumber);
        if (surahResult is Success<Surah>) {
          final surah = surahResult.data;
          final verse = surah.verses.firstWhere(
            (v) => v.number == bookmark.ayahNumber,
            orElse: () => Verse(
              number: bookmark.ayahNumber,
              arabicText: bookmark.text,
            ),
          );

          final bookmarkedVerse = BookmarkedVerse(
            surahNumber: bookmark.surahNumber,
            verseNumber: bookmark.ayahNumber,
            surahName: surah.name,
            arabicText: verse.arabicText,
            translation: verse.translation,
            note: bookmark.note,
            createdAt: bookmark.createdAt,
          );

          bookmarkedVerses.add(bookmarkedVerse);
        }
      }

      return Success(bookmarkedVerses);
    } catch (e) {
      return ResultError(
          StorageFailure(message: 'Failed to get bookmarks: $e'));
    }
  }

  @override
  Future<Result<void>> addBookmark(
      int surahNumber, int verseNumber, String? note) async {
    try {
      if (kDebugMode) {
        debugPrint(
            '🔖 Attempting to add bookmark: Surah $surahNumber, Verse $verseNumber');
      }

      // Check if already bookmarked first
      final isBookmarked = await isVerseBookmarked(surahNumber, verseNumber);
      if (isBookmarked is Success<bool> && isBookmarked.data) {
        if (kDebugMode) {
          debugPrint(
              '⚠️ Bookmark already exists for Surah $surahNumber, Verse $verseNumber');
        }
        return ResultError(const ValidationFailure(
          message: 'Verse is already bookmarked',
        ));
      }

      // Try to get surah name from cache first
      String surahName = 'Surah $surahNumber';
      String verseText = 'Verse $verseNumber';

      final cached = _surahBox.get(surahNumber);
      if (cached != null) {
        surahName = cached.name;
        // Try to find the verse text in cached data
        try {
          final cachedVerse = cached.ayahs.firstWhere(
            (ayah) => ayah.numberInSurah == verseNumber,
          );
          verseText = cachedVerse.text;
        } catch (e) {
          // Verse not found in cache, use fallback
          if (kDebugMode) {
            debugPrint('📝 Using fallback text for verse $verseNumber');
          }
        }
      }

      // Create bookmark with available data
      final bookmark = Bookmark(
        surahNumber: surahNumber,
        surahName: surahName,
        ayahNumber: verseNumber,
        text: verseText,
        note: note,
      );

      // Store in Hive
      final key = '${surahNumber}_$verseNumber';
      await _bookmarkBox.put(key, bookmark);

      if (kDebugMode) {
        debugPrint('✅ Bookmark saved successfully: $key');
      }

      return Success(null);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Failed to add bookmark: $e');
      }
      return ResultError(StorageFailure(
        message: 'Failed to save bookmark: $e',
      ));
    }
  }

  @override
  Future<Result<void>> removeBookmark(int surahNumber, int verseNumber) async {
    try {
      final key = '${surahNumber}_$verseNumber';
      await _bookmarkBox.delete(key);
      return Success(null);
    } catch (e) {
      return ResultError(
          StorageFailure(message: 'Failed to remove bookmark: $e'));
    }
  }

  @override
  Future<Result<bool>> isVerseBookmarked(
      int surahNumber, int verseNumber) async {
    try {
      final key = '${surahNumber}_$verseNumber';
      final bookmark = _bookmarkBox.get(key);
      return Success(bookmark != null);
    } catch (e) {
      return ResultError(
          StorageFailure(message: 'Failed to check bookmark: $e'));
    }
  }

  // ========================= READING PROGRESS OPERATIONS =========================

  @override
  Future<Result<ReadingProgress>> getReadingProgress() async {
    return ResultError(const ServerFailure(message: 'Not implemented yet'));
  }

  @override
  Future<Result<void>> updateLastRead(int surahNumber, int verseNumber) async {
    return ResultError(const ServerFailure(message: 'Not implemented yet'));
  }

  @override
  Future<Result<void>> markVerseAsRead(int surahNumber, int verseNumber) async {
    return ResultError(const ServerFailure(message: 'Not implemented yet'));
  }

  @override
  Future<Result<ReadingStatistics>> getReadingStatistics() async {
    return ResultError(const ServerFailure(message: 'Not implemented yet'));
  }

  // ========================= CACHE OPERATIONS =========================

  @override
  Future<Result<void>> cacheSurah(int surahNumber,
      {String? translationKey, String? reciterKey}) async {
    return ResultError(const ServerFailure(message: 'Not implemented yet'));
  }

  @override
  Future<Result<void>> removeCachedSurah(int surahNumber) async {
    return ResultError(const ServerFailure(message: 'Not implemented yet'));
  }

  @override
  Future<Result<bool>> isSurahCached(int surahNumber) async {
    return ResultError(const ServerFailure(message: 'Not implemented yet'));
  }

  @override
  Future<Result<List<int>>> getCachedSurahs() async {
    return ResultError(const ServerFailure(message: 'Not implemented yet'));
  }

  @override
  Future<Result<void>> clearCache() async {
    return ResultError(const ServerFailure(message: 'Not implemented yet'));
  }

  @override
  Future<Result<int>> getCacheSize() async {
    return ResultError(const ServerFailure(message: 'Not implemented yet'));
  }

  // ========================= HELPER METHODS =========================

  Surah _convertApiDataToSurah(Map<String, dynamic> data) {
    final verses = <Verse>[];

    // According to alquran.cloud API docs, ayahs are in 'ayahs' array
    if (data.containsKey('ayahs') && data['ayahs'] is List) {
      final ayahsList = data['ayahs'] as List;

      for (final ayahData in ayahsList) {
        if (ayahData is Map<String, dynamic>) {
          final verse = Verse(
            number: ayahData['numberInSurah'] ?? ayahData['number'] ?? 0,
            arabicText: ayahData['text'] ?? '',
            translation: ayahData['translation'], // if available
          );
          verses.add(verse);
        }
      }
    }

    return Surah(
      number: data['number'] ?? 0,
      name: data['name'] ?? '',
      englishName: data['englishName'] ?? '',
      englishNameTranslation: data['englishNameTranslation'] ?? '',
      revelationType: data['revelationType'] ?? '',
      numberOfAyahs: data['numberOfAyahs'] ?? verses.length,
      verses: verses,
    );
  }

  Surah _convertCachedSurahToEntity(CachedSurah cached) {
    final verses = cached.ayahs
        .map((ayah) => Verse(
              number: ayah.numberInSurah,
              arabicText: ayah.text,
            ))
        .toList();

    return Surah(
      number: cached.number,
      name: cached.name,
      englishName: cached.englishName,
      englishNameTranslation: cached.englishName, // Use englishName as fallback
      revelationType: cached.revelationType,
      numberOfAyahs: cached.numberOfAyahs,
      verses: verses,
    );
  }

  CachedSurah _convertSurahToCached(Surah surah) {
    return CachedSurah(
      number: surah.number,
      name: surah.name,
      englishName: surah.englishName,
      revelationType: surah.revelationType,
      numberOfAyahs: surah.numberOfAyahs,
      ayahs: surah.verses
          .map((verse) => CachedAyah(
                number: verse.number,
                text: verse.arabicText,
                numberInSurah: verse.number,
              ))
          .toList(),
      cachedAt: DateTime.now(),
    );
  }

  @override
  Future<void> dispose() async {
    try {
      await _surahBox.close();
      await _bookmarkBox.close();
      await _progressBox.close();
    } catch (e) {
      // Log error but don't throw to avoid issues during cleanup
    }
  }
}

// Helper class for reading progress model
class ReadingProgressModel extends ReadingProgress {
  const ReadingProgressModel({
    required int lastReadSurah,
    required int lastReadVerse,
    required DateTime lastReadTime,
    required int totalVersesRead,
    required int totalSurahsCompleted,
    required double completionPercentage,
  }) : super(
          lastReadSurah: lastReadSurah,
          lastReadVerse: lastReadVerse,
          lastReadTime: lastReadTime,
          totalVersesRead: totalVersesRead,
          totalSurahsCompleted: totalSurahsCompleted,
          completionPercentage: completionPercentage,
        );
}
