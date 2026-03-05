import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
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

  final TextEditingController _searchController = TextEditingController();

  List<String> get _categories => [
        'All',
        ...{..._allItem.map((item) => item.category)},
      ];

  @override
  void initState() {
    super.initState();
    _loadGlossary();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadGlossary() async {
    final String response = await rootBundle.loadString('assets/glossary.json');
    final data = await json.decode(response) as List;
    setState(() {
      _allItem = data.map((json) => GlossaryItem.fromJson(json)).toList();
      _filteredItems = _allItem;
      _loading = false;
    });
  }

  void _onSearchChanged() {
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
        return matchesSearch && matchesCategory;
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
                    onPressed: () => _searchController.clear(),
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
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
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
              title: Text(
                item.term,
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                  color: AppColors.textPrimary,
                ),
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
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                  child: Text(
                    item.definition,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      height: 1.6,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ],
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
            'No terms found',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Try adjusting your search or category filter',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              color: AppColors.textSecondary.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }
}
