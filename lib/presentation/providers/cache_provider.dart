import 'package:flutter/foundation.dart';
import '../../core/utils/dependency_injection.dart';
import '../../domain/repositories/quran_repository_interface.dart';

class CacheProvider extends ChangeNotifier {
  QuranRepositoryInterface? _repository;
  bool _isInitialized = false;
  Map<String, dynamic> _cacheInfo = {};
  bool _isLoading = false;

  QuranRepositoryInterface? get repository => _repository;
  bool get isInitialized => _isInitialized;
  Map<String, dynamic> get cacheInfo => _cacheInfo;
  bool get isLoading => _isLoading;

  Future<void> initializeRepository() async {
    if (_isInitialized) return;

    try {
      _isLoading = true;
      notifyListeners();

      _repository = DependencyInjection.quranRepository;
      await updateCacheInfo();

      _isInitialized = true;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      throw Exception('Failed to initialize cache: $e');
    }
  }

  Future<void> updateCacheInfo() async {
    if (_repository == null) return;

    try {
      final cacheSizeResult = await _repository!.getCacheSize();
      final cachedSurahsResult = await _repository!.getCachedSurahs();

      if (cacheSizeResult is Success<int> &&
          cachedSurahsResult is Success<List<int>>) {
        _cacheInfo = {
          'cache_size_bytes': cacheSizeResult.data,
          'cached_surahs': cachedSurahsResult.data,
          'total_cache_items': cachedSurahsResult.data.length,
        };
      } else {
        _cacheInfo = {
          'cache_size_bytes': 0,
          'cached_surahs': <int>[],
          'total_cache_items': 0,
        };
      }
      notifyListeners();
    } catch (e) {
      debugPrint('Failed to update cache info: $e');
    }
  }

  Future<void> clearAllCache() async {
    if (_repository == null) return;

    try {
      _isLoading = true;
      notifyListeners();

      final result = await _repository!.clearCache();
      if (result is Success<void>) {
      await updateCacheInfo();
      } else {
        throw Exception('Failed to clear cache');
      }

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      throw Exception('Failed to clear cache: $e');
    }
  }

  // Get formatted cache size
  String get formattedCacheSize {
    final sizeBytes = _cacheInfo['cache_size_bytes'] ?? 0;
    final sizeMB = sizeBytes / 1024 / 1024;
    return '${sizeMB.toStringAsFixed(2)} MB';
  }

  // Get total cached items
  int get totalCachedItems {
    return _cacheInfo['total_cache_items'] ?? 0;
  }

  // Get cached surahs list
  List<int> get cachedSurahs {
    return List<int>.from(_cacheInfo['cached_surahs'] ?? []);
  }

  // Get offline capability status
  String get offlineStatus {
    final cachedSurahsList = cachedSurahs;

    if (cachedSurahsList.isNotEmpty) {
      return 'Quran text available offline (${cachedSurahsList.length} surahs)';
    } else {
      return 'No offline content';
    }
  }
}
