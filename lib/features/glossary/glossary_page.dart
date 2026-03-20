import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:immutable5/services/secure_storage_provider.dart';
import 'package:immutable5/shared/app_colors.dart';
import 'package:immutable5/shared/glass_container.dart';

import 'models/glossary_item.dart';

class GlossaryPage extends StatefulWidget {
  const GlossaryPage({super.key});

  @override
  State<GlossaryPage> createState() => _GlossaryPageState();
}

class _GlossaryPageState extends State<GlossaryPage> {
  List<GlossaryItem> _allItem = [];
  List<GlossaryItem> _filteredItems = [];
  String _searchQuery = '';
  String _selectedCategory = 'All';
  bool _loading = true;
  bool _hideKnown = false;
  Set<String> _knownItems = {};

  final TextEditingController _searchController = TextEditingController();
  final _prefs = SecureStorageProvider();

  List<String> get _categories => [
        'All',
        ...{..._allItem.map((item) => item.category)},
      ];

  @override
  void initState() {
    super.initState();
    unawaited(_loadKnownStatusAndGlossary());
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadKnownStatusAndGlossary() async {
    final hideKnown = await _prefs.getBool('glossary_hide_known') ?? false;
    final knownList = await _prefs.getStringList('glossary_known_items') ?? [];

    setState(() {
      _hideKnown = hideKnown;
      _knownItems = knownList.toSet();
    });

    await _loadGlossary();
  }

  Future<void> _loadGlossary() async {
    final String response = await rootBundle.loadString('assets/glossary.json');
    final data = json.decode(response) as List;
    setState(() {
      _allItem = data
          .map((json) => GlossaryItem.fromJson(json as Map<String, dynamic>))
          .toList();
      _loading = false;
    });
    _applyFilters();
  }

  void _onSearchChanged() {
    _applyFilters();
  }

  Future<void> _toggleHideKnown() async {
    final newVal = !_hideKnown;
    await _prefs.setBool('glossary_hide_known', newVal);
    setState(() {
      _hideKnown = newVal;
    });
    _applyFilters();
  }

  Future<void> _markAsKnown(String term, bool known) async {
    if (known) {
      _knownItems.add(term);
    } else {
      _knownItems.remove(term);
    }
    await _prefs.setStringList('glossary_known_items', _knownItems.toList());
    setState(() {});
    _applyFilters();
  }

  void _applyFilters() {
    setState(() {
      _searchQuery = _searchController.text.toLowerCase();
      _filteredItems = _allItem.where((item) {
        final matchesSearch = item.term.toLowerCase().contains(_searchQuery) ||
            item.definition.toLowerCase().contains(_searchQuery);
        final matchesCategory =
            _selectedCategory == 'All' || item.category == _selectedCategory;
        final isKnown = _knownItems.contains(item.term);
        final matchesKnownFilter = !_hideKnown || !isKnown;

        return matchesSearch && matchesCategory && matchesKnownFilter;
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Glossary',
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
        actions: [
          IconButton(
            icon: Icon(
              _hideKnown ? Icons.visibility_off : Icons.visibility,
              color: _hideKnown ? AppColors.accent : AppColors.textSecondary,
            ),
            tooltip: _hideKnown ? 'Show known items' : 'Hide known items',
            onPressed: _toggleHideKnown,
          ),
        ],
      ),
      body: Stack(
        children: [
          // Background atmospheric orb
          Positioned(
            top: -50,
            left: -50,
            child: Container(
              height: 250,
              width: 250,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.accent.withValues(alpha: 0.1),
                boxShadow: [
                  BoxShadow(
                    blurRadius: 100,
                    color: AppColors.accent.withValues(alpha: 0.15),
                    spreadRadius: 20,
                  ),
                ],
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                _buildSearchBar(),
                _buildCategoryFilters(),
                Expanded(
                  child: _loading
                      ? const Center(child: CircularProgressIndicator())
                      : _filteredItems.isEmpty
                          ? _buildEmptyState()
                          : _buildGlossaryList(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
      child: GlassContainer(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        height: 56,
        borderRadius: 16,
        child: TextField(
          controller: _searchController,
          style: const TextStyle(color: AppColors.textPrimary),
          decoration: InputDecoration(
            hintText: 'Search terms or definitions...',
            hintStyle: TextStyle(
              color: AppColors.textSecondary.withValues(alpha: 0.6),
            ),
            border: InputBorder.none,
            icon: Icon(Icons.search, color: AppColors.accent),
            suffixIcon: _searchController.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear, size: 20),
                    onPressed: _searchController.clear,
                  )
                : null,
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryFilters() {
    return SizedBox(
      height: 50,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: _categories.length,
        itemBuilder: (context, index) {
          final category = _categories[index];
          final isSelected = _selectedCategory == category;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(category),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  _selectedCategory = category;
                  _applyFilters();
                });
              },
              backgroundColor: Colors.transparent,
              selectedColor: AppColors.accent.withValues(alpha: 0.2),
              checkmarkColor: AppColors.accent,
              labelStyle: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? AppColors.accent : AppColors.textSecondary,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(
                  color: isSelected
                      ? AppColors.accent
                      : AppColors.textSecondary.withValues(alpha: 0.2),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildGlossaryList() {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
      itemCount: _filteredItems.length,
      itemBuilder: (context, index) {
        final item = _filteredItems[index];
        final isKnown = _knownItems.contains(item.term);

        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Opacity(
            opacity: isKnown ? 0.6 : 1.0,
            child: GlassContainer(
              borderRadius: 16,
              padding: EdgeInsets.zero,
              child: ExpansionTile(
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.all(Radius.circular(16)),
                ),
                collapsedShape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.all(Radius.circular(16)),
                ),
                tilePadding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                title: Row(
                  children: [
                    Expanded(
                      child: Text(
                        item.term,
                        style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    if (isKnown)
                      Icon(Icons.check_circle,
                          color: AppColors.accent, size: 16),
                  ],
                ),
                subtitle: item.arabic != null
                    ? Text(
                        item.arabic!,
                        style: TextStyle(
                          fontFamily: 'Amiri',
                          fontSize: 18,
                          color: AppColors.accent,
                          height: 1.2,
                        ),
                      )
                    : null,
                trailing: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.accent.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    item.category,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: AppColors.accent,
                    ),
                  ),
                ),
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                    child: Text(
                      item.definition,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        height: 1.6,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton.icon(
                          onPressed: () => _markAsKnown(item.term, !isKnown),
                          icon: Icon(
                            isKnown ? Icons.undo : Icons.check_circle_outline,
                            size: 18,
                          ),
                          label: Text(
                            isKnown ? 'Mark as unknown' : 'I know this',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          style: TextButton.styleFrom(
                            foregroundColor: isKnown
                                ? AppColors.textSecondary
                                : AppColors.accent,
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off_rounded,
            size: 64,
            color: AppColors.textSecondary.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 16),
          Text(
            _hideKnown && _knownItems.isNotEmpty
                ? 'No remaining terms'
                : 'No terms found',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _hideKnown && _knownItems.isNotEmpty
                ? 'You have marked all visible items as known'
                : 'Try adjusting your search or category filter',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              color: AppColors.textSecondary.withValues(alpha: 0.7),
            ),
          ),
          if (_hideKnown && _knownItems.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: ElevatedButton(
                onPressed: _toggleHideKnown,
                child: const Text('Show all items'),
              ),
            ),
        ],
      ),
    );
  }
}
