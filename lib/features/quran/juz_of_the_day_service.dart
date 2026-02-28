// Juz of the Day calculation service.
//
// Supports two modes:
// - [JuzMode.standard] – Traditional 30-part division (fixed surah+verse boundaries).
// - [JuzMode.surahBased] – Groups whole surahs into 30 roughly-equal parts.

import 'package:hijri/hijri_calendar.dart';
import 'quran_text_service.dart';

enum JuzMode { standard, surahBased }

/// A contiguous range within a single surah that belongs to a Juz.
class JuzRange {
  const JuzRange({required this.surahNumber, this.startVerse, this.endVerse});

  final int surahNumber;

  /// Null means "from the beginning" / "to the end" (i.e. the whole surah
  /// is included, or the range extends to / from the boundary of the surah).
  final int? startVerse;
  final int? endVerse;

  /// Whether this range covers the entire surah.
  bool get isFullSurah => startVerse == null && endVerse == null;
}

/// Resolved information for today's Juz.
class JuzInfo {
  const JuzInfo({
    required this.juzNumber,
    required this.mode,
    required this.ranges,
  });

  final int juzNumber;
  final JuzMode mode;
  final List<JuzRange> ranges;

  /// Human-readable summary, e.g. "Surahs 1 – 2" or "Al-Fatiha – Al-Baqara".
  String summary(List<QuranChapter> chapters) {
    if (ranges.isEmpty) return '';
    final firstSurah = ranges.first.surahNumber;
    final lastSurah = ranges.last.surahNumber;

    String nameOf(int n) {
      final ch = chapters.where((c) => c.number == n).firstOrNull;
      return ch?.transliteration ?? 'Surah $n';
    }

    if (firstSurah == lastSurah) return nameOf(firstSurah);
    return '${nameOf(firstSurah)} – ${nameOf(lastSurah)}';
  }
}

class JuzOfTheDayService {
  /// Returns the Juz number (1–30) for today.
  ///
  /// During Ramadan the traditional khatm assigns Juz [n] to day [n], so we
  /// use the Hijri day-of-month directly (1 Ramadan = Juz 1, 8 Ramadan = Juz 8,
  /// etc.).  Outside Ramadan we fall back to a rotating cycle based on the Hijri
  /// day-of-month clamped to 1–30, keeping the Quran page useful year-round.
  int juzNumberForToday() {
    final hijri = HijriCalendar.now();
    // hDay is already 1–30, which maps perfectly to the 30 Juz.
    return hijri.hDay.clamp(1, 30);
  }

  /// Build [JuzInfo] for the given [juzNumber] and [mode].
  JuzInfo getJuz(int juzNumber, JuzMode mode) {
    assert(juzNumber >= 1 && juzNumber <= 30);
    final ranges = mode == JuzMode.standard
        ? _standardJuzRanges(juzNumber)
        : _surahBasedRanges(juzNumber);
    return JuzInfo(juzNumber: juzNumber, mode: mode, ranges: ranges);
  }

  /// Convenience: Juz for today.
  JuzInfo getJuzForToday(JuzMode mode) => getJuz(juzNumberForToday(), mode);

  /// Filter the full chapter list to only those that appear in [juz].
  List<QuranChapter> filterChapters(List<QuranChapter> chapters, JuzInfo juz) {
    final surahNumbers = juz.ranges.map((r) => r.surahNumber).toSet();
    return chapters.where((c) => surahNumbers.contains(c.number)).toList();
  }

  // ---------------------------------------------------------------------------
  // Standard 30-Juz boundaries (traditional)
  // Each entry: [startSurah, startVerse, endSurah, endVerse]
  // ---------------------------------------------------------------------------
  static const _standardBoundaries = <List<int>>[
    [1, 1, 2, 141], // Juz 1
    [2, 142, 2, 252], // Juz 2
    [2, 253, 3, 92], // Juz 3
    [3, 93, 4, 23], // Juz 4
    [4, 24, 4, 147], // Juz 5
    [4, 148, 5, 81], // Juz 6
    [5, 82, 6, 110], // Juz 7
    [6, 111, 7, 87], // Juz 8
    [7, 88, 8, 40], // Juz 9
    [8, 41, 9, 92], // Juz 10
    [9, 93, 11, 5], // Juz 11
    [11, 6, 12, 52], // Juz 12
    [12, 53, 14, 52], // Juz 13
    [15, 1, 16, 128], // Juz 14
    [17, 1, 18, 74], // Juz 15
    [18, 75, 20, 135], // Juz 16
    [21, 1, 22, 78], // Juz 17
    [23, 1, 25, 20], // Juz 18
    [25, 21, 27, 55], // Juz 19
    [27, 56, 29, 45], // Juz 20
    [29, 46, 33, 30], // Juz 21
    [33, 31, 36, 27], // Juz 22
    [36, 28, 39, 31], // Juz 23
    [39, 32, 41, 46], // Juz 24
    [41, 47, 45, 37], // Juz 25
    [46, 1, 51, 30], // Juz 26
    [51, 31, 57, 29], // Juz 27
    [58, 1, 66, 12], // Juz 28
    [67, 1, 77, 50], // Juz 29
    [78, 1, 114, 6], // Juz 30
  ];

  List<JuzRange> _standardJuzRanges(int juzNumber) {
    final b = _standardBoundaries[juzNumber - 1];
    final startSurah = b[0];
    final startVerse = b[1];
    final endSurah = b[2];
    final endVerse = b[3];

    final ranges = <JuzRange>[];
    for (var s = startSurah; s <= endSurah; s++) {
      ranges.add(
        JuzRange(
          surahNumber: s,
          startVerse: s == startSurah ? startVerse : null,
          endVerse: s == endSurah ? endVerse : null,
        ),
      );
    }
    return ranges;
  }

  // ---------------------------------------------------------------------------
  // Surah-based: split 114 surahs into 30 groups of whole surahs.
  // ---------------------------------------------------------------------------
  List<JuzRange> _surahBasedRanges(int juzNumber) {
    const totalSurahs = 114;
    const totalGroups = 30;
    const baseSize = totalSurahs ~/ totalGroups; // 3
    const remainder = totalSurahs % totalGroups; // 24

    // First `remainder` groups get baseSize+1, the rest get baseSize.
    int startSurah = 1;
    for (var g = 1; g < juzNumber; g++) {
      startSurah += (g <= remainder) ? baseSize + 1 : baseSize;
    }
    final groupSize = (juzNumber <= remainder) ? baseSize + 1 : baseSize;

    final ranges = <JuzRange>[];
    for (var s = startSurah; s < startSurah + groupSize; s++) {
      ranges.add(JuzRange(surahNumber: s));
    }
    return ranges;
  }
}
