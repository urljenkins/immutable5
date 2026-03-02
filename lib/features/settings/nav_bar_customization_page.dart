import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../main.dart';
import '../../services/secure_storage_provider.dart';
import '../../shared/app_colors.dart';

/// A page that lets the user reorder, show/hide, and configure the
/// maximum number of visible tabs in the bottom navigation bar.
class NavBarCustomizationPage extends StatefulWidget {
  const NavBarCustomizationPage({super.key});

  @override
  State<NavBarCustomizationPage> createState() =>
      _NavBarCustomizationPageState();
}

class _NavBarCustomizationPageState extends State<NavBarCustomizationPage> {
  late List<NavTabEntry> _tabs;
  late int _maxVisible;

  // Canonical label + icon lookup — order doesn't matter here,
  // the list itself carries the order.
  static const Map<String, _TabMeta> _meta = {
    'home': _TabMeta(Icons.home, 'Home'),
    'track': _TabMeta(Icons.check_circle, 'Track'),
    'places': _TabMeta(Icons.map, 'Places'),
    'qibla': _TabMeta(Icons.explore, 'Qibla'),
    'calendar': _TabMeta(Icons.calendar_today, 'Calendar'),
    'hajj': _TabMeta(Icons.directions_walk, 'Hajj'),
    'common_words': _TabMeta(Icons.translate, 'Common Words'),
    'tasbih': _TabMeta(Icons.fingerprint, 'Tasbih'),
    'duas': _TabMeta(Icons.menu_book, 'Duas'),
    'quran': _TabMeta(Icons.book, 'Quran'),
    'settings': _TabMeta(Icons.settings, 'Settings'),
  };

  @override
  void initState() {
    super.initState();
    final config = navBarConfigNotifier.value;
    _tabs = config.tabs
        .map((t) => NavTabEntry(id: t.id, visible: t.visible))
        .toList();
    _maxVisible = config.maxVisibleTabs;
  }

  Future<void> _save() async {
    final config = NavBarConfig(tabs: _tabs, maxVisibleTabs: _maxVisible);
    navBarConfigNotifier.value = config;
    await config.save(SecureStorageProvider());
  }

  bool _isPinned(String id) => NavBarConfig.pinnedIds.contains(id);

  @override
  Widget build(BuildContext context) {
    // Separate pinned-top (home), reorderable middle, and pinned-bottom (settings).
    final homeEntry = _tabs.firstWhere((t) => t.id == 'home');
    final settingsEntry = _tabs.firstWhere((t) => t.id == 'settings');
    final reorderable = _tabs.where((t) => !_isPinned(t.id)).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Customize Bottom Bar',
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Column(
        children: [
          // ── Max visible slider ─────────────────────────────────────────
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
            child: Row(
              children: [
                Text(
                  'Icons in bar',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    color: AppColors.textPrimary,
                  ),
                ),
                const Spacer(),
                Text(
                  '$_maxVisible',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.accent,
                  ),
                ),
              ],
            ),
          ),
          SliderTheme(
            data: SliderThemeData(
              activeTrackColor: AppColors.accent,
              thumbColor: AppColors.accent,
              inactiveTrackColor:
                  AppColors.textSecondary.withValues(alpha: 0.2),
              overlayColor: AppColors.accent.withValues(alpha: 0.15),
            ),
            child: Slider(
              min: 3,
              max: 6,
              divisions: 3,
              value: _maxVisible.toDouble(),
              onChanged: (v) {
                setState(() => _maxVisible = v.round());
                _save();
              },
            ),
          ),
          const Divider(height: 1),

          // ── Hint text ──────────────────────────────────────────────────
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
            child: Text(
              'Drag to reorder · Toggle to show/hide',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
          ),

          // ── Tab list ───────────────────────────────────────────────────
          Expanded(
            child: ListView(
              padding: const EdgeInsets.only(bottom: 120),
              children: [
                // Pinned: Home (always first)
                _buildPinnedTile(homeEntry),
                const Divider(height: 1, indent: 24, endIndent: 24),

                // Reorderable middle items
                ReorderableListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  buildDefaultDragHandles: false,
                  itemCount: reorderable.length,
                  proxyDecorator: (child, index, animation) {
                    return AnimatedBuilder(
                      animation: animation,
                      builder: (ctx, child) => Material(
                        color: AppColors.cardSurface,
                        elevation: 6,
                        borderRadius: BorderRadius.circular(12),
                        child: child,
                      ),
                      child: child,
                    );
                  },
                  onReorder: (oldIdx, newIdx) {
                    setState(() {
                      if (newIdx > oldIdx) newIdx--;
                      final item = reorderable.removeAt(oldIdx);
                      reorderable.insert(newIdx, item);
                      // Rebuild _tabs: home + reorderable + settings
                      _tabs = [
                        homeEntry,
                        ...reorderable,
                        settingsEntry,
                      ];
                    });
                    _save();
                  },
                  itemBuilder: (context, index) {
                    final entry = reorderable[index];
                    final meta = _meta[entry.id]!;
                    return _ReorderableTile(
                      key: ValueKey(entry.id),
                      index: index,
                      icon: meta.icon,
                      label: meta.label,
                      visible: entry.visible,
                      onToggle: (val) {
                        setState(() {
                          final tabIndex =
                              _tabs.indexWhere((t) => t.id == entry.id);
                          _tabs[tabIndex] =
                              _tabs[tabIndex].copyWith(visible: val);
                          // Also update the local reorderable list reference
                          reorderable[index] =
                              reorderable[index].copyWith(visible: val);
                        });
                        _save();
                      },
                    );
                  },
                ),

                const Divider(height: 1, indent: 24, endIndent: 24),
                // Pinned: Settings (always last)
                _buildPinnedTile(settingsEntry),
              ],
            ),
          ),

          // ── Live preview strip ─────────────────────────────────────────
          _buildPreviewStrip(),
        ],
      ),
    );
  }

  Widget _buildPinnedTile(NavTabEntry entry) {
    final meta = _meta[entry.id]!;
    return ListTile(
      leading: Icon(meta.icon, color: AppColors.accent),
      title: Text(
        meta.label,
        style: GoogleFonts.plusJakartaSans(color: AppColors.textPrimary),
      ),
      trailing: Padding(
        padding: const EdgeInsets.only(right: 8.0),
        child: Icon(
          Icons.lock_outline,
          size: 18,
          color: AppColors.textSecondary.withValues(alpha: 0.5),
        ),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 24),
    );
  }

  Widget _buildPreviewStrip() {
    final visible = _tabs.where((t) => t.visible).toList();
    final barCount =
        visible.length <= _maxVisible ? visible.length : _maxVisible;
    final barEntries = visible.sublist(0, barCount);
    final hasOverflow = visible.length > _maxVisible;

    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      decoration: BoxDecoration(
        color: AppColors.cardSurface.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.1),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          ...barEntries.map((e) {
            final meta = _meta[e.id]!;
            return Padding(
              padding: const EdgeInsets.all(8.0),
              child: Icon(meta.icon, size: 22, color: AppColors.textSecondary),
            );
          }),
          if (hasOverflow)
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: Icon(
                Icons.more_horiz,
                size: 22,
                color: AppColors.textSecondary,
              ),
            ),
        ],
      ),
    );
  }
}

// ── Helper widgets & data ────────────────────────────────────────────────────

class _TabMeta {
  final IconData icon;
  final String label;
  const _TabMeta(this.icon, this.label);
}

class _ReorderableTile extends StatelessWidget {
  final int index;
  final IconData icon;
  final String label;
  final bool visible;
  final ValueChanged<bool> onToggle;

  const _ReorderableTile({
    super.key,
    required this.index,
    required this.icon,
    required this.label,
    required this.visible,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(
        icon,
        color: visible
            ? AppColors.accent
            : AppColors.textSecondary.withValues(alpha: 0.4),
      ),
      title: Text(
        label,
        style: GoogleFonts.plusJakartaSans(
          color: visible ? AppColors.textPrimary : AppColors.textSecondary,
        ),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Switch(
            value: visible,
            activeColor: AppColors.accent,
            onChanged: onToggle,
          ),
          ReorderableDragStartListener(
            index: index,
            child: const Icon(
              Icons.drag_handle,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 24),
    );
  }
}
