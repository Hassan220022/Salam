import 'package:flutter/material.dart';
import '../../domain/repositories/quran_repository_interface.dart';
import '../../domain/usecases/manage_bookmarks_usecase.dart';

/// Provider for managing bookmarks following clean architecture
/// Uses use cases instead of direct repository calls
class BookmarksProvider with ChangeNotifier {
  final ManageBookmarksUseCase _manageBookmarksUseCase;

  List<BookmarkedVerse> _bookmarks = [];
  bool _isLoading = false;
  String? _errorMessage;

  BookmarksProvider(this._manageBookmarksUseCase) {
    _loadBookmarks();
  }

  // Getters
  List<BookmarkedVerse> get bookmarks => _bookmarks;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get hasBookmarks => _bookmarks.isNotEmpty;
  int get bookmarkCount => _bookmarks.length;

  /// Load all bookmarks from storage
  Future<void> _loadBookmarks() async {
    _setLoading(true);
    _clearError();

    final result = await _manageBookmarksUseCase.getAllBookmarks();

    if (result is Success<List<BookmarkedVerse>>) {
      _bookmarks = result.data;
    } else if (result is ResultError<List<BookmarkedVerse>>) {
      _setError('Failed to load bookmarks: ${result.failure.message}');
    }

    _setLoading(false);
  }

  /// Add a bookmark for a specific verse
  Future<bool> addBookmark({
    required int surahNumber,
    required int verseNumber,
    String? note,
  }) async {
    _clearError();

    final result = await _manageBookmarksUseCase.addBookmark(
      surahNumber: surahNumber,
      verseNumber: verseNumber,
      note: note,
    );

    if (result is Success<void>) {
      await _loadBookmarks(); // Refresh the list
      return true;
    } else if (result is ResultError<void>) {
      _setError('Failed to add bookmark: ${result.failure.message}');
      return false;
    }

    return false;
  }

  /// Remove a bookmark for a specific verse
  Future<bool> removeBookmark({
    required int surahNumber,
    required int verseNumber,
  }) async {
    _clearError();

    final result = await _manageBookmarksUseCase.removeBookmark(
      surahNumber: surahNumber,
      verseNumber: verseNumber,
    );

    if (result is Success<void>) {
      await _loadBookmarks(); // Refresh the list
      return true;
    } else if (result is ResultError<void>) {
      _setError('Failed to remove bookmark: ${result.failure.message}');
      return false;
    }

    return false;
  }

  /// Toggle bookmark status for a verse
  Future<bool?> toggleBookmark({
    required int surahNumber,
    required int verseNumber,
    String? note,
  }) async {
    _clearError();

    final result = await _manageBookmarksUseCase.toggleBookmark(
      surahNumber: surahNumber,
      verseNumber: verseNumber,
      note: note,
    );

    if (result is Success<bool>) {
      await _loadBookmarks(); // Refresh the list
      return result
          .data; // Returns true if now bookmarked, false if unbookmarked
    } else if (result is ResultError<bool>) {
      _setError('Failed to toggle bookmark: ${result.failure.message}');
      return null;
    }

    return null;
  }

  /// Check if a verse is bookmarked
  bool isVerseBookmarked(int surahNumber, int verseNumber) {
    return _bookmarks.any((bookmark) =>
        bookmark.surahNumber == surahNumber &&
        bookmark.verseNumber == verseNumber);
  }

  /// Get bookmarks for a specific surah
  List<BookmarkedVerse> getBookmarksForSurah(int surahNumber) {
    return _bookmarks
        .where((bookmark) => bookmark.surahNumber == surahNumber)
        .toList();
  }

  /// Search bookmarks by text content
  Future<List<BookmarkedVerse>> searchBookmarks(String query) async {
    _clearError();

    final result = await _manageBookmarksUseCase.searchBookmarks(query);

    if (result is Success<List<BookmarkedVerse>>) {
      return result.data;
    } else if (result is ResultError<List<BookmarkedVerse>>) {
      _setError('Search failed: ${result.failure.message}');
      return [];
    }

    return [];
  }

  /// Get bookmark statistics
  Future<BookmarkStatistics?> getStatistics() async {
    _clearError();

    final result = await _manageBookmarksUseCase.getBookmarkStatistics();

    if (result is Success<BookmarkStatistics>) {
      return result.data;
    } else if (result is ResultError<BookmarkStatistics>) {
      _setError('Failed to get statistics: ${result.failure.message}');
      return null;
    }

    return null;
  }

  /// Refresh bookmarks list
  Future<void> refresh() async {
    await _loadBookmarks();
  }

  /// Clear all error messages
  void clearError() {
    _clearError();
  }

  // Private helper methods
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _errorMessage = error;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
