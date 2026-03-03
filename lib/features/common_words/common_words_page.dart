import 'dart:ui';

import 'package:audioplayers/audioplayers.dart';
import 'package:csv/csv.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:google_fonts/google_fonts.dart';
import '../../l10n/app_localizations.dart';
import '../../shared/app_colors.dart';
import 'package:immutable5/services/secure_storage_provider.dart';

class CommonWordsPage extends StatefulWidget {
  const CommonWordsPage({super.key});

  @override
  State<CommonWordsPage> createState() => _CommonWordsPageState();
}

class _CommonWordsPageState extends State<CommonWordsPage> {
  static List<List<String>>? _cache;
  Set<int> _memorized = {};
  List<int> _visibleIndices = [];
  List<List<String>> _rows = [];
  bool _loading = true;
  bool _showMemorized = true;
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();
  final AudioPlayer _audioPlayer = AudioPlayer();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadCsv();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.toLowerCase();
      });
      _applyFilters();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _loadCsv() async {
    if (_cache != null) {
      _rows = _cache!;
      _loading = false;
      await _loadMemorized();
      _applyFilters();
      return;
    }
    final data = await rootBundle.loadString('assets/common_words.csv');
    const converter = CsvToListConverter(fieldDelimiter: ',', eol: '\n');
    final list = converter.convert(data, shouldParseNumbers: false);
    final rows = list.map((e) => e.cast<String>()).toList();
    final dataRows = rows.skip(1).toList(); // drop header row from display
    _cache = dataRows;
    _rows = dataRows;
    _loading = false;
    await _loadMemorized();
    _applyFilters();
  }

  Future<void> _loadMemorized() async {
    final prefs = SecureStorageProvider();
    final mem = <int>{};
    for (int i = 0; i < _rows.length; i++) {
      if (await prefs.getBool('mem_word_${i + 1}') == true) mem.add(i);
    }
    _memorized = mem;
  }

  Future<void> _toggleMemorized(int index) async {
    final prefs = SecureStorageProvider();
    if (_memorized.contains(index)) {
      _memorized.remove(index);
      await prefs.remove('mem_word_${index + 1}');
    } else {
      _memorized.add(index);
      await prefs.setBool('mem_word_${index + 1}', true);
    }
  }

  void _applyFilters() {
    _visibleIndices = List.generate(_rows.length, (i) => i);
    if (!_showMemorized) {
      _visibleIndices =
          _visibleIndices.where((i) => !_memorized.contains(i)).toList();
    }
    if (_searchQuery.isNotEmpty) {
      _visibleIndices = _visibleIndices.where((i) {
        final row = _rows[i];
        return row[0].contains(_searchQuery) || // Arabic
            row[1].toLowerCase().contains(_searchQuery) || // Transliteration
            row[2].toLowerCase().contains(_searchQuery); // English
      }).toList();
    }
    setState(() {});
  }

  // ── Word detail bottom sheet ─────────────────────────────────────────────────

  void _showWordDetail(int rowIndex) {
    final row = _rows[rowIndex];
    final arabic = row[0];
    final transliteration = row[1];
    final english = row[2];

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetCtx) {
        return StatefulBuilder(
          builder: (_, setSheetState) {
            final isMemorized = _memorized.contains(rowIndex);
            return ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(28),
              ),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                child: Container(
                  color: AppColors.cardSurface.withValues(alpha: 0.95),
                  child: SafeArea(
                    top: false,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Handle bar
                          Center(
                            child: Container(
                              width: 40,
                              height: 4,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                          ),
                          const SizedBox(height: 28),

                          // Arabic text — large and centred
                          Stack(
                            alignment: Alignment.center,
                            children: [
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 20,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.accent.withValues(
                                    alpha: 0.07,
                                  ),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: AppColors.accent.withValues(
                                      alpha: 0.2,
                                    ),
                                  ),
                                ),
                                child: Text(
                                  arabic,
                                  textAlign: TextAlign.center,
                                  textDirection: TextDirection.rtl,
                                  style: const TextStyle(
                                    fontFamily: 'Amiri',
                                    fontSize: 72,
                                    height: 1.3,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                              ),
                              Positioned(
                                right: 12,
                                top: 12,
                                child: IconButton(
                                  icon: const Icon(Icons.volume_up_rounded),
                                  color: AppColors.accent,
                                  iconSize: 28,
                                  onPressed: () {
                                    _audioPlayer.play(
                                      AssetSource('audio/words/$rowIndex.mp3'),
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 20),

                          // Transliteration
                          Text(
                            transliteration,
                            textAlign: TextAlign.center,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 22,
                              fontStyle: FontStyle.italic,
                              color: AppColors.accent,
                              fontWeight: FontWeight.w500,
                            ),
                          ),

                          const SizedBox(height: 8),

                          // English meaning
                          Text(
                            english,
                            textAlign: TextAlign.center,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 18,
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w400,
                            ),
                          ),

                          const SizedBox(height: 28),

                          // Memorised toggle button
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton.icon(
                              onPressed: () async {
                                await _toggleMemorized(rowIndex);
                                setSheetState(() {});
                                // Rebuild the list beneath so the opacity/badge updates
                                setState(() {});
                                _applyFilters();
                              },
                              icon: Icon(
                                isMemorized
                                    ? Icons.check_circle
                                    : Icons.check_circle_outline,
                                size: 20,
                              ),
                              label: Text(
                                isMemorized
                                    ? 'Remove from memorised'
                                    : 'Mark as memorised',
                                style: GoogleFonts.plusJakartaSans(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              style: FilledButton.styleFrom(
                                backgroundColor: isMemorized
                                    ? AppColors.error.withValues(alpha: 0.15)
                                    : AppColors.success.withValues(alpha: 0.15),
                                foregroundColor: isMemorized
                                    ? AppColors.error
                                    : AppColors.success,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                  horizontal: 24,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  side: BorderSide(
                                    color: isMemorized
                                        ? AppColors.error.withValues(alpha: 0.3)
                                        : AppColors.success.withValues(
                                            alpha: 0.3,
                                          ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
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

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context);
    final isRtl = locale.languageCode == 'ar';
    return Directionality(
      textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        appBar: AppBar(
          title: _isSearching
              ? TextField(
                  controller: _searchController,
                  autofocus: true,
                  decoration: InputDecoration(
                    hintText: AppLocalizations.of(context)!.search,
                    border: InputBorder.none,
                    hintStyle: const TextStyle(color: Colors.white60),
                  ),
                  style: const TextStyle(color: Colors.white, fontSize: 18),
                )
              : Text(AppLocalizations.of(context)!.commonWords),
          actions: [
            if (!_loading) ...[
              IconButton(
                icon: Icon(_isSearching ? Icons.close : Icons.search),
                onPressed: () {
                  setState(() {
                    if (_isSearching) {
                      _searchController.clear();
                      _isSearching = false;
                    } else {
                      _isSearching = true;
                    }
                  });
                },
              ),
              Switch(
                value: _showMemorized,
                onChanged: (value) {
                  setState(() => _showMemorized = value);
                  _applyFilters();
                },
                activeTrackColor: Colors.greenAccent,
              ),
            ],
          ],
        ),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: _visibleIndices.length,
                itemBuilder: (context, i) {
                  final rowIndex = _visibleIndices[i];
                  final row = _rows[rowIndex];
                  final isMemorized = _memorized.contains(rowIndex);

                  return Dismissible(
                    key: ValueKey('word_$rowIndex'),
                    direction: DismissDirection.endToStart,
                    background: Container(
                      decoration: BoxDecoration(
                        color: (isMemorized ? Colors.red : Colors.green)
                            .withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Icon(
                        isMemorized ? Icons.close : Icons.check,
                        color: isMemorized ? Colors.red : Colors.green,
                      ),
                    ),
                    confirmDismiss: (_) async {
                      await _toggleMemorized(rowIndex);
                      if (_showMemorized) {
                        _applyFilters();
                        return false;
                      }
                      setState(() {
                        _visibleIndices.remove(rowIndex);
                      });
                      return true;
                    },
                    child: Opacity(
                      opacity: isMemorized && _showMemorized ? 0.4 : 1,
                      child: GestureDetector(
                        onLongPress: () => _showWordDetail(rowIndex),
                        child: Card(
                          margin: const EdgeInsets.symmetric(vertical: 6),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        row[1],
                                        style: const TextStyle(
                                          fontStyle: FontStyle.italic,
                                          fontSize: 15,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        row[2],
                                        style: const TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Text(
                                  row[0],
                                  textAlign: TextAlign.right,
                                  style: isRtl
                                      ? const TextStyle(
                                          fontFamily: 'Amiri',
                                          fontSize: 22,
                                        )
                                      : const TextStyle(fontSize: 22),
                                ),
                                if (isMemorized) ...[
                                  const SizedBox(width: 8),
                                  const Icon(
                                    Icons.check_circle,
                                    color: Colors.green,
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }
}
