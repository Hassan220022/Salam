import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../../data/models/reading_progress.dart';

class ReadingProgressProvider with ChangeNotifier {
  Map<int, ReadingProgress> _readingProgress = {};

  Map<int, ReadingProgress> get readingProgress => _readingProgress;

  ReadingProgressProvider() {
    _loadProgress();
  }

  Future<void> updateProgress(
      int surahNumber, String surahName, int ayahNumber, int totalAyahs) async {
    // Calculate progress percentage
    final progressPercentage = (ayahNumber / totalAyahs) * 100;

    // If progress is 100% or more, remove the progress entry instead of updating it
    if (progressPercentage >= 100.0) {
      _readingProgress.remove(surahNumber);
      await _saveProgress();
      notifyListeners();
      return;
    }

    _readingProgress[surahNumber] = ReadingProgress(
      surahNumber: surahNumber,
      surahName: surahName,
      lastReadAyah: ayahNumber,
      lastReadTime: DateTime.now(),
      totalAyahs: totalAyahs,
    );
    await _saveProgress();
    notifyListeners();
  }

  ReadingProgress? getProgress(int surahNumber) {
    return _readingProgress[surahNumber];
  }

  List<ReadingProgress> getRecentlyRead() {
    final progressList = _readingProgress.values.toList();
    progressList.sort((a, b) => b.lastReadTime.compareTo(a.lastReadTime));
    return progressList.take(5).toList();
  }

  Future<void> _loadProgress() async {
    final prefs = await SharedPreferences.getInstance();
    final progressJson = prefs.getString('readingProgress');
    if (progressJson != null) {
      final Map<String, dynamic> progressMap = json.decode(progressJson);
      _readingProgress = progressMap.map(
        (key, value) => MapEntry(
          int.parse(key),
          ReadingProgress.fromJson(value),
        ),
      );
      notifyListeners();
    }
  }

  Future<void> _saveProgress() async {
    final prefs = await SharedPreferences.getInstance();
    final progressMap = _readingProgress.map(
      (key, value) => MapEntry(key.toString(), value.toJson()),
    );
    await prefs.setString('readingProgress', json.encode(progressMap));
  }

  void clearProgress(int surahNumber) {
    _readingProgress.remove(surahNumber);
    _saveProgress();
    notifyListeners();
  }

  void clearAllProgress() {
    _readingProgress.clear();
    _saveProgress();
    notifyListeners();
  }
}
