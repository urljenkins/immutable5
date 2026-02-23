import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:ui';

import 'models/dua_model.dart';
import 'dua_repository.dart';
import '../../di/service_locator.dart';
import '../../shared/app_colors.dart';
import '../../shared/glass_container.dart';

class DuasPage extends StatefulWidget {
  const DuasPage({super.key});

  @override
  State<DuasPage> createState() => _DuasPageState();
}

class _DuasPageState extends State<DuasPage> {
  final DuaRepository _duaRepository = getIt<DuaRepository>();
  List<Dua> _duas = [];
  List<Dua> _filteredDuas = [];
  List<String> _categories = ['All'];
  String _selectedCategory = 'All';
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  bool _loading = true;
  final Set<String> _favorites = {};
  Dua? _selectedDua;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _loadDuas();
  }

  Future<void> _loadDuas() async {
    try {
      final duas = await _duaRepository.getAllDuas();
      final sortedDuas = List<Dua>.from(duas)
        ..sort((a, b) {
          final categoryComparison = a.category.compareTo(b.category);
          if (categoryComparison != 0) return categoryComparison;

          final priorityComparison = a.priority.compareTo(b.priority);
          if (priorityComparison != 0) return priorityComparison;

          return a.id.compareTo(b.id);
        });

      final categories = sortedDuas
          .map((d) => d.category)
          .where((c) => c.isNotEmpty)
          .toSet()
          .toList()
        ..sort();

      setState(() {
        _duas = sortedDuas;
        _filteredDuas = sortedDuas;
        _categories = ['All', ...categories];
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
      var filtered = _duas;

      if (_selectedCategory != 'All') {
        filtered =
            filtered.where((dua) => dua.category == _selectedCategory).toList();
      }

      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        filtered = filtered.where((dua) {
          return dua.translationEn.toLowerCase().contains(query) ||
              dua.transliteration.toLowerCase().contains(query) ||
              dua.arabic.contains(query) ||
              dua.occasion.toLowerCase().contains(query) ||
              dua.category.toLowerCase().contains(query);
        }).toList();
      }

      _filteredDuas = filtered;
    });
  }

  void _filterByCategory(String category) {
    _selectedCategory = category;
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
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(
          'Duas',
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
                  // Wrap content in SafeArea to respect notches
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
                            hintText: 'Search duas...',
                            hintStyle: GoogleFonts.plusJakartaSans(
                              color: AppColors.textSecondary
                                  .withValues(alpha: 0.5),
                            ),
                            prefixIcon: const Icon(Icons.search,
                                color: AppColors.textSecondary),
                            suffixIcon: _searchQuery.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.clear,
                                        color: AppColors.textSecondary),
                                    onPressed: () {
                                      _searchController.clear();
                                      _onSearchChanged('');
                                    },
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                  )
                                : null,
                            filled: true,
                            fillColor:
                                AppColors.cardSurface.withValues(alpha: 0.5),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide(
                                color: AppColors.textSecondary
                                    .withValues(alpha: 0.2),
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide(
                                color: AppColors.textSecondary
                                    .withValues(alpha: 0.2),
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide(
                                color: AppColors.accent.withValues(alpha: 0.5),
                              ),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 12),
                          ),
                        ),
                      ),
                      // Category Filter
                      Container(
                        height: 60,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: _categories.length,
                          itemBuilder: (context, index) {
                            final category = _categories[index];
                            final isSelected = category == _selectedCategory;
                            return Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: FilterChip(
                                label: Text(category),
                                selected: isSelected,
                                onSelected: (selected) {
                                  if (selected) {
                                    _filterByCategory(category);
                                  } else {
                                    _filterByCategory('All');
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
                                        : AppColors.textSecondary
                                            .withValues(alpha: 0.3),
                                  ),
                                ),
                                backgroundColor: Colors.transparent,
                              ),
                            );
                          },
                        ),
                      ),

                      // Duas List
                      Expanded(
                        child: _filteredDuas.isEmpty
                            ? Center(
                                child: Text(
                                  'No duas found',
                                  style: GoogleFonts.plusJakartaSans(
                                      color: AppColors.textSecondary),
                                ),
                              )
                            : ListView.builder(
                                padding: const EdgeInsets.fromLTRB(16, 8, 16,
                                    100), // Bottom padding for nav bar
                                itemCount: _filteredDuas.length,
                                itemBuilder: (context, index) {
                                  final dua = _filteredDuas[index];
                                  return _buildDuaCard(dua);
                                },
                              ),
                      ),
                    ],
                  ),
                ),
                if (_selectedDua != null)
                  _DuaDetailSheet(
                    dua: _selectedDua!,
                    onClose: () => setState(() => _selectedDua = null),
                  ),
              ],
            ),
    );
  }

  Widget _buildDuaCard(Dua dua) {
    final isFavorite = _favorites.contains(dua.id);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: GlassContainer(
        padding: const EdgeInsets.all(20),
        onTap: () => setState(() => _selectedDua = dua),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header with category and favorite
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.accent.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: AppColors.accent.withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    dua.category,
                    style: GoogleFonts.plusJakartaSans(
                      color: AppColors.accent,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(
                    isFavorite ? Icons.bookmark : Icons.bookmark_border,
                    color:
                        isFavorite ? AppColors.accent : AppColors.textSecondary,
                    size: 20,
                  ),
                  onPressed: () => _toggleFavorite(dua.id),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Occasion
            if (dua.occasion.isNotEmpty ||
                (dua.benefits != null && dua.benefits!.isNotEmpty))
              Text(
                dua.occasion.isNotEmpty ? dua.occasion : (dua.benefits ?? ''),
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                  fontStyle: FontStyle.italic,
                  height: 1.4,
                ),
              ),
            const SizedBox(height: 16),

            // Arabic Text
            Text(
              dua.arabic,
              textAlign: TextAlign.right,
              style: const TextStyle(
                // Keep standard font for Arabic for now, or ensure Amiri is loaded
                fontSize: 24,
                fontFamily: 'Amiri', // Assuming Amiri is available or fallback
                height: 2.2,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 16),

            // Transliteration
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.background.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                dua.transliteration,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontStyle: FontStyle.italic,
                  color: AppColors.textSecondary,
                  height: 1.5,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Translation
            Text(
              dua.translationEn,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 15,
                height: 1.6,
                color: AppColors.textPrimary,
              ),
            ),

            // Copy Button
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  icon: const Icon(Icons.copy,
                      size: 16, color: AppColors.textSecondary),
                  label: Text(
                    'Copy',
                    style: GoogleFonts.plusJakartaSans(
                        color: AppColors.textSecondary, fontSize: 12),
                  ),
                  onPressed: () {
                    Clipboard.setData(ClipboardData(
                      text: "${dua.arabic}\n\n${dua.translationEn}",
                    ));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Dua copied to clipboard'),
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
    );
  }
}

String prettyLabel(String value) {
  final clean = value.replaceAll('_', ' ').trim();
  if (clean.isEmpty) return value;
  return clean
      .split(' ')
      .map((word) =>
          word.isEmpty ? '' : '${word[0].toUpperCase()}${word.substring(1)}')
      .join(' ');
}

class _DuaDetailSheet extends StatelessWidget {
  const _DuaDetailSheet({
    required this.dua,
    required this.onClose,
  });

  final Dua dua;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final tags = dua.tags.toSet().toList();
    final timeWindows =
        (dua.displayContext?.timeWindows ?? const <String>[]).toSet().toList();

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
            child: SafeArea(
              // SafeArea for bottom padding
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
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
                          'Details',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close,
                              color: AppColors.textSecondary),
                          onPressed: onClose,
                        )
                      ],
                    ),
                    const SizedBox(height: 16),
                    if (tags.isNotEmpty) ...[
                      Text(
                        'TAGS',
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
                        children: tags
                            .map(
                              (tag) => Chip(
                                label: Text(prettyLabel(tag)),
                                labelStyle:
                                    GoogleFonts.plusJakartaSans(fontSize: 12),
                                backgroundColor: AppColors.background,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8)),
                                side: BorderSide.none,
                              ),
                            )
                            .toList(),
                      ),
                      const SizedBox(height: 16),
                    ],
                    if (timeWindows.isNotEmpty) ...[
                      Text(
                        'CONTEXTS',
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
                        children: timeWindows
                            .map(
                              (window) => Chip(
                                label: Text(prettyLabel(window)),
                                labelStyle:
                                    GoogleFonts.plusJakartaSans(fontSize: 12),
                                backgroundColor: AppColors.background,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8)),
                                side: BorderSide.none,
                              ),
                            )
                            .toList(),
                      ),
                      const SizedBox(height: 16),
                    ],
                    if (dua.notes?.isNotEmpty ?? false) ...[
                      Text(
                        'NOTES',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        dua.notes!,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          color: AppColors.textPrimary,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                    if (dua.authenticity != null &&
                        dua.authenticity!.grade != null &&
                        dua.authenticity!.grade!.isNotEmpty) ...[
                      Text(
                        'AUTHENTICITY',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.accent.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                              color: AppColors.accent.withValues(alpha: 0.2)),
                        ),
                        child: Text(
                          prettyLabel(dua.authenticity!.grade!),
                          style: GoogleFonts.plusJakartaSans(
                            color: AppColors.accent,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
