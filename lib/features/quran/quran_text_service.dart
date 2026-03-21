import 'package:flutter/services.dart';

class QuranChapter {
  const QuranChapter({
    required this.number,
    required this.title,
    required this.transliteration,
    required this.verses,
  });

  final int number;
  final String title;
  final String transliteration;
  final List<String> verses;

  String get shortLabel => '$number. $title';
}

/// Service for loading and structuring the Qur'an text from assets.
class QuranTextService {
  String? _fullText;
  List<QuranChapter>? _cachedChapters;

  Future<void> _load() async {
    if (_fullText != null) return;
    _fullText = await rootBundle.loadString('assets/quran.txt');
  }

  Future<String> getFullText() async {
    await _load();
    return _fullText ?? '';
  }

  Future<List<QuranChapter>> getChapters() async {
    if (_cachedChapters != null) return _cachedChapters!;

    final text = await getFullText();
    final lines = text.split('\n');

    final inlineHeading = RegExp(
      r'^\s*(\d{1,3})\.\s+([^(]+?)\s*\(([^)]+)\)\s*$',
    );
    final headingLine = RegExp(r'^\s*(\d{1,3})\.\s+(.+)$');
    final parenLine = RegExp(r'^\s*\(([^)]+)\)\s*$');

    final occurrences = <int, List<_Heading>>{};

    for (var i = 0; i < lines.length; i++) {
      final line = lines[i].trim();
      if (line.isEmpty) continue;

      final inlineMatch = inlineHeading.firstMatch(line);
      if (inlineMatch != null) {
        final number = int.tryParse(inlineMatch.group(1) ?? '');
        if (number != null) {
          occurrences
              .putIfAbsent(number, () => [])
              .add(
                _Heading(
                  number: number,
                  title: inlineMatch.group(2)!.trim(),
                  transliteration: inlineMatch.group(3)!.trim(),
                  lineIndex: i,
                  contentStart: i + 1,
                ),
              );
        }
        continue;
      }

      final headingMatch = headingLine.firstMatch(line);
      if (headingMatch != null && i + 1 < lines.length) {
        final parenMatch = parenLine.firstMatch(lines[i + 1].trim());
        final number = int.tryParse(headingMatch.group(1) ?? '');
        if (parenMatch != null && number != null) {
          occurrences
              .putIfAbsent(number, () => [])
              .add(
                _Heading(
                  number: number,
                  title: headingMatch.group(2)!.trim(),
                  transliteration: parenMatch.group(1)!.trim(),
                  lineIndex: i,
                  contentStart: i + 2,
                ),
              );
          i++; // Skip the transliteration line.
        }
      }
    }

    final headings = <_Heading>[];
    const totalChapters = 114;
    for (var n = 1; n <= totalChapters; n++) {
      final options = occurrences[n];
      if (options == null || options.isEmpty) continue;
      options.sort((a, b) => a.lineIndex.compareTo(b.lineIndex));
      final selected = options.firstWhere(
        (opt) => _hasVerseOneAhead(lines, opt.contentStart),
        orElse: () => options.first,
      );
      headings.add(selected);
    }

    final chapters = <QuranChapter>[];
    for (var i = 0; i < headings.length; i++) {
      final start = headings[i].contentStart;
      final end = i + 1 < headings.length
          ? headings[i + 1].lineIndex
          : lines.length;
      final verses = _parseVerses(
        lines.sublist(start, end),
        headings[i].number,
      );
      chapters.add(
        QuranChapter(
          number: headings[i].number,
          title: headings[i].title,
          transliteration: headings[i].transliteration,
          verses: verses,
        ),
      );
    }

    _cachedChapters = chapters;
    return chapters;
  }

  List<String> _parseVerses(List<String> lines, int surahNumber) {
    final verses = <String>[];
    final versePattern = RegExp(r'^(\d{1,3})\.\s*(.*)$');
    final pageMarker = RegExp(r'^\d{1,3}$');
    final headerInline = RegExp(
      '^$surahNumber\\.\\s+[^()]+\\([^)]*\\)\$',
    ); // e.g. "2. THE HEIFER (al-Baqarah)"
    final headerSimple = RegExp(
      '^$surahNumber\\.\\s+[A-Z \\-]+\$',
    ); // e.g. "1. THE OPENING"
    final parenLine = RegExp(r'^\([^)]*\)$');
    String? current;

    for (var i = 0; i < lines.length; i++) {
      final raw = lines[i].trim();
      if (raw.isEmpty || pageMarker.hasMatch(raw)) continue;

      final isHeader =
          headerInline.hasMatch(raw) ||
          (raw.startsWith('$surahNumber.') && headerSimple.hasMatch(raw));
      if (isHeader) {
        if (i + 1 < lines.length && parenLine.hasMatch(lines[i + 1].trim())) {
          i++; // Skip the transliteration line too.
        }
        continue;
      }

      final verseMatch = versePattern.firstMatch(raw);
      if (verseMatch != null) {
        if (current != null) verses.add(current.trim());
        final number = verseMatch.group(1) ?? '';
        final content = verseMatch.group(2) ?? '';
        current = '$number. ${content.trim()}';
        continue;
      }

      if (current != null) {
        current = '$current ${raw.trim()}';
      } else {
        // Some introductions (e.g. Bismillah) do not carry a verse number.
        current = raw.trim();
      }
    }

    if (current != null) verses.add(current.trim());
    return verses;
  }

  bool _hasVerseOneAhead(List<String> lines, int startIndex) {
    final verseOne = RegExp(r'^1\.\s');
    final pageMarker = RegExp(r'^\d{1,3}$');
    for (var i = startIndex; i < lines.length && i < startIndex + 20; i++) {
      final raw = lines[i].trim();
      if (raw.isEmpty || pageMarker.hasMatch(raw)) continue;
      if (verseOne.hasMatch(raw)) return true;
    }
    return false;
  }
}

class _Heading {
  const _Heading({
    required this.number,
    required this.title,
    required this.transliteration,
    required this.lineIndex,
    required this.contentStart,
  });

  final int number;
  final String title;
  final String transliteration;
  final int lineIndex;
  final int contentStart;
}
