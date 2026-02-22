import 'dart:convert';

class Dua {
  final String id;
  final String source;
  final String license;
  final String schemaVersion;
  final String? category;
  final String? occasion;
  final List<String> tags;
  final String arabic;
  final String transliteration;
  final String translationEn;
  final Map<String, String>? translations;
  final String? length;
  final int? wordCountArabic;
  final int repetitions;
  final int? priority;
  final String? frequency;
  final DisplayContext? displayContext;
  final Authenticity? authenticity;
  final String? benefits;
  final String? notes;
  final List<String>? relatedIds;
  final List<DuaVariant>? variants;
  final AudioRef? audio;

  const Dua({
    required this.id,
    required this.source,
    required this.license,
    required this.schemaVersion,
    required this.tags,
    required this.arabic,
    required this.transliteration,
    required this.translationEn,
    this.category,
    this.occasion,
    this.translations,
    this.length,
    this.wordCountArabic,
    this.repetitions = 1,
    this.priority,
    this.frequency,
    this.displayContext,
    this.authenticity,
    this.benefits,
    this.notes,
    this.relatedIds,
    this.variants,
    this.audio,
  });

  String get categoryLabel =>
      category ?? (tags.isNotEmpty ? tags.first : 'Uncategorized');

  String get shareText =>
      '$arabic\n\n$transliteration\n\n$translationEn';

  factory Dua.fromJson(Map<String, dynamic> json) {
    return Dua(
      id: json['id'] as String,
      source: json['source'] as String,
      license: json['license'] as String,
      schemaVersion: json['schema_version'] as String,
      category: json['category'] as String?,
      occasion: json['occasion'] as String?,
      tags: (json['tags'] as List<dynamic>).cast<String>(),
      arabic: json['arabic'] as String,
      transliteration: json['transliteration'] as String,
      translationEn: json['translation_en'] as String,
      translations: (json['translations'] as Map?)?.map(
        (key, value) => MapEntry(key.toString(), value.toString()),
      ),
      length: json['length'] as String?,
      wordCountArabic: json['word_count_arabic'] as int?,
      repetitions: (json['repetitions'] as num?)?.toInt() ?? 1,
      priority: (json['priority'] as num?)?.toInt(),
      frequency: json['frequency'] as String?,
      displayContext: json['display_context'] != null
          ? DisplayContext.fromJson(
              json['display_context'] as Map<String, dynamic>)
          : null,
      authenticity: json['authenticity'] != null
          ? Authenticity.fromJson(
              json['authenticity'] as Map<String, dynamic>)
          : null,
      benefits: json['benefits'] as String?,
      notes: json['notes'] as String?,
      relatedIds: (json['related_ids'] as List?)?.map((e) => e.toString()).toList(),
      variants: (json['variants'] as List?)
          ?.map((e) => DuaVariant.fromJson(e as Map<String, dynamic>))
          .toList(),
      audio: json['audio'] != null
          ? AudioRef.fromJson(json['audio'] as Map<String, dynamic>)
          : null,
    );
  }

  static List<Dua> listFromJsonString(String jsonString) {
    final decoded = json.decode(jsonString) as List<dynamic>;
    return decoded
        .map((entry) => Dua.fromJson(entry as Map<String, dynamic>))
        .toList();
  }
}

class DisplayContext {
  final List<String> timeWindows;
  final List<HijriDate> hijriDates;
  final List<String> hijriPeriods;
  final List<String> conditions;
  final List<String> daysOfWeek;

  const DisplayContext({
    this.timeWindows = const [],
    this.hijriDates = const [],
    this.hijriPeriods = const [],
    this.conditions = const [],
    this.daysOfWeek = const [],
  });

  factory DisplayContext.fromJson(Map<String, dynamic> json) {
    return DisplayContext(
      timeWindows:
          (json['time_windows'] as List?)?.map((e) => e.toString()).toList() ??
              const [],
      hijriDates: (json['hijri_dates'] as List?)
              ?.map((e) => HijriDate.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      hijriPeriods:
          (json['hijri_periods'] as List?)?.map((e) => e.toString()).toList() ??
              const [],
      conditions:
          (json['conditions'] as List?)?.map((e) => e.toString()).toList() ??
              const [],
      daysOfWeek:
          (json['days_of_week'] as List?)?.map((e) => e.toString()).toList() ??
              const [],
    );
  }
}

class HijriDate {
  final int month;
  final int day;
  final bool recurring;

  const HijriDate({
    required this.month,
    required this.day,
    this.recurring = true,
  });

  factory HijriDate.fromJson(Map<String, dynamic> json) {
    return HijriDate(
      month: (json['month'] as num).toInt(),
      day: (json['day'] as num).toInt(),
      recurring: json['recurring'] as bool? ?? true,
    );
  }
}

class Authenticity {
  final String grade;
  final String? origin;
  final String? sourceHadith;
  final String? sourceQuran;
  final String? narrator;
  final List<String>? additionalReferences;
  final String? scholarlyNotes;

  const Authenticity({
    required this.grade,
    this.origin,
    this.sourceHadith,
    this.sourceQuran,
    this.narrator,
    this.additionalReferences,
    this.scholarlyNotes,
  });

  factory Authenticity.fromJson(Map<String, dynamic> json) {
    return Authenticity(
      grade: json['grade'] as String,
      origin: json['origin'] as String?,
      sourceHadith: json['source_hadith'] as String?,
      sourceQuran: json['source_quran'] as String?,
      narrator: json['narrator'] as String?,
      additionalReferences: (json['additional_references'] as List?)
          ?.map((e) => e.toString())
          .toList(),
      scholarlyNotes: json['scholarly_notes'] as String?,
    );
  }
}

class DuaVariant {
  final String arabic;
  final String transliteration;
  final String translationEn;
  final String source;
  final String? note;

  const DuaVariant({
    required this.arabic,
    required this.transliteration,
    required this.translationEn,
    required this.source,
    this.note,
  });

  factory DuaVariant.fromJson(Map<String, dynamic> json) {
    return DuaVariant(
      arabic: json['arabic'] as String,
      transliteration: json['transliteration'] as String,
      translationEn: json['translation_en'] as String,
      source: json['source'] as String,
      note: json['note'] as String?,
    );
  }
}

class AudioRef {
  final String? url;
  final String? localPath;
  final int? durationSeconds;
  final String? reciter;
  final String? license;

  const AudioRef({
    this.url,
    this.localPath,
    this.durationSeconds,
    this.reciter,
    this.license,
  });

  factory AudioRef.fromJson(Map<String, dynamic> json) {
    return AudioRef(
      url: json['url'] as String?,
      localPath: json['local_path'] as String?,
      durationSeconds: (json['duration_seconds'] as num?)?.toInt(),
      reciter: json['reciter'] as String?,
      license: json['license'] as String?,
    );
  }
}
