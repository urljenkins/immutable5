class Dua {
  final String id;
  final String category;
  final String occasion;
  final List<String> tags;
  final String arabic;
  final String transliteration;
  final String translationEn;
  final String? length;
  final int? wordCountArabic;
  final int repetitions;
  final int priority;
  final String? frequency;
  final DisplayContext? displayContext;
  final Authenticity? authenticity;
  final String? benefits;
  final String? notes;

  const Dua({
    required this.id,
    this.category = '',
    required this.occasion,
    required this.tags,
    required this.arabic,
    required this.transliteration,
    required this.translationEn,
    this.length,
    this.wordCountArabic,
    this.repetitions = 1,
    this.priority = 5,
    this.frequency,
    this.displayContext,
    this.authenticity,
    this.benefits,
    this.notes,
  });

  factory Dua.fromJson(Map<String, dynamic> json) {
    return Dua(
      id: json['id'] as String,
      category: json['category'] as String? ?? 'General',
      occasion: json['occasion'] as String? ?? '',
      tags:
          (json['tags'] as List<dynamic>?)?.map((e) => e as String).toList() ??
          [],
      arabic: json['arabic'] as String,
      transliteration: json['transliteration'] as String,
      translationEn: json['translation_en'] as String,
      length: json['length'] as String?,
      wordCountArabic: json['word_count_arabic'] as int?,
      repetitions: json['repetitions'] as int? ?? 1,
      priority: json['priority'] as int? ?? 5,
      frequency: json['frequency'] as String?,
      displayContext: json['display_context'] != null
          ? DisplayContext.fromJson(
              json['display_context'] as Map<String, dynamic>,
            )
          : null,
      authenticity: json['authenticity'] != null
          ? Authenticity.fromJson(json['authenticity'] as Map<String, dynamic>)
          : null,
      benefits: json['benefits'] as String?,
      notes: json['notes'] as String?,
    );
  }
}

class DisplayContext {
  final List<String> timeWindows;
  final List<String> hijriPeriods;
  final List<String> conditions;
  final List<String> daysOfWeek;

  const DisplayContext({
    this.timeWindows = const [],
    this.hijriPeriods = const [],
    this.conditions = const [],
    this.daysOfWeek = const [],
  });

  factory DisplayContext.fromJson(Map<String, dynamic> json) {
    return DisplayContext(
      timeWindows:
          (json['time_windows'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      hijriPeriods:
          (json['hijri_periods'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      conditions:
          (json['conditions'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      daysOfWeek:
          (json['days_of_week'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
    );
  }
}

class Authenticity {
  final String? grade;
  final String? origin;
  final String? sourceHadith;
  final String? sourceQuran;

  const Authenticity({
    this.grade,
    this.origin,
    this.sourceHadith,
    this.sourceQuran,
  });

  factory Authenticity.fromJson(Map<String, dynamic> json) {
    return Authenticity(
      grade: json['grade'] as String?,
      origin: json['origin'] as String?,
      sourceHadith: json['source_hadith'] as String?,
      sourceQuran: json['source_quran'] as String?,
    );
  }
}
