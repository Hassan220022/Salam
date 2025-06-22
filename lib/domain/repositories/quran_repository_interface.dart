import '../../core/errors/failures.dart';
import '../entities/surah_entity.dart';

/// Result type for handling success/failure scenarios
sealed class Result<T> {
  const Result();
}

class Success<T> extends Result<T> {
  final T data;
  const Success(this.data);
}

class ResultError<T> extends Result<T> {
  final Failure failure;
  const ResultError(this.failure);
}

/// Repository interface for Quran data operations
/// Defines the contract that must be implemented by data layer
abstract class QuranRepositoryInterface {
  // ========================= SURAH OPERATIONS =========================

  /// Get all surahs with basic information
  Future<Result<List<Surah>>> getAllSurahs();

  /// Get a specific surah by number with all verses
  Future<Result<Surah>> getSurah(int surahNumber);

  /// Get a specific verse from a surah
  Future<Result<Verse>> getVerse(int surahNumber, int verseNumber);

  /// Get multiple verses from a surah
  Future<Result<List<Verse>>> getVerses(
    int surahNumber, {
    int? startVerse,
    int? endVerse,
  });

  // ========================= SEARCH OPERATIONS =========================

  /// Search for verses containing specific Arabic text
  Future<Result<List<Verse>>> searchArabicText(String query);

  /// Search for verses in translations
  Future<Result<List<Verse>>> searchTranslation(
    String query,
    String translationKey,
  );

  /// Search for verses by surah name (Arabic or English)
  Future<Result<List<Surah>>> searchSurahs(String query);

  // ========================= TRANSLATION OPERATIONS =========================

  /// Get available translations
  Future<Result<List<TranslationInfo>>> getAvailableTranslations();

  /// Get verse translation for specific translator
  Future<Result<String>> getVerseTranslation(
    int surahNumber,
    int verseNumber,
    String translationKey,
  );

  /// Get surah translations for specific translator
  Future<Result<List<String>>> getSurahTranslations(
    int surahNumber,
    String translationKey,
  );

  // ========================= TAFSIR OPERATIONS =========================

  /// Get available tafsir (commentary) sources
  Future<Result<List<TafsirInfo>>> getAvailableTafsirs();

  /// Get verse tafsir for specific source
  Future<Result<String>> getVerseTafsir(
    int surahNumber,
    int verseNumber,
    String tafsirKey,
  );

  // ========================= AUDIO OPERATIONS =========================

  /// Get available reciters
  Future<Result<List<ReciterInfo>>> getAvailableReciters();

  /// Get audio URL for specific verse
  Future<Result<String>> getVerseAudioUrl(
    int surahNumber,
    int verseNumber,
    String reciterKey,
  );

  /// Get audio URL for entire surah
  Future<Result<String>> getSurahAudioUrl(
    int surahNumber,
    String reciterKey,
  );

  // ========================= BOOKMARK OPERATIONS =========================

  /// Get all bookmarked verses
  Future<Result<List<BookmarkedVerse>>> getBookmarkedVerses();

  /// Add verse to bookmarks
  Future<Result<void>> addBookmark(
    int surahNumber,
    int verseNumber,
    String? note,
  );

  /// Remove verse from bookmarks
  Future<Result<void>> removeBookmark(
    int surahNumber,
    int verseNumber,
  );

  /// Check if verse is bookmarked
  Future<Result<bool>> isVerseBookmarked(
    int surahNumber,
    int verseNumber,
  );

  // ========================= READING PROGRESS OPERATIONS =========================

  /// Get reading progress for user
  Future<Result<ReadingProgress>> getReadingProgress();

  /// Update last read position
  Future<Result<void>> updateLastRead(
    int surahNumber,
    int verseNumber,
  );

  /// Mark verse as read
  Future<Result<void>> markVerseAsRead(
    int surahNumber,
    int verseNumber,
  );

  /// Get reading statistics
  Future<Result<ReadingStatistics>> getReadingStatistics();

  // ========================= CACHE OPERATIONS =========================

  /// Cache surah for offline reading
  Future<Result<void>> cacheSurah(
    int surahNumber, {
    String? translationKey,
    String? reciterKey,
  });

  /// Remove surah from cache
  Future<Result<void>> removeCachedSurah(int surahNumber);

  /// Check if surah is cached
  Future<Result<bool>> isSurahCached(int surahNumber);

  /// Get list of cached surahs
  Future<Result<List<int>>> getCachedSurahs();

  /// Clear all cache
  Future<Result<void>> clearCache();

  /// Get cache size in bytes
  Future<Result<int>> getCacheSize();

  /// Dispose resources and clean up
  Future<void> dispose();
}

// ========================= SUPPORTING CLASSES =========================

/// Information about available translations
class TranslationInfo {
  final String key;
  final String name;
  final String author;
  final String language;
  final String languageCode;

  const TranslationInfo({
    required this.key,
    required this.name,
    required this.author,
    required this.language,
    required this.languageCode,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TranslationInfo && other.key == key;
  }

  @override
  int get hashCode => key.hashCode;
}

/// Information about available tafsir sources
class TafsirInfo {
  final String key;
  final String name;
  final String author;
  final String language;
  final String languageCode;

  const TafsirInfo({
    required this.key,
    required this.name,
    required this.author,
    required this.language,
    required this.languageCode,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TafsirInfo && other.key == key;
  }

  @override
  int get hashCode => key.hashCode;
}

/// Information about available reciters
class ReciterInfo {
  final String key;
  final String name;
  final String nameArabic;
  final String country;
  final String style;

  const ReciterInfo({
    required this.key,
    required this.name,
    required this.nameArabic,
    required this.country,
    required this.style,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ReciterInfo && other.key == key;
  }

  @override
  int get hashCode => key.hashCode;
}

/// Represents a bookmarked verse with metadata
class BookmarkedVerse {
  final int surahNumber;
  final int verseNumber;
  final String surahName;
  final String arabicText;
  final String? translation;
  final String? note;
  final DateTime createdAt;

  const BookmarkedVerse({
    required this.surahNumber,
    required this.verseNumber,
    required this.surahName,
    required this.arabicText,
    this.translation,
    this.note,
    required this.createdAt,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is BookmarkedVerse &&
        other.surahNumber == surahNumber &&
        other.verseNumber == verseNumber;
  }

  @override
  int get hashCode => surahNumber.hashCode ^ verseNumber.hashCode;
}

/// Represents reading progress information
class ReadingProgress {
  final int lastReadSurah;
  final int lastReadVerse;
  final DateTime lastReadTime;
  final int totalVersesRead;
  final int totalSurahsCompleted;
  final double completionPercentage;

  const ReadingProgress({
    required this.lastReadSurah,
    required this.lastReadVerse,
    required this.lastReadTime,
    required this.totalVersesRead,
    required this.totalSurahsCompleted,
    required this.completionPercentage,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ReadingProgress &&
        other.lastReadSurah == lastReadSurah &&
        other.lastReadVerse == lastReadVerse &&
        other.totalVersesRead == totalVersesRead;
  }

  @override
  int get hashCode {
    return lastReadSurah.hashCode ^
        lastReadVerse.hashCode ^
        totalVersesRead.hashCode;
  }
}

/// Reading statistics for analytics
class ReadingStatistics {
  final int totalReadingTime; // in minutes
  final int dailyStreak;
  final int longestStreak;
  final Map<String, int> monthlyStats; // month -> verses read
  final List<String> favoriteReciters;
  final List<String> favoriteTranslations;

  const ReadingStatistics({
    required this.totalReadingTime,
    required this.dailyStreak,
    required this.longestStreak,
    required this.monthlyStats,
    required this.favoriteReciters,
    required this.favoriteTranslations,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ReadingStatistics &&
        other.totalReadingTime == totalReadingTime &&
        other.dailyStreak == dailyStreak &&
        other.longestStreak == longestStreak;
  }

  @override
  int get hashCode {
    return totalReadingTime.hashCode ^
        dailyStreak.hashCode ^
        longestStreak.hashCode;
  }
}
