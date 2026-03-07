import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../di/service_locator.dart';
import '../../l10n/app_localizations.dart';
import '../../shared/app_colors.dart';
import '../../shared/glass_container.dart';
import 'hadith_repository.dart';
import 'models/hadith.dart';

class HadithPage extends StatefulWidget {
  const HadithPage({super.key});

  @override
  State<HadithPage> createState() => _HadithPageState();
}

class _HadithPageState extends State<HadithPage> {
  final HadithRepository _hadithRepository = getIt<HadithRepository>();
  List<Hadith> _hadiths = [];
  List<Hadith> _filteredHadiths = [];
  List<String> _collections = ['All'];
  String _selectedCollection = 'All';
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  bool _loading = true;
  Hadith? _selectedHadith;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    unawaited(_loadHadiths());
  }

  Future<void> _loadHadiths() async {
    try {
      final hadiths = await _hadithRepository.getAllHadiths();
      final sortedHadiths = List<Hadith>.from(hadiths)
        ..sort((a, b) => a.priority.compareTo(b.priority));

      final collections = sortedHadiths
          .map((h) => h.collection)
          .where((c) => c.isNotEmpty)
          .toSet()
          .toList()
        ..sort();

      setState(() {
        _hadiths = sortedHadiths;
        _filteredHadiths = sortedHadiths;
        _collections = ['All', ...collections];
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _loading = false;
      });
    }
  }

  void _applyFilters() {
    setState(() {
      var filtered = _hadiths;

      if (_selectedCollection != 'All') {
        filtered =
            filtered.where((h) => h.collection == _selectedCollection).toList();
      }

      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        filtered = filtered.where((h) {
          return h.translationEn.toLowerCase().contains(query) ||
              h.arabic.contains(query) ||
              h.summaryEn.toLowerCase().contains(query) ||
              h.topics.any((t) => t.toLowerCase().contains(query)) ||
              h.collection.toLowerCase().contains(query);
        }).toList();
      }

      _filteredHadiths = filtered;
    });
  }

  void _filterByCollection(String collection) {
    _selectedCollection = collection;
    _applyFilters();
  }

  void _onSearchChanged(String query) {
    _searchQuery = query;
    _applyFilters();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(
          l10n.hadiths,
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: _loading
          ? Center(child: CircularProgressIndicator(color: AppColors.accent))
          : Stack(
              children: [
                SafeArea(
                  child: Column(
                    children: [
                      // Search Bar
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                        child: TextField(
                          controller: _searchController,
                          onChanged: _onSearchChanged,
                          style: GoogleFonts.plusJakartaSans(
                            color: AppColors.textPrimary,
                          ),
                          decoration: InputDecoration(
                            hintText: l10n.searchHadiths,
                            hintStyle: GoogleFonts.plusJakartaSans(
                              color: AppColors.textSecondary.withValues(
                                alpha: 0.5,
                              ),
                            ),
                            prefixIcon: const Icon(
                              Icons.search,
                              color: AppColors.textSecondary,
                            ),
                            suffixIcon: _searchQuery.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(
                                      Icons.clear,
                                      color: AppColors.textSecondary,
                                    ),
                                    onPressed: () {
                                      _searchController.clear();
                                      _onSearchChanged('');
                                    },
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                  )
                                : null,
                            filled: true,
                            fillColor: AppColors.cardSurface.withValues(
                              alpha: 0.5,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide(
                                color: AppColors.textSecondary.withValues(
                                  alpha: 0.2,
                                ),
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide(
                                color: AppColors.textSecondary.withValues(
                                  alpha: 0.2,
                                ),
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide(
                                color: AppColors.accent.withValues(alpha: 0.5),
                              ),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                          ),
                        ),
                      ),
                      // Collection Filter
                      Container(
                        height: 60,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: _collections.length,
                          itemBuilder: (context, index) {
                            final collection = _collections[index];
                            final isSelected =
                                collection == _selectedCollection;
                            return Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: FilterChip(
                                label: Text(collection),
                                selected: isSelected,
                                onSelected: (selected) {
                                  if (selected) {
                                    _filterByCollection(collection);
                                  } else {
                                    _filterByCollection('All');
                                  }
                                },
                                selectedColor: AppColors.accent,
                                checkmarkColor: AppColors.background,
                                labelStyle: GoogleFonts.plusJakartaSans(
                                  color: isSelected
                                      ? AppColors.background
                                      : AppColors.textSecondary,
                                  fontWeight: isSelected
                                      ? FontWeight.w600
                                      : FontWeight.normal,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                  side: BorderSide(
                                    color: isSelected
                                        ? Colors.transparent
                                        : AppColors.textSecondary.withValues(
                                            alpha: 0.3,
                                          ),
                                  ),
                                ),
                                backgroundColor: Colors.transparent,
                              ),
                            );
                          },
                        ),
                      ),

                      // Hadiths List
                      Expanded(
                        child: _filteredHadiths.isEmpty
                            ? Center(
                                child: Text(
                                  l10n.noHadithsFound,
                                  style: GoogleFonts.plusJakartaSans(
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              )
                            : ListView.builder(
                                padding: const EdgeInsets.fromLTRB(
                                  16,
                                  8,
                                  16,
                                  100,
                                ), // Bottom padding for nav bar
                                itemCount: _filteredHadiths.length,
                                itemBuilder: (context, index) {
                                  final hadith = _filteredHadiths[index];
                                  return _buildHadithCard(hadith);
                                },
                              ),
                      ),
                    ],
                  ),
                ),
                if (_selectedHadith != null)
                  _HadithDetailSheet(
                    hadith: _selectedHadith!,
                    onClose: () => setState(() => _selectedHadith = null),
                  ),
              ],
            ),
    );
  }

  Widget _buildHadithCard(Hadith hadith) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: GlassContainer(
        onTap: () => setState(() => _selectedHadith = hadith),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Collection and Number
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.accent.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.accent.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Text(
                    hadith.collection.toUpperCase(),
                    style: GoogleFonts.plusJakartaSans(
                      color: AppColors.accent,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                Text(
                  '#${hadith.hadithNumber}',
                  style: GoogleFonts.plusJakartaSans(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Arabic Text
            Text(
              hadith.arabic,
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontSize: 22,
                fontFamily: 'Amiri',
                height: 1.8,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 16),

            // Summary
            Text(
              hadith.summaryEn,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 8),

            // Translation
            Text(
              hadith.translationEn,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                height: 1.5,
                color: AppColors.textSecondary,
              ),
            ),

            const SizedBox(height: 16),

            // Footer
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.background.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    hadith.grade,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: hadith.grade.toLowerCase().contains('sahih')
                          ? Colors.green
                          : AppColors.accent,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () => setState(() => _selectedHadith = hadith),
                  child: Text(
                    'Read More',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppColors.accent,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _HadithDetailSheet extends StatelessWidget {
  const _HadithDetailSheet({required this.hadith, required this.onClose});

  final Hadith hadith;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.8,
            ),
            color: AppColors.cardSurface.withValues(alpha: 0.9),
            child: SafeArea(
              top: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
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
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      hadith.collection,
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                    Text(
                                      'Book: ${hadith.book} (${hadith.hadithNumber})',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 14,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.close,
                                  color: AppColors.textSecondary,
                                ),
                                onPressed: onClose,
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          if (hadith.narrator != null) ...[
                            Text(
                              'NARRATED BY',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.2,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              hadith.narrator!,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 14,
                                fontStyle: FontStyle.italic,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 24),
                          ],
                          Text(
                            hadith.arabic,
                            textAlign: TextAlign.right,
                            textDirection: TextDirection.rtl,
                            style: const TextStyle(
                              fontSize: 24,
                              fontFamily: 'Amiri',
                              height: 1.8,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 24),
                          Text(
                            'TRANSLATION',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.2,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            hadith.translationEn,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 16,
                              height: 1.6,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 24),
                          if (hadith.keyLessons.isNotEmpty) ...[
                            Text(
                              'KEY LESSONS',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.2,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 8),
                            ...hadith.keyLessons.map(
                              (lesson) => Padding(
                                padding: const EdgeInsets.only(bottom: 8.0),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '• ',
                                      style: TextStyle(
                                        color: AppColors.accent,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Expanded(
                                      child: Text(
                                        lesson,
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 14,
                                          height: 1.5,
                                          color: AppColors.textPrimary,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                          ],
                          Text(
                            'TOPICS',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.2,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: hadith.topics
                                .map(
                                  (topic) => Chip(
                                    label: Text(topic),
                                    labelStyle: GoogleFonts.plusJakartaSans(
                                      fontSize: 11,
                                    ),
                                    backgroundColor: AppColors.background,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    side: BorderSide.none,
                                  ),
                                )
                                .toList(),
                          ),
                          const SizedBox(height: 24),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'AUTHENTICITY',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 1.2,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    hadith.grade,
                                    style: GoogleFonts.plusJakartaSans(
                                      color: hadith.grade
                                              .toLowerCase()
                                              .contains('sahih')
                                          ? Colors.green
                                          : AppColors.accent,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                              ElevatedButton.icon(
                                icon: const Icon(Icons.copy, size: 16),
                                label: const Text('Copy'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.accent,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                onPressed: () {
                                  unawaited(Clipboard.setData(
                                    ClipboardData(
                                      text:
                                          '${hadith.arabic}\n\n${hadith.translationEn}\n\n[${hadith.collection}, ${hadith.hadithNumber}]',
                                    ),
                                  ));
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content:
                                          Text('Hadith copied to clipboard'),
                                      duration: Duration(seconds: 2),
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ],
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
  }
}
