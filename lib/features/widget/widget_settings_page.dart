import 'package:flutter/material.dart';
import 'widget_preferences.dart';
import 'prayer_widget_service.dart';

class WidgetSettingsPage extends StatefulWidget {
  const WidgetSettingsPage({super.key});

  @override
  State<WidgetSettingsPage> createState() => _WidgetSettingsPageState();
}

class _WidgetSettingsPageState extends State<WidgetSettingsPage> {
  WidgetTheme _selectedTheme = WidgetTheme.light;
  WidgetLayout _selectedLayout = WidgetLayout.detailed;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final theme = await WidgetPreferences.getTheme();
    final layout = await WidgetPreferences.getLayout();

    setState(() {
      _selectedTheme = theme;
      _selectedLayout = layout;
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

          // Theme Selection
          ListTile(
            title: const Text('Widget Theme'),
            subtitle: Text(_getThemeName(_selectedTheme)),
            trailing: const Icon(Icons.color_lens),
            onTap: () => _showThemeDialog(),
          ),
          const Divider(),

          // Layout Selection
          ListTile(
            title: const Text('Widget Layout'),
            subtitle: Text(_getLayoutName(_selectedLayout)),
            trailing: const Icon(Icons.view_compact),
            onTap: () => _showLayoutDialog(),
          ),
          const Divider(),

          // Preview Section
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              'Preview',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: _buildPreview(),
          ),

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
        ],
      ),
    );
  }

  String _getThemeName(WidgetTheme theme) {
    switch (theme) {
      case WidgetTheme.light:
        return 'Light';
      case WidgetTheme.dark:
        return 'Dark';
      case WidgetTheme.greenAccent:
        return 'Green Accent';
      case WidgetTheme.blueAccent:
        return 'Blue Accent';
    }
  }

  String _getLayoutName(WidgetLayout layout) {
    switch (layout) {
      case WidgetLayout.compact:
        return 'Compact - Next prayer only';
      case WidgetLayout.detailed:
        return 'Detailed - All prayers';
      case WidgetLayout.minimal:
        return 'Minimal - Countdown only';
    }
  }

  void _showThemeDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Widget Theme'),
        content: RadioGroup<WidgetTheme>(
          groupValue: _selectedTheme,
          onChanged: (value) async {
            if (value != null) {
              await WidgetPreferences.setTheme(value);
              if (!mounted) return;
              setState(() => _selectedTheme = value);
              if (context.mounted) Navigator.pop(context);
              await _updateWidget();
            }
          },
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: WidgetTheme.values.map((theme) {
              return RadioListTile<WidgetTheme>(
                title: Text(_getThemeName(theme)),
                value: theme,
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  void _showLayoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Widget Layout'),
        content: RadioGroup<WidgetLayout>(
          groupValue: _selectedLayout,
          onChanged: (value) async {
            if (value != null) {
              await WidgetPreferences.setLayout(value);
              if (!mounted) return;
              setState(() => _selectedLayout = value);
              if (context.mounted) Navigator.pop(context);
              await _updateWidget();
            }
          },
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: WidgetLayout.values.map((layout) {
              return RadioListTile<WidgetLayout>(
                title: Text(_getLayoutName(layout)),
                value: layout,
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildPreview() {
    final colors = WidgetPreferences.getThemeColors(_selectedTheme);
    final bgColor = Color(colors['background'] as int);
    final textColor = Color(colors['text'] as int);
    final accentColor = Color(colors['accent'] as int);
    final cardBgColor = Color(colors['cardBg'] as int);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Prayer Times',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
              Text(
                'Just now',
                style: TextStyle(
                    fontSize: 10, color: textColor.withValues(alpha: 0.6)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: cardBgColor,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Next Prayer',
                  style: TextStyle(
                      fontSize: 12, color: textColor.withValues(alpha: 0.7)),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Fajr',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: accentColor,
                      ),
                    ),
                    Text(
                      '05:30',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: accentColor,
                      ),
                    ),
                  ],
                ),
                Text(
                  'in 2h 30m',
                  style: TextStyle(
                      fontSize: 12, color: textColor.withValues(alpha: 0.6)),
                ),
              ],
            ),
          ),
          if (_selectedLayout == WidgetLayout.detailed) ...[
            const SizedBox(height: 8),
            _buildPrayerRow('Fajr', '05:30', textColor),
            _buildPrayerRow('Dhuhr', '12:45', textColor),
            _buildPrayerRow('Asr', '15:30', textColor),
          ],
        ],
      ),
    );
  }

  Widget _buildPrayerRow(String name, String time, Color textColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(name, style: TextStyle(fontSize: 14, color: textColor)),
          Text(time, style: TextStyle(fontSize: 14, color: textColor)),
        ],
      ),
    );
  }
}
