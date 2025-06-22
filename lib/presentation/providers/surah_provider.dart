import 'package:flutter/material.dart';
import '../../domain/entities/surah_entity.dart';
import '../../domain/repositories/quran_repository_interface.dart';
import '../../domain/usecases/get_surah_usecase.dart';

/// Provider for managing Quran surahs following clean architecture
/// Uses GetSurahUseCase for business logic
class SurahProvider with ChangeNotifier {
  final GetSurahUseCase _getSurahUseCase;

  List<Surah> _surahs = [];
  Surah? _currentSurah;
  bool _isLoading = false;
  String? _errorMessage;

  SurahProvider(this._getSurahUseCase);

  // Getters
  List<Surah> get surahs => _surahs;
  Surah? get currentSurah => _currentSurah;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get hasSurahs => _surahs.isNotEmpty;
  int get surahCount => _surahs.length;

  /// Load all surahs
  Future<void> loadAllSurahs() async {
    _setLoading(true);
    _clearError();

    final result = await _getSurahUseCase.executeAll();

    if (result is Success<List<Surah>>) {
      _surahs = result.data;
      _setLoading(false);
    } else if (result is ResultError<List<Surah>>) {
      _setError('Failed to load surahs: ${result.failure.message}');
      _setLoading(false);
    }
  }

  /// Load a specific surah by number
  Future<bool> loadSurah(int surahNumber) async {
    _setLoading(true);
    _clearError();

    final result = await _getSurahUseCase.execute(surahNumber);

    if (result is Success<Surah>) {
      _currentSurah = result.data;

      // Update surah in the list if it exists
      final index = _surahs.indexWhere((s) => s.number == surahNumber);
      if (index != -1) {
        _surahs[index] = result.data;
      } else {
        _surahs.add(result.data);
      }

      _setLoading(false);
      return true;
    } else if (result is ResultError<Surah>) {
      _setError('Failed to load surah: ${result.failure.message}');
      _setLoading(false);
      return false;
    }

    _setLoading(false);
    return false;
  }

  /// Load multiple surahs
  Future<bool> loadMultipleSurahs(List<int> surahNumbers) async {
    _setLoading(true);
    _clearError();

    final result = await _getSurahUseCase.executeMultiple(surahNumbers);

    if (result is Success<List<Surah>>) {
      for (final surah in result.data) {
        final index = _surahs.indexWhere((s) => s.number == surah.number);
        if (index != -1) {
          _surahs[index] = surah;
        } else {
          _surahs.add(surah);
        }
      }

      // Sort surahs by number
      _surahs.sort((a, b) => a.number.compareTo(b.number));

      _setLoading(false);
      return true;
    } else if (result is ResultError<List<Surah>>) {
      _setError('Failed to load surahs: ${result.failure.message}');
      _setLoading(false);
      return false;
    }

    _setLoading(false);
    return false;
  }

  /// Load surah with translation
  Future<bool> loadSurahWithTranslation(
      int surahNumber, String translationKey) async {
    _setLoading(true);
    _clearError();

    final result = await _getSurahUseCase.executeWithTranslation(
        surahNumber, translationKey);

    if (result is Success<Surah>) {
      _currentSurah = result.data;

      // Update surah in the list
      final index = _surahs.indexWhere((s) => s.number == surahNumber);
      if (index != -1) {
        _surahs[index] = result.data;
      } else {
        _surahs.add(result.data);
      }

      _setLoading(false);
      return true;
    } else if (result is ResultError<Surah>) {
      _setError(
          'Failed to load surah with translation: ${result.failure.message}');
      _setLoading(false);
      return false;
    }

    _setLoading(false);
    return false;
  }

  /// Search surahs by name
  List<Surah> searchSurahs(String query) {
    if (query.trim().isEmpty) return _surahs;

    final lowerQuery = query.toLowerCase();
    return _surahs
        .where((surah) =>
            surah.name.toLowerCase().contains(lowerQuery) ||
            surah.englishName.toLowerCase().contains(lowerQuery) ||
            surah.englishNameTranslation.toLowerCase().contains(lowerQuery))
        .toList();
  }

  /// Get surah by number
  Surah? getSurahByNumber(int number) {
    try {
      return _surahs.firstWhere((surah) => surah.number == number);
    } catch (e) {
      return null;
    }
  }

  /// Get Meccan surahs
  List<Surah> get meccanSurahs => _surahs.where((s) => s.isMeccan).toList();

  /// Get Medinan surahs
  List<Surah> get medinanSurahs => _surahs.where((s) => s.isMedinan).toList();

  /// Clear current surah
  void clearCurrentSurah() {
    _currentSurah = null;
    notifyListeners();
  }

  /// Refresh all data
  Future<void> refresh() async {
    _surahs.clear();
    _currentSurah = null;
    await loadAllSurahs();
  }

  /// Clear error message
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
