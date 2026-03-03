import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../di/service_locator.dart';
import '../../shared/app_colors.dart';
import 'contextual_hadith_service.dart';
import 'hadith_repository.dart';
import 'models/hadith.dart';
import 'widgets/hadith_card.dart';

class HadithsPage extends StatefulWidget {
  const HadithsPage({super.key});

  @override
  State<HadithsPage> createState() => _HadithsPageState();
}

class _HadithsPageState extends State<HadithsPage> {
  final HadithRepository _hadithRepository = getIt<HadithRepository>();
  final ContextualHadithService _contextualHadithService =
      getIt<ContextualHadithService>();

  List<Hadith> _hadiths = [];
  List<Hadith> _filteredHadiths = [];
  List<Hadith> _recommendedHadiths = [];
  bool _hasRecommendations = false;
  List<String> _topics = ['All'];
  String _selectedTopic = 'All';
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  bool _loading = true;
  final Set<String> _favorites = {};
  Hadith? _selectedHadith;
  bool _filterFavoritesOnly = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _loadHadiths();
  }

  Future<void> _loadHadiths() async {
    try {
      final hadiths = await _hadithRepository.getAllHadiths();
      final now = DateTime.now();

      final recommended = await _contextualHadithService.getRecommendedHadiths(
        now: now,
      );

      final topicsSet = <String>{};
      for (var h in hadiths) {
        topicsSet.addAll(h.topics);
      }
      final topics = topicsSet.toList()..sort();

      setState(() {
        _hadiths = hadiths;
        _recommendedHadiths = recommended;
        _hasRecommendations = recommended.isNotEmpty;
        _filteredHadiths = hadiths;

        final baseTopics = ['All'];
        if (_hasRecommendations) {
          baseTopics.add('Recommended');
        }
        _topics = [...baseTopics, ...topics];
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

      if (_selectedTopic == 'Recommended') {
        filtered = _recommendedHadiths;
      } else if (_selectedTopic != 'All') {
        filtered =
            filtered.where((h) => h.topics.contains(_selectedTopic)).toList();
      }

      if (_filterFavoritesOnly) {
        filtered =
            filtered.where((h) => _favorites.contains(h.hadithId)).toList();
      }

      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        filtered = filtered.where((h) {
          final matchesTopics =
              h.topics.any((t) => t.toLowerCase().contains(query));
          return h.translationEn.toLowerCase().contains(query) ||
              h.transliteration.toLowerCase().contains(query) ||
              h.arabic.contains(query) ||
              h.summaryEn.toLowerCase().contains(query) ||
              h.narrator?.toLowerCase().contains(query) == true ||
              matchesTopics;
        }).toList();
      }

      _filteredHadiths = filtered;
    });
  }

  void _filterByTopic(String topic) {
    _selectedTopic = topic;
    _applyFilters();
  }

  void _onSearchChanged(String query) {
    _searchQuery = query;
    _applyFilters();
  }

  void _toggleFavorite(String id) {
    setState(() {
      if (_favorites.contains(id)) {
        _favorites.remove(id);
      } else {
        _favorites.add(id);
      }
      if (_filterFavoritesOnly) {
        _applyFilters();
      }
    });
  }

  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.cardSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Filters',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    SwitchListTile(
                      title: Text(
                        'Favorites Only',
                        style: GoogleFonts.plusJakartaSans(
                          color: AppColors.textPrimary,
                        ),
                      ),
                      value: _filterFavoritesOnly,
                      onChanged: (val) {
                        setSheetState(() => _filterFavoritesOnly = val);
                        setState(() => _filterFavoritesOnly = val);
                        _applyFilters();
                      },
                      activeThumbColor: AppColors.background,
                      activeTrackColor: AppColors.accent,
                    ),
                  ],
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
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(
          'Hadiths',
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
                            hintText: 'Search hadiths...',
                            hintStyle: GoogleFonts.plusJakartaSans(
                              color: AppColors.textSecondary
                                  .withValues(alpha: 0.5),
                            ),
                            prefixIcon: const Icon(
                              Icons.search,
                              color: AppColors.textSecondary,
                            ),
                            suffixIcon: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (_searchQuery.isNotEmpty)
                                  IconButton(
                                    icon: const Icon(
                                      Icons.clear,
                                      color: AppColors.textSecondary,
                                    ),
                                    onPressed: () {
                                      _searchController.clear();
                                      _onSearchChanged('');
                                    },
                                  ),
                                IconButton(
                                  icon: Icon(
                                    Icons.filter_list,
                                    color: _filterFavoritesOnly
                                        ? AppColors.accent
                                        : AppColors.textSecondary,
                                  ),
                                  onPressed: _showFilterSheet,
                                ),
                              ],
                            ),
                            filled: true,
                            fillColor:
                                AppColors.cardSurface.withValues(alpha: 0.5),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                      ),

                      // Filter Topics
                      Container(
                        height: 60,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: _topics.length,
                          itemBuilder: (context, index) {
                            final topic = _topics[index];
                            final isSelected = topic == _selectedTopic;
                            return Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: FilterChip(
                                label: Text(topic),
                                selected: isSelected,
                                onSelected: (s) =>
                                    _filterByTopic(s ? topic : 'All'),
                                selectedColor: AppColors.accent,
                                checkmarkColor: AppColors.background,
                                labelStyle: GoogleFonts.plusJakartaSans(
                                  color: isSelected
                                      ? AppColors.background
                                      : AppColors.textPrimary,
                                  fontWeight: isSelected
                                      ? FontWeight.w600
                                      : FontWeight.w500,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                  side: BorderSide(
                                    color: isSelected
                                        ? Colors.transparent
                                        : AppColors.textSecondary
                                            .withValues(alpha: 0.5),
                                  ),
                                ),
                                backgroundColor: AppColors.cardSurface
                                    .withValues(alpha: 0.5),
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
                                  'No hadiths found',
                                  style: GoogleFonts.plusJakartaSans(
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              )
                            : ListView.builder(
                                padding:
                                    const EdgeInsets.fromLTRB(16, 8, 16, 100),
                                itemCount: _filteredHadiths.length,
                                itemBuilder: (context, index) {
                                  return HadithCard(
                                    hadith: _filteredHadiths[index],
                                    isFavorite: _favorites.contains(
                                      _filteredHadiths[index].hadithId,
                                    ),
                                    onTap: () => setState(
                                      () => _selectedHadith =
                                          _filteredHadiths[index],
                                    ),
                                    onFavoriteToggle: () => _toggleFavorite(
                                      _filteredHadiths[index].hadithId,
                                    ),
                                  );
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
}

class _HadithDetailSheet extends StatelessWidget {
  const _HadithDetailSheet({required this.hadith, required this.onClose});

  final Hadith hadith;
  final VoidCallback onClose;

  String _prettyLabel(String value) {
    if (value.isEmpty) return value;
    final split = value.split('_');
    return split
        .map((e) => e.length > 1 ? '${e[0].toUpperCase()}${e.substring(1)}' : e)
        .join(' ');
  }

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
            color: AppColors.cardSurface.withValues(alpha: 0.9),
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
            child: SafeArea(
              top: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Details & Lessons',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
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
                  const SizedBox(height: 16),

                  // Key Lessons
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
                            const Text(
                              '• ',
                              style: TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 16,
                              ),
                            ),
                            Expanded(
                              child: Text(
                                lesson,
                                style: GoogleFonts.plusJakartaSans(
                                  color: AppColors.textPrimary,
                                  height: 1.4,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Topics
                  if (hadith.topics.isNotEmpty) ...[
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
                            (tag) => Chip(
                              label: Text(tag),
                              labelStyle: GoogleFonts.plusJakartaSans(
                                fontSize: 12,
                                color: AppColors.background,
                                fontWeight: FontWeight.w600,
                              ),
                              backgroundColor: AppColors.accent,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              side: BorderSide.none,
                            ),
                          )
                          .toList(),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Related Duas link (if integrated later with Navigation)
                  if (hadith.relatedDuaIds.isNotEmpty) ...[
                    Text(
                      'RELATED DUAS',
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
                      children: hadith.relatedDuaIds
                          .map(
                            (id) => ActionChip(
                              label: Text(_prettyLabel(id)),
                              backgroundColor: AppColors.cardSurface,
                              labelStyle: TextStyle(color: AppColors.accent),
                              onPressed: () {
                                // TBD: Navigate to dua details
                              },
                            ),
                          )
                          .toList(),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
