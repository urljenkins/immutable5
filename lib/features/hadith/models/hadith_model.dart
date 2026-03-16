class Hadith {
  final String id;
  final String collection;
  final String book;
  final int? bookNumber;
  final String hadithNumber;
  final String? narrator;
  final String arabic;
  final String translationEn;
  final String translationLanguage;
  final String grade;
  final String? gradeBy;
  final List<String> topics;
  final String summaryEn;
  final List<String> keyLessons;
  final List<String> relatedDuaIds;
  final String length; // short, medium, long
  final int? wordCountArabic;
  final int priority;
  final Map<String, dynamic>? displayContext;

  const Hadith({
    required this.id,
    required this.collection,
    required this.book,
    this.bookNumber,
    required this.hadithNumber,
    this.narrator,
    required this.arabic,
    required this.translationEn,
    this.translationLanguage = 'en',
    required this.grade,
    this.gradeBy,
    required this.topics,
    required this.summaryEn,
    required this.keyLessons,
    this.relatedDuaIds = const [],
    required this.length,
    this.wordCountArabic,
    required this.priority,
    this.displayContext,
  });

  factory Hadith.fromJson(Map<String, dynamic> json) {
    return Hadith(
      id: json['hadith_id'] as String,
      collection: json['collection'] as String,
      book: json['book'] as String,
      bookNumber: json['book_number'] as int?,
      hadithNumber: json['hadith_number'] as String,
      narrator: json['narrator'] as String?,
      arabic: json['arabic'] as String,
      translationEn: json['translation_en'] as String,
      translationLanguage: json['translation_language'] as String? ?? 'en',
      grade: json['grade'] as String,
      gradeBy: json['grade_by'] as String?,
      topics: (json['topics'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      summaryEn: json['summary_en'] as String,
      keyLessons: (json['key_lessons'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      relatedDuaIds:
          (json['related_dua_ids'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      length: json['length'] as String,
      wordCountArabic: json['word_count_arabic'] as int?,
      priority: json['priority'] as int,
      displayContext: json['display_context'] as Map<String, dynamic>?,
    );
  }
}
