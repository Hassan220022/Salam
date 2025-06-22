class Translation {
  final int number;
  final String text;
  final String edition;
  final String language;

  Translation({
    required this.number,
    required this.text,
    required this.edition,
    required this.language,
  });

  factory Translation.fromJson(Map<String, dynamic> json) {
    return Translation(
      number: json['number'] ?? 0,
      text: json['text'] ?? '',
      edition: json['edition']?['name'] ?? '',
      language: json['edition']?['language'] ?? '',
    );
  }
}

class TranslationSet {
  final List<Translation> translations;
  final String surahName;
  final int surahNumber;

  TranslationSet({
    required this.translations,
    required this.surahName,
    required this.surahNumber,
  });
}
