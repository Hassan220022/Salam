import 'package:hive/hive.dart';

part 'cached_surah.g.dart';

@HiveType(typeId: 0)
class CachedSurah extends HiveObject {
  @HiveField(0)
  final int number;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final String englishName;

  @HiveField(3)
  final String revelationType;

  @HiveField(4)
  final int numberOfAyahs;

  @HiveField(5)
  final List<CachedAyah> ayahs;

  @HiveField(6)
  final DateTime cachedAt;

  CachedSurah({
    required this.number,
    required this.name,
    required this.englishName,
    required this.revelationType,
    required this.numberOfAyahs,
    required this.ayahs,
    required this.cachedAt,
  });

  factory CachedSurah.fromJson(Map<String, dynamic> json) {
    return CachedSurah(
      number: json['number'],
      name: json['name'],
      englishName: json['englishName'],
      revelationType: json['revelationType'],
      numberOfAyahs: json['numberOfAyahs'],
      ayahs: (json['ayahs'] as List<dynamic>)
          .map((ayah) => CachedAyah.fromJson(ayah))
          .toList(),
      cachedAt: DateTime.now(),
    );
  }

  bool get isExpired {
    final now = DateTime.now();
    final daysSinceCached = now.difference(cachedAt).inDays;
    return daysSinceCached > 7; // Cache expires after 7 days
  }
}

@HiveType(typeId: 1)
class CachedAyah extends HiveObject {
  @HiveField(0)
  final int number;

  @HiveField(1)
  final String text;

  @HiveField(2)
  final int numberInSurah;

  @HiveField(3)
  final String? translation;

  @HiveField(4)
  final String? tafsir;

  CachedAyah({
    required this.number,
    required this.text,
    required this.numberInSurah,
    this.translation,
    this.tafsir,
  });

  factory CachedAyah.fromJson(Map<String, dynamic> json) {
    return CachedAyah(
      number: json['number'],
      text: json['text'],
      numberInSurah: json['numberInSurah'],
      translation: json['translation'],
      tafsir: json['tafsir'],
    );
  }
}
