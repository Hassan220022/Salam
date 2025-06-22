import '../../core/errors/failures.dart';
import '../entities/surah_entity.dart';
import '../repositories/quran_repository_interface.dart';

/// Use case for retrieving surah data
/// Encapsulates business logic for fetching and processing surah information
class GetSurahUseCase {
  final QuranRepositoryInterface repository;

  const GetSurahUseCase(this.repository);

  /// Get a specific surah with all its verses
  /// Validates surah number and applies business rules
  Future<Result<Surah>> execute(int surahNumber) async {
    // Validate input
    if (surahNumber < 1 || surahNumber > 114) {
      return ResultError(
        InvalidInputFailure(
          message:
              'Invalid surah number: $surahNumber. Must be between 1 and 114.',
        ),
      );
    }

    // Fetch surah from repository
    final result = await repository.getSurah(surahNumber);

    // Apply business logic if needed
    if (result is Success<Surah>) {
      final surah = result.data;

      // Validate surah data integrity
      if (surah.verses.isEmpty) {
        return ResultError(
          QuranDataFailure(
            message: 'Surah $surahNumber has no verses',
          ),
        );
      }

      // Verify verse count matches expected
      if (surah.verses.length != surah.numberOfAyahs) {
        return ResultError(
          QuranDataFailure(
            message: 'Verse count mismatch for Surah $surahNumber: '
                'expected ${surah.numberOfAyahs}, got ${surah.verses.length}',
          ),
        );
      }

      return Success(surah);
    }

    return result;
  }

  /// Get multiple surahs by their numbers
  Future<Result<List<Surah>>> executeMultiple(List<int> surahNumbers) async {
    // Validate input
    if (surahNumbers.isEmpty) {
      return ResultError(
        InvalidInputFailure(message: 'Surah numbers list cannot be empty'),
      );
    }

    // Check for invalid surah numbers
    final invalidNumbers =
        surahNumbers.where((num) => num < 1 || num > 114).toList();
    if (invalidNumbers.isNotEmpty) {
      return ResultError(
        InvalidInputFailure(
          message:
              'Invalid surah numbers: $invalidNumbers. Must be between 1 and 114.',
        ),
      );
    }

    // Fetch all surahs
    final surahs = <Surah>[];
    for (final surahNumber in surahNumbers) {
      final result = await execute(surahNumber);
      if (result is Success<Surah>) {
        surahs.add(result.data);
      } else if (result is ResultError<Surah>) {
        return ResultError(result.failure);
      }
    }

    return Success(surahs);
  }

  /// Get all surahs (1-114) from the repository
  Future<Result<List<Surah>>> executeAll() async {
    final result = await repository.getAllSurahs();

    // Apply business logic if needed
    if (result is Success<List<Surah>>) {
      final surahs = result.data;

      // Validate that we have all 114 surahs
      if (surahs.length != 114) {
        return ResultError(
          QuranDataFailure(
            message: 'Expected 114 surahs, but got ${surahs.length}',
          ),
        );
      }

      // Validate surah numbers are sequential (1-114)
      for (int i = 0; i < surahs.length; i++) {
        final expectedNumber = i + 1;
        if (surahs[i].number != expectedNumber) {
          return ResultError(
            QuranDataFailure(
              message: 'Surah number mismatch at index $i: '
                  'expected $expectedNumber, got ${surahs[i].number}',
            ),
          );
        }
      }

      return Success(surahs);
    }

    return result;
  }

  /// Get surah with specific translation
  Future<Result<Surah>> executeWithTranslation(
    int surahNumber,
    String translationKey,
  ) async {
    // First get the basic surah
    final surahResult = await execute(surahNumber);
    if (surahResult is ResultError<Surah>) {
      return surahResult;
    }

    final surah = (surahResult as Success<Surah>).data;

    // Get translations for all verses
    final translationsResult = await repository.getSurahTranslations(
      surahNumber,
      translationKey,
    );

    if (translationsResult is ResultError<List<String>>) {
      return ResultError(translationsResult.failure);
    }

    final translations = (translationsResult as Success<List<String>>).data;

    // Validate translation count matches verse count
    if (translations.length != surah.verses.length) {
      return ResultError(
        TranslationNotFoundFailure(
          translationKey: translationKey,
          message: 'Translation count mismatch for $translationKey',
        ),
      );
    }

    // Create new verses with translations
    final versesWithTranslation = <Verse>[];
    for (int i = 0; i < surah.verses.length; i++) {
      final verse = surah.verses[i];
      final translatedVerse = verse.copyWith(
        translation: translations[i],
        translationAuthor: translationKey,
      );
      versesWithTranslation.add(translatedVerse);
    }

    // Create new surah with translated verses
    final surahWithTranslation = Surah(
      number: surah.number,
      name: surah.name,
      englishName: surah.englishName,
      englishNameTranslation: surah.englishNameTranslation,
      revelationType: surah.revelationType,
      numberOfAyahs: surah.numberOfAyahs,
      verses: versesWithTranslation,
    );

    return Success(surahWithTranslation);
  }
}
 