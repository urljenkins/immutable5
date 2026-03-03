import 'dart:ui';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:immutable5/services/secure_storage_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

import '../../shared/app_colors.dart';
import '../../shared/glass_container.dart';
import 'juz_of_the_day_service.dart';
import 'quran_audio_service.dart';
import 'quran_bookmark_service.dart';
import 'quran_context_menu_settings.dart';
import 'quran_text_service.dart';

/// A structured Qur'an reader with chapter navigation, bookmarking,
/// and a customisable long-press context menu per verse.
class QuranPage extends StatefulWidget {
  const QuranPage({super.key});

  @override
  State<QuranPage> createState() => _QuranPageState();
}

class _QuranPageState extends State<QuranPage> {
  final QuranTextService _service = QuranTextService();
  final JuzOfTheDayService _juzService = JuzOfTheDayService();
  final QuranAudioService _audioService = QuranAudioService();
  final _bookmarks = QuranBookmarkService.instance;
  final ItemScrollController _itemScrollController = ItemScrollController();
  final Map<int, GlobalKey> _chapterKeys = {};
  // Per-verse keys: key = surahNumber * 10000 + verseIndex
  final Map<int, GlobalKey> _verseKeys = {};
  final AudioPlayer _audioPlayer = AudioPlayer();

  List<QuranChapter> _chapters = [];
  JuzInfo? _todayJuz;
  QuranContextMenuSettings _ctxSettings = const QuranContextMenuSettings();
  bool _loading = true;

  // Audio State
  String _currentReciterId = 'ar.alafasy';
  int? _playingSurah;
  int? _playingVerse;
  bool _isPlaying = false;
  bool _isAudioLoading = false;
  List<String> _audioUrls = [];

  @override
  void initState() {
    super.initState();
    _load();
    _audioPlayer.onPlayerComplete.listen((_) => _onPlayerComplete());
  }

  Future<void> _load() async {
    final chapters = await _service.getChapters();
    final prefs = SecureStorageProvider();
    final savedMode = await prefs.getString('juzMode');
    final savedReciter = await prefs.getString('quran_reciter_id');
    final mode =
        savedMode == 'surahBased' ? JuzMode.surahBased : JuzMode.standard;
    final todayJuz = _juzService.getJuzForToday(mode);
    final ctxSettings = await QuranContextMenuSettings.fromPrefs(prefs);
    await _bookmarks.load();
    if (!mounted) return;
    setState(() {
      _chapterKeys.clear();
      _verseKeys.clear();
      _chapters = List.of(chapters)
        ..sort((a, b) => a.number.compareTo(b.number));
      for (final chapter in _chapters) {
        _chapterKeys[chapter.number] = GlobalKey();
        for (var i = 0; i < chapter.verses.length; i++) {
          _verseKeys[chapter.number * 10000 + i] = GlobalKey();
        }
      }
      _todayJuz = todayJuz;
      _ctxSettings = ctxSettings;
      if (savedReciter != null) {
        _currentReciterId = savedReciter;
      }
      _loading = false;
    });
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  // ── Audio Logic ─────────────────────────────────────────────────────────────

  Future<void> _changeReciter(String reciterId) async {
    if (_currentReciterId == reciterId) return;

    // Stop current playback if any
    await _stopAudio();

    setState(() {
      _currentReciterId = reciterId;
      _audioUrls = []; // Clear cached URLs as reciter changed
    });

    final prefs = SecureStorageProvider();
    await prefs.setString('quran_reciter_id', reciterId);
  }

  Future<void> _playVerse(int surah, int verse) async {
    // If playing same verse, do nothing
    if (_playingSurah == surah && _playingVerse == verse && _isPlaying) return;

    // If changing surah, we need to fetch URLs if not already available
    if (_playingSurah != surah || _audioUrls.isEmpty) {
      setState(() {
        _isAudioLoading = true;
        _playingSurah = surah;
        _playingVerse = verse;
        _isPlaying = false;
      });

      try {
        final urls = await _audioService.getSurahAudioData(
          surah,
          _currentReciterId,
        );
        if (!mounted) return;
        // Check race condition: if playingSurah changed while awaiting, discard this result
        if (_playingSurah != surah) return;

        setState(() {
          _audioUrls = urls;
          _isAudioLoading = false;
        });
      } catch (e) {
        if (!mounted) return;
        setState(() {
          _isAudioLoading = false;
          _playingSurah = null;
          _playingVerse = null;
        });
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to load audio: $e')));
        return;
      }
    }

    if (verse >= _audioUrls.length) {
      _stopAudio();
      return;
    }

    try {
      await _audioPlayer.play(UrlSource(_audioUrls[verse]));
      setState(() {
        _playingSurah = surah;
        _playingVerse = verse;
        _isPlaying = true;
      });
      _scrollToVerse(surah, verse);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error playing audio: $e')));
    }
  }

  Future<void> _togglePlay(int surah) async {
    if (_playingSurah == surah) {
      if (_isPlaying) {
        await _audioPlayer.pause();
        setState(() => _isPlaying = false);
      } else {
        await _audioPlayer.resume();
        setState(() => _isPlaying = true);
      }
    } else {
      // Start from beginning of Surah
      await _playVerse(surah, 0);
    }
  }

  Future<void> _stopAudio() async {
    await _audioPlayer.stop();
    setState(() {
      _isPlaying = false;
      _playingSurah = null;
      _playingVerse = null;
    });
  }

  void _onPlayerComplete() {
    if (_playingSurah != null && _playingVerse != null) {
      final nextVerse = _playingVerse! + 1;
      // Check if we have more verses in this surah
      if (_audioUrls.isNotEmpty && nextVerse < _audioUrls.length) {
        _playVerse(_playingSurah!, nextVerse);
      } else {
        // End of Surah
        setState(() {
          _isPlaying = false;
          _playingVerse = null;
          // Keep playingSurah to show we are still "on" this surah, or reset?
          // Resetting feels cleaner.
          _playingSurah = null;
        });
      }
    }
  }

  Future<void> _scrollToVerse(int surah, int verse) async {
    final key = _verseKeys[surah * 10000 + verse];
    if (key?.currentContext != null) {
      await Scrollable.ensureVisible(
        key!.currentContext!,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        alignment: 0.3, // Position somewhat near top
      );
    }
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
            child: Container(
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
                    // Play verse option
                    _ContextMenuItem(
                      icon: Icons.play_arrow_rounded,
                      label: 'Play from here',
                      onTap: () {
                        Navigator.pop(sheetCtx);
                        _playVerse(chapter.number, verseIndex);
                      },
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

  // ── Bookmarks bottom-sheet ──────────────────────────────────────────────────

  void _openBookmarks() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetCtx) {
        return ValueListenableBuilder<List<QuranBookmark>>(
          valueListenable: _bookmarks.bookmarks,
          builder: (_, list, __) {
            return ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(24),
              ),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  color: AppColors.cardSurface.withValues(alpha: 0.95),
                  height: MediaQuery.of(context).size.height * 0.6,
                  child: SafeArea(
                    child: Column(
                      children: [
                        const SizedBox(height: 12),
                        Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Row(
                            children: [
                              Icon(
                                Icons.bookmark_rounded,
                                color: AppColors.accent,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Bookmarks',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const Spacer(),
                              if (list.isNotEmpty)
                                TextButton(
                                  onPressed: () async {
                                    final confirm = await showDialog<bool>(
                                      context: context,
                                      builder: (d) => AlertDialog(
                                        backgroundColor: AppColors.cardSurface,
                                        title: const Text(
                                          'Clear all bookmarks?',
                                        ),
                                        actions: [
                                          TextButton(
                                            onPressed: () =>
                                                Navigator.pop(d, false),
                                            child: const Text('Cancel'),
                                          ),
                                          TextButton(
                                            onPressed: () =>
                                                Navigator.pop(d, true),
                                            child: const Text(
                                              'Clear',
                                              style: TextStyle(
                                                color: AppColors.error,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                    if (confirm == true) {
                                      for (final b in List.of(
                                        _bookmarks.bookmarks.value,
                                      )) {
                                        await _bookmarks.remove(
                                          b.surahNumber,
                                          b.verseIndex,
                                        );
                                      }
                                    }
                                  },
                                  child: const Text(
                                    'Clear all',
                                    style: TextStyle(color: AppColors.error),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        if (list.isEmpty)
                          Expanded(
                            child: Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.bookmark_border_rounded,
                                    size: 48,
                                    color: AppColors.textSecondary.withValues(
                                      alpha: 0.5,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    'No bookmarks yet',
                                    style: GoogleFonts.plusJakartaSans(
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Long-press a verse to bookmark it',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 12,
                                      color: AppColors.textSecondary.withValues(
                                        alpha: 0.6,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                        else
                          Expanded(
                            child: ListView.separated(
                              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                              itemCount: list.length,
                              separatorBuilder: (_, __) => Divider(
                                color: AppColors.textSecondary.withValues(
                                  alpha: 0.1,
                                ),
                                height: 1,
                              ),
                              itemBuilder: (_, i) {
                                final bm = list[i];
                                return ListTile(
                                  contentPadding: EdgeInsets.zero,
                                  leading: Container(
                                    width: 36,
                                    height: 36,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: AppColors.accent.withValues(
                                        alpha: 0.1,
                                      ),
                                      border: Border.all(
                                        color: AppColors.accent.withValues(
                                          alpha: 0.3,
                                        ),
                                      ),
                                    ),
                                    alignment: Alignment.center,
                                    child: Icon(
                                      Icons.bookmark_rounded,
                                      color: AppColors.accent,
                                      size: 18,
                                    ),
                                  ),
                                  title: Text(
                                    '${bm.surahTitle} · Verse ${bm.verseIndex + 1}',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textPrimary,
                                      fontSize: 14,
                                    ),
                                  ),
                                  subtitle: Text(
                                    bm.verseText,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.plusJakartaSans(
                                      color: AppColors.textSecondary,
                                      fontSize: 12,
                                    ),
                                  ),
                                  trailing: IconButton(
                                    icon: const Icon(
                                      Icons.delete_outline,
                                      color: AppColors.textSecondary,
                                      size: 20,
                                    ),
                                    onPressed: () => _bookmarks.remove(
                                      bm.surahNumber,
                                      bm.verseIndex,
                                    ),
                                  ),
                                  onTap: () {
                                    Navigator.pop(sheetCtx);
                                    _scrollToChapter(
                                      _chapters.firstWhere(
                                        (c) => c.number == bm.surahNumber,
                                        orElse: () => _chapters.first,
                                      ),
                                    );
                                  },
                                );
                              },
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  // ── Chapter picker ──────────────────────────────────────────────────────────

  void _openChapterPicker() {
    if (_loading) return;
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) {
        return ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              color: AppColors.cardSurface.withValues(alpha: 0.9),
              height: MediaQuery.of(context).size.height * 0.7,
              child: SafeArea(
                child: Column(
                  children: [
                    const SizedBox(height: 12),
                    Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(
                        'Select Surah',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    Expanded(
                      child: ListView.separated(
                        itemCount: _chapters.length,
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                        separatorBuilder: (_, __) => Divider(
                          color: AppColors.textSecondary.withValues(alpha: 0.1),
                          height: 1,
                        ),
                        itemBuilder: (_, index) {
                          final chapter = _chapters[index];
                          return ListTile(
                            leading: Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppColors.accent.withValues(alpha: 0.1),
                                border: Border.all(
                                  color: AppColors.accent.withValues(
                                    alpha: 0.3,
                                  ),
                                ),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                chapter.number.toString(),
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.accent,
                                ),
                              ),
                            ),
                            title: Text(
                              chapter.title,
                              style: GoogleFonts.plusJakartaSans(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            subtitle: Text(
                              chapter.transliteration,
                              style: GoogleFonts.plusJakartaSans(
                                color: AppColors.textSecondary,
                                fontSize: 12,
                              ),
                            ),
                            onTap: () {
                              Navigator.of(sheetContext).pop();
                              _scrollToChapter(chapter);
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // ── Reciter picker ──────────────────────────────────────────────────────────

  void _openReciterPicker() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) {
        return ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              color: AppColors.cardSurface.withValues(alpha: 0.9),
              height: MediaQuery.of(context).size.height * 0.5,
              child: SafeArea(
                child: Column(
                  children: [
                    const SizedBox(height: 12),
                    Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(
                        'Select Reciter',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    Expanded(
                      child: ListView.separated(
                        itemCount: QuranAudioService.availableReciters.length,
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                        separatorBuilder: (_, __) => Divider(
                          color: AppColors.textSecondary.withValues(alpha: 0.1),
                          height: 1,
                        ),
                        itemBuilder: (_, index) {
                          final reciter =
                              QuranAudioService.availableReciters[index];
                          final isSelected = reciter.id == _currentReciterId;
                          return ListTile(
                            leading: isSelected
                                ? Icon(
                                    Icons.check,
                                    color: AppColors.accent,
                                  )
                                : const SizedBox(width: 24),
                            title: Text(
                              reciter.name,
                              style: GoogleFonts.plusJakartaSans(
                                color: isSelected
                                    ? AppColors.accent
                                    : AppColors.textPrimary,
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.w500,
                              ),
                            ),
                            onTap: () {
                              Navigator.of(sheetContext).pop();
                              _changeReciter(reciter.id);
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // ── Scroll helpers ──────────────────────────────────────────────────────────

  Future<void> _scrollToChapter(QuranChapter chapter) async {
    final index = _chapters.indexWhere((c) => c.number == chapter.number);
    if (index == -1) return;

    if (_itemScrollController.isAttached) {
      await _itemScrollController.scrollTo(
        index: index,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
        alignment: 0.05,
      );
    }
  }

  // ── Helper widgets ──────────────────────────────────────────────────────────

  Widget _buildQuickJump() {
    if (_loading) return const SizedBox.shrink();
    return SizedBox(
      height: 60,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        itemCount: _chapters.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, index) {
          final chapter = _chapters[index];
          return ActionChip(
            label: Text('${chapter.number}. ${chapter.title}'),
            onPressed: () => _scrollToChapter(chapter),
            backgroundColor: AppColors.background.withValues(alpha: 0.8),
            labelStyle: GoogleFonts.plusJakartaSans(
              color: AppColors.accent,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: BorderSide(color: AppColors.accent.withValues(alpha: 0.3)),
            ),
          );
        },
      ),
    );
  }

  Widget _buildJuzBanner() {
    if (_loading || _todayJuz == null) return const SizedBox.shrink();
    final juz = _todayJuz!;
    final summary = juz.summary(_chapters);
    final firstSurah = juz.ranges.first.surahNumber;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: GlassContainer(
        padding: const EdgeInsets.all(16),
        gradientColors: [
          AppColors.accent.withValues(alpha: 0.18),
          AppColors.accent.withValues(alpha: 0.05),
        ],
        borderColor: AppColors.accent.withValues(alpha: 0.3),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.accent.withValues(alpha: 0.15),
                border: Border.all(
                  color: AppColors.accent.withValues(alpha: 0.4),
                  width: 2,
                ),
              ),
              alignment: Alignment.center,
              child: Text(
                juz.juzNumber.toString(),
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.accent,
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "TODAY'S JUZ",
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.5,
                      color: AppColors.accent,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    summary,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    juz.mode == JuzMode.standard
                        ? 'Standard · Juz ${juz.juzNumber} of 30'
                        : 'Surah-based · Part ${juz.juzNumber} of 30',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: () {
                final chapter = _chapters.firstWhere(
                  (c) => c.number == firstSurah,
                  orElse: () => _chapters.first,
                );
                _scrollToChapter(chapter);
              },
              style: IconButton.styleFrom(
                backgroundColor: AppColors.accent.withValues(alpha: 0.15),
              ),
              icon: Icon(Icons.auto_stories, color: AppColors.accent),
              tooltip: "Read today's Juz",
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMiniPlayer() {
    if (_playingSurah == null) return const SizedBox.shrink();

    final chapter = _chapters.firstWhere(
      (c) => c.number == _playingSurah,
      orElse: () => _chapters.first,
    );
    final verseNum = (_playingVerse ?? 0) + 1;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.cardSurface.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.accent.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${chapter.title} · Verse $verseNum',
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                    fontSize: 14,
                  ),
                ),
                Text(
                  _isAudioLoading ? 'Loading...' : 'Playing',
                  style: GoogleFonts.plusJakartaSans(
                    color: AppColors.accent,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          // Controls
          if (_isAudioLoading)
            const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          else
            IconButton(
              icon: Icon(
                _isPlaying
                    ? Icons.pause_circle_filled_rounded
                    : Icons.play_circle_fill_rounded,
                color: AppColors.accent,
                size: 36,
              ),
              onPressed: () => _togglePlay(chapter.number),
            ),

          IconButton(
            icon: const Icon(Icons.stop_rounded, color: AppColors.error),
            onPressed: _stopAudio,
          ),
        ],
      ),
    );
  }

  // ── Build ───────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(
          "Qur'an",
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          // Reciter button
          IconButton(
            icon: const Icon(
              Icons.record_voice_over_outlined,
              color: AppColors.textSecondary,
            ),
            onPressed: _openReciterPicker,
            tooltip: 'Select Reciter',
          ),
          // Bookmark button with badge
          ValueListenableBuilder<List<QuranBookmark>>(
            valueListenable: _bookmarks.bookmarks,
            builder: (_, list, __) {
              return Stack(
                alignment: Alignment.center,
                children: [
                  IconButton(
                    icon: Icon(
                      list.isEmpty
                          ? Icons.bookmark_border_rounded
                          : Icons.bookmark_rounded,
                      color: list.isEmpty
                          ? AppColors.textSecondary
                          : AppColors.accent,
                    ),
                    onPressed: _openBookmarks,
                    tooltip: 'Bookmarks',
                  ),
                  if (list.isNotEmpty)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        width: 16,
                        height: 16,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.accent,
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          list.length > 9 ? '9+' : '${list.length}',
                          style: const TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
          IconButton(
            icon: const Icon(
              Icons.menu_book_outlined,
              color: AppColors.textSecondary,
            ),
            onPressed: _openChapterPicker,
            tooltip: 'Browse chapters',
          ),
        ],
      ),
      body: _loading
          ? Center(child: CircularProgressIndicator(color: AppColors.accent))
          : SafeArea(
              child: Stack(
                alignment: Alignment.bottomCenter,
                children: [
                  Column(
                    children: [
                      _buildJuzBanner(),
                      _buildQuickJump(),
                      Expanded(
                        child: ScrollablePositionedList.builder(
                          itemScrollController: _itemScrollController,
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                          itemCount: _chapters.length,
                          itemBuilder: (context, index) {
                            final chapter = _chapters[index];
                            return _ChapterCard(
                              key: _chapterKeys[chapter.number],
                              chapter: chapter,
                              verseKeys: _verseKeys,
                              bookmarkService: _bookmarks,
                              contextMenuSettings: _ctxSettings,
                              onLongPressVerse: (verseIndex) =>
                                  _showVerseContextMenu(
                                context,
                                chapter: chapter,
                                verseIndex: verseIndex,
                              ),
                              playingSurah: _playingSurah,
                              playingVerse: _playingVerse,
                              isPlaying: _isPlaying,
                              onPlayTap: () => _togglePlay(chapter.number),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                  _buildMiniPlayer(),
                ],
              ),
            ),
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

// ── Chapter card ──────────────────────────────────────────────────────────────

class _ChapterCard extends StatelessWidget {
  const _ChapterCard({
    super.key,
    required this.chapter,
    required this.verseKeys,
    required this.bookmarkService,
    required this.contextMenuSettings,
    required this.onLongPressVerse,
    this.playingSurah,
    this.playingVerse,
    this.isPlaying = false,
    this.onPlayTap,
  });

  final QuranChapter chapter;
  final Map<int, GlobalKey> verseKeys;
  final QuranBookmarkService bookmarkService;
  final QuranContextMenuSettings contextMenuSettings;
  final void Function(int verseIndex) onLongPressVerse;
  final int? playingSurah;
  final int? playingVerse;
  final bool isPlaying;
  final VoidCallback? onPlayTap;

  @override
  Widget build(BuildContext context) {
    final isCurrentSurah = playingSurah == chapter.number;

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
                    chapter.number.toString(),
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
                        chapter.title,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        chapter.transliteration,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                // Play button for Surah
                IconButton(
                  icon: Icon(
                    isCurrentSurah && isPlaying
                        ? Icons.pause_circle_filled_rounded
                        : Icons.play_circle_fill_rounded,
                    color: AppColors.accent,
                    size: 32,
                  ),
                  onPressed: onPlayTap,
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Verses
            ListView.separated(
              physics: const NeverScrollableScrollPhysics(),
              shrinkWrap: true,
              itemCount: chapter.verses.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (_, verseIndex) {
                final verseKey = verseKeys[chapter.number * 10000 + verseIndex];
                final isPlayingThisVerse =
                    isCurrentSurah && playingVerse == verseIndex;

                return ValueListenableBuilder<List<QuranBookmark>>(
                  key: verseKey,
                  valueListenable: bookmarkService.bookmarks,
                  builder: (_, bookmarks, __) {
                    final isBookmarked = bookmarks.any(
                      (b) =>
                          b.surahNumber == chapter.number &&
                          b.verseIndex == verseIndex,
                    );

                    // Combine styles: playing verse highlight overrides/adds to bookmark style
                    BoxDecoration? decoration;
                    if (isPlayingThisVerse) {
                      decoration = BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        color: AppColors.accent.withValues(alpha: 0.15),
                        border: Border.all(
                          color: AppColors.accent.withValues(alpha: 0.5),
                          width: 1,
                        ),
                      );
                    } else if (isBookmarked) {
                      decoration = BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        color: AppColors.accent.withValues(alpha: 0.07),
                        border: Border.all(
                          color: AppColors.accent.withValues(alpha: 0.2),
                          width: 1,
                        ),
                      );
                    }

                    return GestureDetector(
                      onLongPress: () => onLongPressVerse(verseIndex),
                      child: Container(
                        decoration: decoration,
                        padding: (isBookmarked || isPlayingThisVerse)
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
                                chapter.verses[verseIndex],
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
