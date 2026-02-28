import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'quran_text_service.dart';
import 'juz_mapping.dart';
import '../../shared/app_colors.dart';
import '../../shared/glass_container.dart';

/// Displays the chapters and verses that belong to a single Juz.
class JuzPage extends StatefulWidget {
  const JuzPage({super.key, required this.boundary});

  final JuzBoundary boundary;

  @override
  State<JuzPage> createState() => _JuzPageState();
}

class _JuzPageState extends State<JuzPage> {
  final QuranTextService _service = QuranTextService();
  List<_JuzChapterSlice> _slices = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final chapters = await _service.getChapters();
    if (!mounted) return;

    final b = widget.boundary;
    final slices = <_JuzChapterSlice>[];

    for (final chapter in chapters) {
      if (chapter.number < b.startSurah || chapter.number > b.endSurah) {
        continue;
      }

      // Determine which verses to include from this chapter.
      int startVerse = 0; // 0-indexed into the verses list
      int endVerse = chapter.verses.length; // exclusive

      if (chapter.number == b.startSurah) {
        startVerse = _findVerseIndex(chapter.verses, b.startAyah);
      }
      if (chapter.number == b.endSurah) {
        endVerse = _findVerseIndex(chapter.verses, b.endAyah) + 1;
      }

      if (startVerse >= endVerse) continue;

      slices.add(
        _JuzChapterSlice(
          chapter: chapter,
          verses: chapter.verses.sublist(
            startVerse.clamp(0, chapter.verses.length),
            endVerse.clamp(0, chapter.verses.length),
          ),
        ),
      );
    }

    setState(() {
      _slices = slices;
      _loading = false;
    });
  }

  /// Finds the 0-based index of the verse whose number matches [ayahNumber].
  /// Falls back to 0 or end if not found.
  int _findVerseIndex(List<String> verses, int ayahNumber) {
    final prefix = '$ayahNumber. ';
    for (int i = 0; i < verses.length; i++) {
      if (verses[i].startsWith(prefix)) return i;
    }
    // If the exact ayah number isn't found (e.g. Bismillah line), return 0.
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(
          'Juz ${widget.boundary.juz}',
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: _loading
          ? Center(child: CircularProgressIndicator(color: AppColors.accent))
          : SafeArea(
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                itemCount: _slices.length,
                itemBuilder: (context, index) {
                  final slice = _slices[index];
                  return _SliceCard(slice: slice);
                },
              ),
            ),
    );
  }
}

class _JuzChapterSlice {
  const _JuzChapterSlice({required this.chapter, required this.verses});

  final QuranChapter chapter;
  final List<String> verses;
}

class _SliceCard extends StatelessWidget {
  const _SliceCard({required this.slice});

  final _JuzChapterSlice slice;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: GlassContainer(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Chapter header
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.accent.withValues(alpha: 0.1),
                    border: Border.all(
                      color: AppColors.accent.withValues(alpha: 0.3),
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    slice.chapter.number.toString(),
                    style: GoogleFonts.plusJakartaSans(
                      fontWeight: FontWeight.bold,
                      color: AppColors.accent,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        slice.chapter.title,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        slice.chapter.transliteration,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Verses
            ListView.separated(
              physics: const NeverScrollableScrollPhysics(),
              shrinkWrap: true,
              itemCount: slice.verses.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (_, verseIndex) => SelectableText(
                slice.verses[verseIndex],
                textAlign: TextAlign.right,
                style: const TextStyle(
                  fontFamily: 'Amiri',
                  fontSize: 22,
                  height: 2.0,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
