import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:ui';

import 'quran_text_service.dart';
import '../../shared/app_colors.dart';
import '../../shared/glass_container.dart';

/// A structured Qur'an reader with chapter navigation.
class QuranPage extends StatefulWidget {
  const QuranPage({super.key});

  @override
  State<QuranPage> createState() => _QuranPageState();
}

class _QuranPageState extends State<QuranPage> {
  final QuranTextService _service = QuranTextService();
  final ScrollController _scrollController = ScrollController();
  final Map<int, GlobalKey> _chapterKeys = {};

  List<QuranChapter> _chapters = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final chapters = await _service.getChapters();
    if (!mounted) return;
    setState(() {
      _chapterKeys.clear();
      _chapters = List.of(chapters)
        ..sort((a, b) => a.number.compareTo(b.number));
      _loading = false;
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

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
                                    color: AppColors.accent
                                        .withValues(alpha: 0.3)),
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

  Future<void> _scrollToChapter(QuranChapter chapter) async {
    final index = _chapters.indexWhere((c) => c.number == chapter.number);
    final key = _chapterKeys[chapter.number];
    if (key?.currentContext != null) {
      await Scrollable.ensureVisible(
        key!.currentContext!,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
        alignment: 0.05,
      );
      return;
    }

    if (!_scrollController.hasClients) return;

    final position = _scrollController.position;
    final avgExtent = _chapters.isNotEmpty && position.hasPixels
        ? position.maxScrollExtent / _chapters.length
        : 600.0;
    final chapterIndex = index >= 0 ? index : (chapter.number - 1);
    final estimatedOffset =
        (avgExtent * chapterIndex).clamp(0.0, position.maxScrollExtent);

    await _scrollController.animateTo(
      estimatedOffset,
      duration: const Duration(milliseconds: 450),
      curve: Curves.easeInOut,
    );

    // Try again after scrolling now that more items are built.
    await Future.delayed(const Duration(milliseconds: 16));
    if (key?.currentContext != null) {
      await Scrollable.ensureVisible(
        key!.currentContext!,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
        alignment: 0.05,
      );
    }
  }

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
          IconButton(
            icon: const Icon(Icons.menu_book_outlined,
                color: AppColors.textSecondary),
            onPressed: _openChapterPicker,
            tooltip: 'Browse chapters',
          ),
        ],
      ),
      body: _loading
          ? Center(child: CircularProgressIndicator(color: AppColors.accent))
          : SafeArea(
              // Ensure content is safe
              child: Column(
                children: [
                  _buildQuickJump(),
                  Expanded(
                    child: Scrollbar(
                      controller: _scrollController,
                      child: ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.fromLTRB(
                            16, 0, 16, 100), // Bottom padding for nav bar
                        cacheExtent: 2000,
                        itemCount: _chapters.length,
                        itemBuilder: (context, index) {
                          final chapter = _chapters[index];
                          _chapterKeys.putIfAbsent(
                            chapter.number,
                            () => GlobalKey(),
                          );
                          return _ChapterCard(
                            key: ValueKey('chapter_${chapter.number}'),
                            chapter: chapter,
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

class _ChapterCard extends StatelessWidget {
  const _ChapterCard({
    super.key,
    required this.chapter,
  });

  final QuranChapter chapter;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: GlassContainer(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
                        color: AppColors.accent.withValues(alpha: 0.3)),
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
              ],
            ),
            const SizedBox(height: 16),
            ListView.separated(
              physics: const NeverScrollableScrollPhysics(),
              shrinkWrap: true,
              itemCount: chapter.verses.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (_, verseIndex) => SelectableText(
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
          ],
        ),
      ),
    );
  }
}
