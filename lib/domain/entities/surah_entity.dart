/// Pure business entity representing a Surah (chapter) in the Quran
/// Contains no dependencies on frameworks or external libraries
class Surah {
  final int number;
  final String name;
  final String englishName;
  final String englishNameTranslation;
  final String revelationType;
  final int numberOfAyahs;
  final List<Verse> verses;

  const Surah({
    required this.number,
    required this.name,
    required this.englishName,
    required this.englishNameTranslation,
    required this.revelationType,
    required this.numberOfAyahs,
    required this.verses,
  });

  /// Check if this is a Meccan surah
  bool get isMeccan => revelationType.toLowerCase() == 'meccan';

  /// Check if this is a Medinan surah
  bool get isMedinan => revelationType.toLowerCase() == 'medinan';

  /// Get the total length of Arabic text in this surah
  int get totalCharacters =>
      verses.fold(0, (sum, verse) => sum + verse.arabicText.length);

  /// Get verses that are bookmarked
  List<Verse> get bookmarkedVerses =>
      verses.where((verse) => verse.isBookmarked).toList();

  /// Check if surah has any bookmarked verses
  bool get hasBookmarks => verses.any((verse) => verse.isBookmarked);

  /// Get a specific verse by number
  Verse? getVerse(int verseNumber) {
    try {
      return verses.firstWhere((verse) => verse.number == verseNumber);
    } catch (e) {
      return null;
    }
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Surah &&
        other.number == number &&
        other.name == name &&
        other.englishName == englishName &&
        other.englishNameTranslation == englishNameTranslation &&
        other.revelationType == revelationType &&
        other.numberOfAyahs == numberOfAyahs;
  }

  @override
  int get hashCode {
    return number.hashCode ^
        name.hashCode ^
        englishName.hashCode ^
        englishNameTranslation.hashCode ^
        revelationType.hashCode ^
        numberOfAyahs.hashCode;
  }

  @override
  String toString() {
    return 'Surah{number: $number, name: $name, englishName: $englishName, '
        'revelationType: $revelationType, numberOfAyahs: $numberOfAyahs}';
  }
}

/// Pure business entity representing a Verse (Ayah) in the Quran
class Verse {
  final int number;
  final String arabicText;
  final String? translation;
  final String? tafsir;
  final bool isBookmarked;
  final DateTime? lastRead;
  final String? translationAuthor;
  final String? tafsirAuthor;

  const Verse({
    required this.number,
    required this.arabicText,
    this.translation,
    this.tafsir,
    this.isBookmarked = false,
    this.lastRead,
    this.translationAuthor,
    this.tafsirAuthor,
  });

  /// Get word count in Arabic text (approximate)
  int get wordCount => arabicText.split(' ').length;

  /// Get character count in Arabic text
  int get characterCount => arabicText.length;

  /// Check if verse has translation
  bool get hasTranslation => translation != null && translation!.isNotEmpty;

  /// Check if verse has tafsir (commentary)
  bool get hasTafsir => tafsir != null && tafsir!.isNotEmpty;

  /// Check if verse was read recently (within last 24 hours)
  bool get isRecentlyRead {
    if (lastRead == null) return false;
    return DateTime.now().difference(lastRead!).inHours < 24;
  }

  /// Create a copy with modified properties
  Verse copyWith({
    int? number,
    String? arabicText,
    String? translation,
    String? tafsir,
    bool? isBookmarked,
    DateTime? lastRead,
    String? translationAuthor,
    String? tafsirAuthor,
  }) {
    return Verse(
      number: number ?? this.number,
      arabicText: arabicText ?? this.arabicText,
      translation: translation ?? this.translation,
      tafsir: tafsir ?? this.tafsir,
      isBookmarked: isBookmarked ?? this.isBookmarked,
      lastRead: lastRead ?? this.lastRead,
      translationAuthor: translationAuthor ?? this.translationAuthor,
      tafsirAuthor: tafsirAuthor ?? this.tafsirAuthor,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Verse &&
        other.number == number &&
        other.arabicText == arabicText &&
        other.translation == translation &&
        other.tafsir == tafsir &&
        other.isBookmarked == isBookmarked &&
        other.translationAuthor == translationAuthor &&
        other.tafsirAuthor == tafsirAuthor;
  }

  @override
  int get hashCode {
    return number.hashCode ^
        arabicText.hashCode ^
        translation.hashCode ^
        tafsir.hashCode ^
        isBookmarked.hashCode ^
        translationAuthor.hashCode ^
        tafsirAuthor.hashCode;
  }

  @override
  String toString() {
    return 'Verse{number: $number, arabicText: ${arabicText.substring(0, 20)}..., '
        'hasTranslation: $hasTranslation, isBookmarked: $isBookmarked}';
  }
}
