import 'package:hive/hive.dart';

part 'cached_audio.g.dart';

@HiveType(typeId: 3)
class CachedAudioFile extends HiveObject {
  @HiveField(0)
  final int surahNumber;

  @HiveField(1)
  final int ayahNumber;

  @HiveField(2)
  final String localPath;

  @HiveField(3)
  final String originalUrl;

  @HiveField(4)
  final int fileSize;

  @HiveField(5)
  final DateTime downloadedAt;

  CachedAudioFile({
    required this.surahNumber,
    required this.ayahNumber,
    required this.localPath,
    required this.originalUrl,
    required this.fileSize,
    required this.downloadedAt,
  });

  String get fileName =>
      '${surahNumber.toString().padLeft(3, '0')}${ayahNumber.toString().padLeft(3, '0')}.mp3';

  bool get isExpired {
    final now = DateTime.now();
    final daysSinceDownloaded = now.difference(downloadedAt).inDays;
    return daysSinceDownloaded > 30; // Audio cache expires after 30 days
  }
}
