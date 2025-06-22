import 'package:hive/hive.dart';

part 'bookmark.g.dart';

@HiveType(typeId: 2)
class Bookmark extends HiveObject {
  @HiveField(0)
  final int surahNumber;

  @HiveField(1)
  final String surahName;

  @HiveField(2)
  final int ayahNumber;

  @HiveField(3)
  final String text;

  @HiveField(4)
  final String? note;

  @HiveField(5)
  final DateTime createdAt;

  Bookmark({
    required this.surahNumber,
    required this.surahName,
    required this.ayahNumber,
    required this.text,
    this.note,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  factory Bookmark.fromJson(Map<String, dynamic> json) {
    return Bookmark(
      surahNumber: json['surahNumber'],
      surahName: json['surahName'],
      ayahNumber: json['ayahNumber'],
      text: json['text'],
      note: json['note'],
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'surahNumber': surahNumber,
      'surahName': surahName,
      'ayahNumber': ayahNumber,
      'text': text,
      'note': note,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
