import '../../core/errors/failures.dart';
import '../entities/surah_entity.dart';
import '../repositories/quran_repository_interface.dart';

/// Use case for managing verse bookmarks
/// Encapsulates business logic for bookmark operations
class ManageBookmarksUseCase {
  final QuranRepositoryInterface repository;

  const ManageBookmarksUseCase(this.repository);

  /// Add a verse to bookmarks with optional note
  Future<Result<void>> addBookmark({
    required int surahNumber,
    required int verseNumber,
    String? note,
  }) async {
    // Validate input
    if (surahNumber < 1 || surahNumber > 114) {
      return ResultError(
        InvalidInputFailure(
          message: 'Invalid surah number: $surahNumber',
        ),
      );
    }

    if (verseNumber < 1) {
      return ResultError(
        InvalidInputFailure(
          message: 'Invalid verse number: $verseNumber',
        ),
      );
    }

    // Check if already bookmarked
    final isBookmarkedResult = await repository.isVerseBookmarked(
      surahNumber,
      verseNumber,
    );

    if (isBookmarkedResult is Success<bool> && isBookmarkedResult.data) {
      return ResultError(
        ValidationFailure(
          message: 'Verse $surahNumber:$verseNumber is already bookmarked',
        ),
      );
    }

    // Add bookmark - the repository will handle verse lookup and validation
    return await repository.addBookmark(surahNumber, verseNumber, note);
  }

  /// Remove a verse from bookmarks
  Future<Result<void>> removeBookmark({
    required int surahNumber,
    required int verseNumber,
  }) async {
    // Validate input
    if (surahNumber < 1 || surahNumber > 114) {
      return ResultError(
        InvalidInputFailure(
          message: 'Invalid surah number: $surahNumber',
        ),
      );
    }

    if (verseNumber < 1) {
      return ResultError(
        InvalidInputFailure(
          message: 'Invalid verse number: $verseNumber',
        ),
      );
    }

    // Check if bookmarked first
    final isBookmarkedResult = await repository.isVerseBookmarked(
      surahNumber,
      verseNumber,
    );

    if (isBookmarkedResult is Success<bool> && !isBookmarkedResult.data) {
      return ResultError(
        ValidationFailure(
          message: 'Verse $surahNumber:$verseNumber is not bookmarked',
        ),
      );
    }

    // Remove bookmark
    return await repository.removeBookmark(surahNumber, verseNumber);
  }

  /// Toggle bookmark status for a verse
  Future<Result<bool>> toggleBookmark({
    required int surahNumber,
    required int verseNumber,
    String? note,
  }) async {
    // Check current bookmark status
    final isBookmarkedResult = await repository.isVerseBookmarked(
      surahNumber,
      verseNumber,
    );

    if (isBookmarkedResult is ResultError<bool>) {
      return ResultError(isBookmarkedResult.failure);
    }

    final isBookmarked = (isBookmarkedResult as Success<bool>).data;

    if (isBookmarked) {
      // Remove bookmark
      final removeResult = await removeBookmark(
        surahNumber: surahNumber,
        verseNumber: verseNumber,
      );

      if (removeResult is Success<void>) {
        return Success(false); // Now unbookmarked
      } else {
        return ResultError((removeResult as ResultError<void>).failure);
      }
    } else {
      // Add bookmark
      final addResult = await addBookmark(
        surahNumber: surahNumber,
        verseNumber: verseNumber,
        note: note,
      );

      if (addResult is Success<void>) {
        return Success(true); // Now bookmarked
      } else {
        return ResultError((addResult as ResultError<void>).failure);
      }
    }
  }

  /// Get all bookmarked verses sorted by date
  Future<Result<List<BookmarkedVerse>>> getAllBookmarks({
    bool sortByDate = true,
    bool descending = true,
  }) async {
    final result = await repository.getBookmarkedVerses();

    if (result is Success<List<BookmarkedVerse>>) {
      var bookmarks = result.data;

      if (sortByDate) {
        bookmarks = List.from(bookmarks);
        bookmarks.sort((a, b) {
          final comparison = a.createdAt.compareTo(b.createdAt);
          return descending ? -comparison : comparison;
        });
      }

      return Success(bookmarks);
    }

    return result;
  }

  /// Get bookmarks for a specific surah
  Future<Result<List<BookmarkedVerse>>> getBookmarksForSurah(
    int surahNumber,
  ) async {
    // Validate input
    if (surahNumber < 1 || surahNumber > 114) {
      return ResultError(
        InvalidInputFailure(
          message: 'Invalid surah number: $surahNumber',
        ),
      );
    }

    final allBookmarksResult = await getAllBookmarks();

    if (allBookmarksResult is Success<List<BookmarkedVerse>>) {
      final filteredBookmarks = allBookmarksResult.data
          .where((bookmark) => bookmark.surahNumber == surahNumber)
          .toList();

      return Success(filteredBookmarks);
    }

    return ResultError(
        (allBookmarksResult as ResultError<List<BookmarkedVerse>>).failure);
  }

  /// Search bookmarks by text content
  Future<Result<List<BookmarkedVerse>>> searchBookmarks(String query) async {
    if (query.trim().isEmpty) {
      return ResultError(
        InvalidInputFailure(
          message: 'Search query cannot be empty',
        ),
      );
    }

    final allBookmarksResult = await getAllBookmarks();

    if (allBookmarksResult is Success<List<BookmarkedVerse>>) {
      final searchQuery = query.toLowerCase().trim();
      final filteredBookmarks = allBookmarksResult.data.where((bookmark) {
        return bookmark.arabicText.toLowerCase().contains(searchQuery) ||
            bookmark.translation?.toLowerCase().contains(searchQuery) == true ||
            bookmark.note?.toLowerCase().contains(searchQuery) == true ||
            bookmark.surahName.toLowerCase().contains(searchQuery);
      }).toList();

      return Success(filteredBookmarks);
    }

    return ResultError(
        (allBookmarksResult as ResultError<List<BookmarkedVerse>>).failure);
  }

  /// Get bookmark statistics
  Future<Result<BookmarkStatistics>> getBookmarkStatistics() async {
    final allBookmarksResult = await getAllBookmarks(sortByDate: false);

    if (allBookmarksResult is Success<List<BookmarkedVerse>>) {
      final bookmarks = allBookmarksResult.data;

      // Calculate statistics
      final totalBookmarks = bookmarks.length;
      final surahsWithBookmarks =
          bookmarks.map((b) => b.surahNumber).toSet().length;
      final bookmarksWithNotes =
          bookmarks.where((b) => b.note?.isNotEmpty == true).length;

      // Find most bookmarked surah
      final surahCounts = <int, int>{};
      for (final bookmark in bookmarks) {
        surahCounts[bookmark.surahNumber] =
            (surahCounts[bookmark.surahNumber] ?? 0) + 1;
      }

      int? mostBookmarkedSurah;
      int maxCount = 0;
      surahCounts.forEach((surah, count) {
        if (count > maxCount) {
          maxCount = count;
          mostBookmarkedSurah = surah;
        }
      });

      final stats = BookmarkStatistics(
        totalBookmarks: totalBookmarks,
        surahsWithBookmarks: surahsWithBookmarks,
        bookmarksWithNotes: bookmarksWithNotes,
        mostBookmarkedSurah: mostBookmarkedSurah,
        mostBookmarkedSurahCount: maxCount,
        averageBookmarksPerSurah: surahsWithBookmarks > 0
            ? (totalBookmarks / surahsWithBookmarks).round()
            : 0,
      );

      return Success(stats);
    }

    return ResultError(
        (allBookmarksResult as ResultError<List<BookmarkedVerse>>).failure);
  }
}

/// Statistics about user's bookmarks
class BookmarkStatistics {
  final int totalBookmarks;
  final int surahsWithBookmarks;
  final int bookmarksWithNotes;
  final int? mostBookmarkedSurah;
  final int mostBookmarkedSurahCount;
  final int averageBookmarksPerSurah;

  const BookmarkStatistics({
    required this.totalBookmarks,
    required this.surahsWithBookmarks,
    required this.bookmarksWithNotes,
    this.mostBookmarkedSurah,
    required this.mostBookmarkedSurahCount,
    required this.averageBookmarksPerSurah,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is BookmarkStatistics &&
        other.totalBookmarks == totalBookmarks &&
        other.surahsWithBookmarks == surahsWithBookmarks &&
        other.bookmarksWithNotes == bookmarksWithNotes &&
        other.mostBookmarkedSurah == mostBookmarkedSurah &&
        other.mostBookmarkedSurahCount == mostBookmarkedSurahCount &&
        other.averageBookmarksPerSurah == averageBookmarksPerSurah;
  }

  @override
  int get hashCode {
    return totalBookmarks.hashCode ^
        surahsWithBookmarks.hashCode ^
        bookmarksWithNotes.hashCode ^
        mostBookmarkedSurah.hashCode ^
        mostBookmarkedSurahCount.hashCode ^
        averageBookmarksPerSurah.hashCode;
  }

  @override
  String toString() {
    return 'BookmarkStatistics{totalBookmarks: $totalBookmarks, '
        'surahsWithBookmarks: $surahsWithBookmarks, '
        'mostBookmarkedSurah: $mostBookmarkedSurah}';
  }
}
