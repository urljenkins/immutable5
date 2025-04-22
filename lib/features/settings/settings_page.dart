import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({Key? key}) : super(key: key);

  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  static const _keyCalculationMethod = 'calculationMethod';
  static const _keyMadhab = 'madhab';
  static const _keyNotificationsEnabled = 'notificationsEnabled';
  List<String> _methods = [
    'Method 2 (University of Islamic Sciences)',
    'Method 4 (Islamic Society of North America)',
  ];
  List<String> _madhabs = ['Shafi', 'Hanafi', 'Maliki', 'Hanbali'];
  String _calculationMethod = _methods[0];
  String _madhab = 'Shafi';
  bool _notificationsEnabled = true;

  @override
  void initState() {
    super.initState();
    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _calculationMethod = prefs.getString(_keyCalculationMethod) ?? _calculationMethod;
      _madhab = prefs.getString(_keyMadhab) ?? _madhab;
      _notificationsEnabled = prefs.getBool(_keyNotificationsEnabled) ?? _notificationsEnabled;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.settings),
      ),
      body: ListView(
        children: [
          ListTile(
            title: Text(AppLocalizations.of(context)!.calculationMethod),
            subtitle: Text(_calculationMethod),
            onTap: () async {
              final choice = await showDialog<String>(
                  context: context,
                  builder: (_) => SimpleDialog(
                        title: Text(AppLocalizations.of(context)!.selectCalculationMethod),
                        children: _methods
                            .map((m) => RadioListTile(
                                  title: Text(m),
                                  value: m,
                                  groupValue: _calculationMethod,
                                  onChanged: (v) => Navigator.pop(context, v),
                                ))
                            .toList(),
                      ));
              if (choice != null) {
                final prefs = await SharedPreferences.getInstance();
                setState(() => _calculationMethod = choice);
                prefs.setString(_keyCalculationMethod, choice);
              }
            },
          ),
          ListTile(
            title: Text(AppLocalizations.of(context)!.madhab),
            subtitle: Text(_madhab),
            onTap: () async {
              final choice = await showDialog<String>(
                  context: context,
                  builder: (_) => SimpleDialog(
                        title: Text(AppLocalizations.of(context)!.selectMadhab),
                        children: _madhabs
                            .map((m) => RadioListTile(
                                  title: Text(m),
                                  value: m,
                                  groupValue: _madhab,
                                  onChanged: (v) => Navigator.pop(context, v),
                                ))
                            .toList(),
                      ));
              if (choice != null) {
                final prefs = await SharedPreferences.getInstance();
                setState(() => _madhab = choice);
                prefs.setString(_keyMadhab, choice);
              }
            },
          ),
          SwitchListTile(
            title: Text(AppLocalizations.of(context)!.notifications),
            value: _notificationsEnabled,
            onChanged: (value) async {
              final prefs = await SharedPreferences.getInstance();
              setState(() => _notificationsEnabled = value);
              prefs.setBool(_keyNotificationsEnabled, value);
            },
          ),
        ],
      ),
    );
  }
}
