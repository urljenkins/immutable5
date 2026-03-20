import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';

import '../../shared/app_colors.dart';
import '../../shared/glass_container.dart';
import 'juz_mapping.dart';
import 'quran_bookmark_service.dart';
import 'quran_context_menu_settings.dart';
import 'quran_text_service.dart';

/// Displays the chapters and verses that belong to a single Juz.
class JuzPage extends StatefulWidget {
  const JuzPage({super.key, required this.boundary});

  final JuzBoundary boundary;

  @override
  State<JuzPage> createState() => _JuzPageState();
}

class _JuzPageState extends State<JuzPage> {
  final QuranTextService _service = QuranTextService();
  final _bookmarks = QuranBookmarkService.instance;
  List<_JuzChapterSlice> _slices = [];
  QuranContextMenuSettings _ctxSettings = const QuranContextMenuSettings();
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final chapters = await _service.getChapters();
    final ctxSettings = await QuranContextMenuSettings.fromPrefs();
    await _bookmarks.load();
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
          startVerseIndex: startVerse,
          verses: chapter.verses.sublist(
            startVerse.clamp(0, chapter.verses.length),
            endVerse.clamp(0, chapter.verses.length),
          ),
        ),
      );
    }

    setState(() {
      _slices = slices;
      _ctxSettings = ctxSettings;
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
                  return _SliceCard(
                    slice: slice,
                    bookmarks: _bookmarks,
                    ctxSettings: _ctxSettings,
                    onLongPressVerse: (globalVerseIndex) =>
                        _showVerseContextMenu(
                      context,
                      chapter: slice.chapter,
                      verseIndex: globalVerseIndex,
                    ),
                  );
                },
              ),
            ),
    );
  }

  // ── Context menu ────────────────────────────────────────────────────────────

  void _showVerseContextMenu(
    BuildContext context, {
    required QuranChapter chapter,
    required int verseIndex,
  }) {
    final verse = chapter.verses[verseIndex];
    final isBookmarked = _bookmarks.isBookmarked(chapter.number, verseIndex);

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) {
        return ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: ColoredBox(
              color: AppColors.cardSurface.withValues(alpha: 0.95),
              child: SafeArea(
                top: false,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(height: 12),
                    // Handle bar
                    Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Verse preview
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 8,
                      ),
                      child: Text(
                        '${chapter.title} · Verse ${verseIndex + 1}',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.accent,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    Divider(
                      color: AppColors.textSecondary.withValues(alpha: 0.15),
                      height: 1,
                    ),
                    if (_ctxSettings.showCopy)
                      _ContextMenuItem(
                        icon: Icons.copy_rounded,
                        label: 'Copy verse',
                        onTap: () {
                          Navigator.pop(sheetCtx);
                          Clipboard.setData(ClipboardData(text: verse));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Verse copied to clipboard'),
                              duration: Duration(seconds: 2),
                            ),
                          );
                        },
                      ),
                    if (_ctxSettings.showBookmark)
                      _ContextMenuItem(
                        icon: isBookmarked
                            ? Icons.bookmark_rounded
                            : Icons.bookmark_add_outlined,
                        label:
                            isBookmarked ? 'Remove bookmark' : 'Bookmark verse',
                        iconColor: isBookmarked ? AppColors.accent : null,
                        onTap: () async {
                          Navigator.pop(sheetCtx);
                          final messenger = ScaffoldMessenger.of(context);
                          final added = await _bookmarks.toggle(
                            QuranBookmark(
                              surahNumber: chapter.number,
                              surahTitle: chapter.title,
                              verseIndex: verseIndex,
                              verseText: verse,
                              savedAt: DateTime.now(),
                            ),
                          );
                          messenger.showSnackBar(
                            SnackBar(
                              content: Text(
                                added ? 'Verse bookmarked' : 'Bookmark removed',
                              ),
                              duration: const Duration(seconds: 2),
                            ),
                          );
                        },
                      ),
                    if (_ctxSettings.showShare)
                      _ContextMenuItem(
                        icon: Icons.share_rounded,
                        label: 'Share verse',
                        onTap: () {
                          Navigator.pop(sheetCtx);
                          Share.share(
                            '$verse\n\n— ${chapter.title}, Verse ${verseIndex + 1}',
                          );
                        },
                      ),
                    if (_ctxSettings.showAyahInfo)
                      _ContextMenuItem(
                        icon: Icons.info_outline_rounded,
                        label: 'Ayah info',
                        onTap: () {
                          Navigator.pop(sheetCtx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Surah ${chapter.number} (${chapter.transliteration})'
                                ' · Verse ${verseIndex + 1} of ${chapter.verses.length}',
                              ),
                              duration: const Duration(seconds: 3),
                            ),
                          );
                        },
                      ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

// ── Context menu item ─────────────────────────────────────────────────────────

class _ContextMenuItem extends StatelessWidget {
  const _ContextMenuItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.iconColor,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        child: Row(
          children: [
            Icon(icon, color: iconColor ?? AppColors.textSecondary, size: 22),
            const SizedBox(width: 16),
            Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 15,
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _JuzChapterSlice {
  const _JuzChapterSlice({
    required this.chapter,
    required this.startVerseIndex,
    required this.verses,
  });

  final QuranChapter chapter;
  final int startVerseIndex;
  final List<String> verses;
}

class _SliceCard extends StatelessWidget {
  const _SliceCard({
    required this.slice,
    required this.bookmarks,
    required this.ctxSettings,
    required this.onLongPressVerse,
  });

  final _JuzChapterSlice slice;
  final QuranBookmarkService bookmarks;
  final QuranContextMenuSettings ctxSettings;
  final void Function(int globalVerseIndex) onLongPressVerse;

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
              itemBuilder: (_, localVerseIndex) {
                final globalVerseIndex =
                    slice.startVerseIndex + localVerseIndex;
                return ValueListenableBuilder<List<QuranBookmark>>(
                  valueListenable: bookmarks.bookmarks,
                  builder: (_, bms, __) {
                    final isBookmarked = bms.any(
                      (b) =>
                          b.surahNumber == slice.chapter.number &&
                          b.verseIndex == globalVerseIndex,
                    );

                    BoxDecoration? decoration;
                    if (isBookmarked) {
                      decoration = BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        color: AppColors.accent.withValues(alpha: 0.07),
                        border: Border.all(
                          color: AppColors.accent.withValues(alpha: 0.2),
                        ),
                      );
                    }

                    return GestureDetector(
                      onLongPress: () => onLongPressVerse(globalVerseIndex),
                      child: Container(
                        decoration: decoration,
                        padding: isBookmarked
                            ? const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              )
                            : EdgeInsets.zero,
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: SelectableText(
                                slice.verses[localVerseIndex],
                                textAlign: TextAlign.right,
                                style: const TextStyle(
                                  fontFamily: 'Amiri',
                                  fontSize: 22,
                                  height: 2.0,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ),
                            if (isBookmarked)
                              Padding(
                                padding: const EdgeInsets.only(left: 6, top: 6),
                                child: Icon(
                                  Icons.bookmark_rounded,
                                  color: AppColors.accent,
                                  size: 16,
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
