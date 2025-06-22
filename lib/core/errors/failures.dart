/// Base class for all failures in the application
/// Follows clean architecture principles for error handling
abstract class Failure {
  final String message;
  final int? code;

  const Failure({
    required this.message,
    this.code,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Failure && other.message == message && other.code == code;
  }

  @override
  int get hashCode => message.hashCode ^ code.hashCode;
}

// ========================= NETWORK FAILURES =========================
class NetworkFailure extends Failure {
  const NetworkFailure({
    required String message,
    int? code,
  }) : super(message: message, code: code);
}

class ServerFailure extends Failure {
  const ServerFailure({
    required String message,
    int? code,
  }) : super(message: message, code: code);
}

class TimeoutFailure extends Failure {
  const TimeoutFailure({
    String message = 'Request timeout',
    int? code,
  }) : super(message: message, code: code);
}

// ========================= CACHE FAILURES =========================
class CacheFailure extends Failure {
  const CacheFailure({
    required String message,
    int? code,
  }) : super(message: message, code: code);
}

class StorageFailure extends Failure {
  const StorageFailure({
    required String message,
    int? code,
  }) : super(message: message, code: code);
}

// ========================= VALIDATION FAILURES =========================
class ValidationFailure extends Failure {
  const ValidationFailure({
    required String message,
    int? code,
  }) : super(message: message, code: code);
}

class InvalidInputFailure extends Failure {
  const InvalidInputFailure({
    required String message,
    int? code,
  }) : super(message: message, code: code);
}

// ========================= PERMISSION FAILURES =========================
class PermissionFailure extends Failure {
  const PermissionFailure({
    required String message,
    int? code,
  }) : super(message: message, code: code);
}

class LocationPermissionFailure extends PermissionFailure {
  const LocationPermissionFailure({
    String message = 'Location permission denied',
    int? code,
  }) : super(message: message, code: code);
}

class NotificationPermissionFailure extends PermissionFailure {
  const NotificationPermissionFailure({
    String message = 'Notification permission denied',
    int? code,
  }) : super(message: message, code: code);
}

// ========================= AUDIO FAILURES =========================
class AudioFailure extends Failure {
  const AudioFailure({
    required String message,
    int? code,
  }) : super(message: message, code: code);
}

class AudioNotFoundFailure extends AudioFailure {
  const AudioNotFoundFailure({
    String message = 'Audio file not found',
    int? code,
  }) : super(message: message, code: code);
}

class AudioPlaybackFailure extends AudioFailure {
  const AudioPlaybackFailure({
    String message = 'Audio playback failed',
    int? code,
  }) : super(message: message, code: code);
}

// ========================= QURAN-SPECIFIC FAILURES =========================
class QuranDataFailure extends Failure {
  const QuranDataFailure({
    required String message,
    int? code,
  }) : super(message: message, code: code);
}

class SurahNotFoundFailure extends QuranDataFailure {
  final int surahNumber;

  const SurahNotFoundFailure({
    required this.surahNumber,
    String? message,
    int? code,
  }) : super(
          message: message ?? 'Surah $surahNumber not found',
          code: code,
        );

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SurahNotFoundFailure &&
        other.message == message &&
        other.code == code &&
        other.surahNumber == surahNumber;
  }

  @override
  int get hashCode => message.hashCode ^ code.hashCode ^ surahNumber.hashCode;
}

class VerseNotFoundFailure extends QuranDataFailure {
  final int surahNumber;
  final int verseNumber;

  const VerseNotFoundFailure({
    required this.surahNumber,
    required this.verseNumber,
    String? message,
    int? code,
  }) : super(
          message:
              message ?? 'Verse $verseNumber in Surah $surahNumber not found',
          code: code,
        );

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is VerseNotFoundFailure &&
        other.message == message &&
        other.code == code &&
        other.surahNumber == surahNumber &&
        other.verseNumber == verseNumber;
  }

  @override
  int get hashCode =>
      message.hashCode ^
      code.hashCode ^
      surahNumber.hashCode ^
      verseNumber.hashCode;
}

class TranslationNotFoundFailure extends QuranDataFailure {
  final String translationKey;

  const TranslationNotFoundFailure({
    required this.translationKey,
    String? message,
    int? code,
  }) : super(
          message: message ?? 'Translation $translationKey not found',
          code: code,
        );

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TranslationNotFoundFailure &&
        other.message == message &&
        other.code == code &&
        other.translationKey == translationKey;
  }

  @override
  int get hashCode =>
      message.hashCode ^ code.hashCode ^ translationKey.hashCode;
}

// ========================= PRAYER TIME FAILURES =========================
class PrayerTimeFailure extends Failure {
  const PrayerTimeFailure({
    required String message,
    int? code,
  }) : super(message: message, code: code);
}

class LocationNotFoundFailure extends PrayerTimeFailure {
  const LocationNotFoundFailure({
    String message = 'Unable to determine location',
    int? code,
  }) : super(message: message, code: code);
}

class QiblaCalculationFailure extends Failure {
  const QiblaCalculationFailure({
    String message = 'Unable to calculate Qibla direction',
    int? code,
  }) : super(message: message, code: code);
}
