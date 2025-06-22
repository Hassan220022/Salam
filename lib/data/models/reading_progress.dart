class ReadingProgress {
  final int surahNumber;
  final String surahName;
  final int lastReadAyah;
  final DateTime lastReadTime;
  final int totalAyahs;

  ReadingProgress({
    required this.surahNumber,
    required this.surahName,
    required this.lastReadAyah,
    required this.lastReadTime,
    required this.totalAyahs,
  });

  factory ReadingProgress.fromJson(Map<String, dynamic> json) {
    return ReadingProgress(
      surahNumber: json['surahNumber'],
      surahName: json['surahName'],
      lastReadAyah: json['lastReadAyah'],
      lastReadTime: DateTime.parse(json['lastReadTime']),
      totalAyahs: json['totalAyahs'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'surahNumber': surahNumber,
      'surahName': surahName,
      'lastReadAyah': lastReadAyah,
      'lastReadTime': lastReadTime.toIso8601String(),
      'totalAyahs': totalAyahs,
    };
  }

  double get progressPercentage {
    return (lastReadAyah / totalAyahs) * 100;
  }
}
