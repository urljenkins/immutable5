import 'dart:convert';
import '../../duas/models/dua.dart'; // To reuse DisplayContext and HijriDate

class Hadith {
  final String schemaVersion;
  final String hadithId;
  final String source;
  final String license;
  final String collection;
  final String book;
  final int? bookNumber;
  final String hadithNumber;
  final String? narrator;
  final String arabic;
  final String transliteration;
  final String translationEn;
  final String translationLanguage;
  final String grade;
  final String? gradeBy;
  final List<String> topics;
  final String summaryEn;
  final List<String> keyLessons;
  final List<String> relatedDuaIds;
  final List<String> relatedHadithIds;
  final String length;
  final int? wordCountArabic;
  final int priority;
  final DisplayContext? displayContext;
  final List<HadithVariant> variants;

  /// Convenience getter for backwards compatibility with code using 'id'
  String get id => hadithId;

  const Hadith({
    required this.schemaVersion,
    required this.hadithId,
    required this.source,
    required this.license,
    required this.collection,
    required this.book,
    this.bookNumber,
    required this.hadithNumber,
    this.narrator,
    required this.arabic,
    required this.transliteration,
    required this.translationEn,
    this.translationLanguage = 'en',
    required this.grade,
    this.gradeBy,
    required this.topics,
    required this.summaryEn,
    required this.keyLessons,
    this.relatedDuaIds = const [],
    this.relatedHadithIds = const [],
    required this.length,
    this.wordCountArabic,
    required this.priority,
    this.displayContext,
    this.variants = const [],
  });

  factory Hadith.fromJson(Map<String, dynamic> json) {
    return Hadith(
      schemaVersion: json['schema_version'] as String,
      hadithId: json['hadith_id'] as String,
      source: json['source'] as String,
      license: json['license'] as String,
      collection: json['collection'] as String,
      book: json['book'] as String,
      bookNumber: (json['book_number'] as num?)?.toInt(),
      hadithNumber: json['hadith_number'] as String,
      narrator: json['narrator'] as String?,
      arabic: json['arabic'] as String,
      transliteration: json['transliteration'] as String,
      translationEn: json['translation_en'] as String,
      translationLanguage: json['translation_language'] as String? ?? 'en',
      grade: json['grade'] as String,
      gradeBy: json['grade_by'] as String?,
      topics: (json['topics'] as List<dynamic>).cast<String>(),
      summaryEn: json['summary_en'] as String,
      keyLessons: (json['key_lessons'] as List<dynamic>).cast<String>(),
      relatedDuaIds:
          (json['related_dua_ids'] as List?)?.cast<String>() ?? const [],
      relatedHadithIds:
          (json['related_hadith_ids'] as List?)?.cast<String>() ?? const [],
      length: json['length'] as String,
      wordCountArabic: (json['word_count_arabic'] as num?)?.toInt(),
      priority: (json['priority'] as num).toInt(),
      displayContext: json['display_context'] != null
          ? DisplayContext.fromJson(
              json['display_context'] as Map<String, dynamic>,
            )
          : null,
      variants: (json['variants'] as List?)
              ?.map((e) => HadithVariant.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
    );
  }

  static List<Hadith> listFromJsonString(String jsonString) {
    final decoded = json.decode(jsonString) as List<dynamic>;
    return decoded
        .map((entry) => Hadith.fromJson(entry as Map<String, dynamic>))
        .toList();
  }
}

class HadithVariant {
  final String arabic;
  final String transliteration;
  final String translationEn;
  final String source;
  final String? note;

  const HadithVariant({
    required this.arabic,
    required this.transliteration,
    required this.translationEn,
    required this.source,
    this.note,
  });

  factory HadithVariant.fromJson(Map<String, dynamic> json) {
    return HadithVariant(
      arabic: json['arabic'] as String,
      transliteration: json['transliteration'] as String,
      translationEn: json['translation_en'] as String,
      source: json['source'] as String,
      note: json['note'] as String?,
    );
  }
}
