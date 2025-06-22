/// Pure business entity representing Islamic prayer times
/// Contains no dependencies on frameworks or external libraries
class PrayerTimes {
  /// Standard prayer time detection window in minutes
  static const int defaultPrayerTimeWindowMinutes = 15;

  final DateTime fajr;
  final DateTime sunrise;
  final DateTime dhuhr;
  final DateTime asr;
  final DateTime maghrib;
  final DateTime isha;
  final DateTime date;
  final Location location;

  const PrayerTimes({
    required this.fajr,
    required this.sunrise,
    required this.dhuhr,
    required this.asr,
    required this.maghrib,
    required this.isha,
    required this.date,
    required this.location,
  });

  /// Get all prayer times in chronological order
  List<Prayer> get allPrayers => [
        Prayer(name: 'Fajr', time: fajr, type: PrayerType.fajr),
        Prayer(name: 'Dhuhr', time: dhuhr, type: PrayerType.dhuhr),
        Prayer(name: 'Asr', time: asr, type: PrayerType.asr),
        Prayer(name: 'Maghrib', time: maghrib, type: PrayerType.maghrib),
        Prayer(name: 'Isha', time: isha, type: PrayerType.isha),
      ];

  /// Get the next prayer from current time
  Prayer? getNextPrayer([DateTime? currentTime]) {
    final now = currentTime ?? DateTime.now();

    for (final prayer in allPrayers) {
      if (prayer.time.isAfter(now)) {
        return prayer;
      }
    }

    // If no prayer is found for today, return Fajr of next day
    return Prayer(
      name: 'Fajr',
      time: fajr.add(const Duration(days: 1)),
      type: PrayerType.fajr,
    );
  }

  /// Get the current prayer (the last prayer that has passed)
  Prayer? getCurrentPrayer([DateTime? currentTime]) {
    final now = currentTime ?? DateTime.now();
    Prayer? currentPrayer;

    for (final prayer in allPrayers) {
      if (prayer.time.isBefore(now)) {
        currentPrayer = prayer;
      } else {
        break;
      }
    }

    return currentPrayer;
  }

  /// Get time until next prayer
  Duration? getTimeUntilNextPrayer([DateTime? currentTime]) {
    final nextPrayer = getNextPrayer(currentTime);
    if (nextPrayer == null) return null;

    final now = currentTime ?? DateTime.now();
    return nextPrayer.time.difference(now);
  }

  /// Check if it's currently prayer time (within configurable minutes of prayer)
  bool isCurrentlyPrayerTime([
    DateTime? currentTime,
    int windowMinutes = defaultPrayerTimeWindowMinutes,
  ]) {
    final now = currentTime ?? DateTime.now();

    for (final prayer in allPrayers) {
      final difference = now.difference(prayer.time).abs();
      if (difference.inMinutes <= windowMinutes) {
        return true;
      }
    }

    return false;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PrayerTimes &&
        other.fajr == fajr &&
        other.sunrise == sunrise &&
        other.dhuhr == dhuhr &&
        other.asr == asr &&
        other.maghrib == maghrib &&
        other.isha == isha &&
        other.date == date &&
        other.location == location;
  }

  @override
  int get hashCode {
    return Object.hash(
      fajr,
      sunrise,
      dhuhr,
      asr,
      maghrib,
      isha,
      date,
      location,
    );
  }

  @override
  String toString() {
    return 'PrayerTimes{date: $date, location: $location, '
        'fajr: $fajr, dhuhr: $dhuhr, asr: $asr, maghrib: $maghrib, isha: $isha}';
  }
}

/// Represents a single prayer
class Prayer {
  final String name;
  final DateTime time;
  final PrayerType type;

  const Prayer({
    required this.name,
    required this.time,
    required this.type,
  });

  /// Check if this prayer is currently active (within prayer window)
  bool isActive([
    DateTime? currentTime,
    int windowMinutes = PrayerTimes.defaultPrayerTimeWindowMinutes,
  ]) {
    final now = currentTime ?? DateTime.now();
    final difference = now.difference(time).abs();
    return difference.inMinutes <= windowMinutes;
  }

  /// Get formatted time string
  String get formattedTime {
    final hour = time.hour;
    final minute = time.minute;
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);

    return '${displayHour.toString().padLeft(2, '0')}:'
        '${minute.toString().padLeft(2, '0')} $period';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Prayer &&
        other.name == name &&
        other.time == time &&
        other.type == type;
  }

  @override
  int get hashCode => Object.hash(name, time, type);

  @override
  String toString() => 'Prayer{name: $name, time: $formattedTime, type: $type}';
}

/// Enum representing different prayer types
enum PrayerType {
  fajr,
  dhuhr,
  asr,
  maghrib,
  isha,
}

/// Extension for PrayerType to get display names
extension PrayerTypeExtension on PrayerType {
  String get displayName {
    switch (this) {
      case PrayerType.fajr:
        return 'Fajr';
      case PrayerType.dhuhr:
        return 'Dhuhr';
      case PrayerType.asr:
        return 'Asr';
      case PrayerType.maghrib:
        return 'Maghrib';
      case PrayerType.isha:
        return 'Isha';
    }
  }

  String get arabicName {
    switch (this) {
      case PrayerType.fajr:
        return 'الفجر';
      case PrayerType.dhuhr:
        return 'الظهر';
      case PrayerType.asr:
        return 'العصر';
      case PrayerType.maghrib:
        return 'المغرب';
      case PrayerType.isha:
        return 'العشاء';
    }
  }
}

/// Represents a geographical location
class Location {
  final double latitude;
  final double longitude;
  final String? city;
  final String? country;
  final String? timezone;

  const Location({
    required this.latitude,
    required this.longitude,
    this.city,
    this.country,
    this.timezone,
  });

  /// Get display name for location
  String get displayName {
    if (city != null && country != null) {
      return '$city, $country';
    } else if (city != null) {
      return city!;
    } else if (country != null) {
      return country!;
    } else {
      return '${latitude.toStringAsFixed(2)}, ${longitude.toStringAsFixed(2)}';
    }
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Location &&
        other.latitude == latitude &&
        other.longitude == longitude &&
        other.city == city &&
        other.country == country &&
        other.timezone == timezone;
  }

  @override
  int get hashCode {
    return Object.hash(
      latitude,
      longitude,
      city,
      country,
      timezone,
    );
  }

  @override
  String toString() {
    return 'Location{lat: $latitude, lng: $longitude, city: $city, country: $country}';
  }
}
