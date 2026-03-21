import 'dart:async';
import 'package:flutter/material.dart';

import 'prayer_widget_service.dart';
import 'widget_preferences.dart';

class WidgetSettingsPage extends StatefulWidget {
  const WidgetSettingsPage({super.key});

  @override
  State<WidgetSettingsPage> createState() => _WidgetSettingsPageState();
}

class _WidgetSettingsPageState extends State<WidgetSettingsPage> {
  WidgetTheme _selectedTheme = WidgetTheme.nightSky;

  @override
  void initState() {
    super.initState();
    unawaited(_loadPreferences());
  }

  Future<void> _loadPreferences() async {
    final theme = await WidgetPreferences.getTheme();

    setState(() {
      _selectedTheme = theme;
    });
  }

  Future<void> _updateWidget() async {
    await PrayerWidgetService.updateWidgetWithStoredSettings();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Widget updated!'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Widget Settings'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: ListView(
        children: [
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              'Customize your home screen widget',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),

          // Preview Section
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0),
            child: Text(
              'Preview',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
          ),
          Padding(padding: const EdgeInsets.all(16.0), child: _buildPreview()),

          const Divider(),

          // Theme Selection
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              'Theme',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
          ),
          _buildThemeSelector(),

          const SizedBox(height: 16),

          // Update Button
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton.icon(
              onPressed: _updateWidget,
              icon: const Icon(Icons.refresh),
              label: const Text('Update Widget Now'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.all(16),
              ),
            ),
          ),

          // Instructions
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        size: 18,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'How to add the widget',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '1. Long press on your home screen\n'
                    '2. Tap "Widgets" or "+"\n'
                    '3. Search for "Prayer Times"\n'
                    '4. Drag the widget to your home screen',
                    style: TextStyle(fontSize: 13, height: 1.5),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildThemeSelector() {
    return SizedBox(
      height: 100,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: WidgetTheme.values.length,
        itemBuilder: (context, index) {
          final theme = WidgetTheme.values[index];
          final isSelected = _selectedTheme == theme;
          final colors = WidgetPreferences.getThemeColors(theme);
          final bgColor = Color(colors['background']!);
          final accentColor = Color(colors['accent']!);

          return GestureDetector(
            onTap: () async {
              await WidgetPreferences.setTheme(theme);
              setState(() => _selectedTheme = theme);
              await _updateWidget();
            },
            child: Container(
              width: 80,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected
                      ? Theme.of(context).colorScheme.primary
                      : Colors.grey.shade300,
                  width: isSelected ? 3 : 1,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: accentColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    WidgetPreferences.getThemeName(theme),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.normal,
                      color:
                          colors['text']! == 0xFFFFFFFF ||
                              colors['text']! == 0xFFF8FAFC
                          ? Colors.white
                          : Colors.black87,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPreview() {
    final colors = WidgetPreferences.getThemeColors(_selectedTheme);
    final bgColor = Color(colors['background']!);
    final textColor = Color(colors['text']!);
    final textSecondaryColor = Color(colors['textSecondary']!);
    final accentColor = Color(colors['accent']!);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header Row
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'London',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: textColor,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '15 Rajab 1446',
                        style: TextStyle(
                          fontSize: 11,
                          color: textSecondaryColor,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Maghrib in',
                      style: TextStyle(fontSize: 11, color: textSecondaryColor),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '02:30',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'monospace',
                        color: accentColor,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Divider
          Container(
            height: 1,
            margin: const EdgeInsets.symmetric(horizontal: 16),
            color: textSecondaryColor.withValues(alpha: 0.2),
          ),

          // Prayer Times Row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
            child: Row(
              children: [
                _buildPrayerColumn(
                  'Fajr',
                  '05:57',
                  false,
                  textColor,
                  textSecondaryColor,
                  accentColor,
                ),
                _buildPrayerColumn(
                  'Dhuhr',
                  '12:55',
                  false,
                  textColor,
                  textSecondaryColor,
                  accentColor,
                ),
                _buildPrayerColumn(
                  'Asr',
                  '15:37',
                  false,
                  textColor,
                  textSecondaryColor,
                  accentColor,
                ),
                _buildPrayerColumn(
                  'Maghrib',
                  '18:12',
                  true,
                  textColor,
                  textSecondaryColor,
                  accentColor,
                ),
                _buildPrayerColumn(
                  'Isha',
                  '19:46',
                  false,
                  textColor,
                  textSecondaryColor,
                  accentColor,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrayerColumn(
    String name,
    String time,
    bool isNext,
    Color textColor,
    Color textSecondaryColor,
    Color accentColor,
  ) {
    return Expanded(
      child: Column(
        children: [
          Text(
            name,
            style: TextStyle(
              fontSize: 11,
              fontWeight: isNext ? FontWeight.w600 : FontWeight.normal,
              color: isNext ? accentColor : textSecondaryColor,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            time,
            style: TextStyle(
              fontSize: 13,
              fontWeight: isNext ? FontWeight.bold : FontWeight.w500,
              fontFamily: 'monospace',
              color: isNext ? accentColor : textColor,
            ),
          ),
        ],
      ),
    );
  }
}
