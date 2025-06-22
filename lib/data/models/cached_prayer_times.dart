import 'package:hive/hive.dart';

part 'cached_prayer_times.g.dart';

@HiveType(typeId: 2)
class CachedPrayerTimes extends HiveObject {
  @HiveField(0)
  final String fajr;

  @HiveField(1)
  final String dhuhr;

  @HiveField(2)
  final String asr;

  @HiveField(3)
  final String maghrib;

  @HiveField(4)
  final String isha;

  @HiveField(5)
  final DateTime date;

  @HiveField(6)
  final double latitude;

  @HiveField(7)
  final double longitude;

  @HiveField(8)
  final DateTime cachedAt;

  CachedPrayerTimes({
    required this.fajr,
    required this.dhuhr,
    required this.asr,
    required this.maghrib,
    required this.isha,
    required this.date,
    required this.latitude,
    required this.longitude,
    required this.cachedAt,
  });

  factory CachedPrayerTimes.fromJson(
    Map<String, dynamic> json,
    DateTime date,
    double latitude,
    double longitude,
  ) {
    return CachedPrayerTimes(
      fajr: json['Fajr'] ?? '',
      dhuhr: json['Dhuhr'] ?? '',
      asr: json['Asr'] ?? '',
      maghrib: json['Maghrib'] ?? '',
      isha: json['Isha'] ?? '',
      date: date,
      latitude: latitude,
      longitude: longitude,
      cachedAt: DateTime.now(),
    );
  }

  Map<String, dynamic> toTimingsMap() {
    return {
      'Fajr': fajr,
      'Dhuhr': dhuhr,
      'Asr': asr,
      'Maghrib': maghrib,
      'Isha': isha,
    };
  }

  bool get isExpired {
    final now = DateTime.now();
    final daysDifference = now.difference(date).inDays;
    return daysDifference != 0; // Prayer times expire daily
  }

  bool isForLocation(double lat, double lng) {
    const double tolerance = 0.01; // ~1km tolerance
    return (latitude - lat).abs() < tolerance &&
        (longitude - lng).abs() < tolerance;
  }
}
