class Tafsir {
  final int ayahNumber;
  final String text;
  final String author;
  final String language;

  Tafsir({
    required this.ayahNumber,
    required this.text,
    required this.author,
    required this.language,
  });

  factory Tafsir.fromJson(Map<String, dynamic> json) {
    return Tafsir(
      ayahNumber: json['ayahNumber'] ?? 0,
      text: json['text'] ?? '',
      author: json['edition']?['name'] ?? '',
      language: json['edition']?['language'] ?? '',
    );
  }
}

class TafsirSet {
  final List<Tafsir> tafasir;
  final String surahName;
  final int surahNumber;

  TafsirSet({
    required this.tafasir,
    required this.surahName,
    required this.surahNumber,
  });
}
