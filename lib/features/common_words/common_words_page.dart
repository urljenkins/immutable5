import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:csv/csv.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CommonWordsPage extends StatefulWidget {
  const CommonWordsPage({Key? key}) : super(key: key);

  @override
  _CommonWordsPageState createState() => _CommonWordsPageState();
}

class _CommonWordsPageState extends State<CommonWordsPage> {
  static List<List<String>>? _cache;
  Set<int> _favorites = {};
  List<List<String>> _rows = [];
  List<List<String>> _filteredRows = [];
  bool _loading = true;
  String _searchQuery = '';
  String _sortOption = 'Default';

  @override
  void initState() {
    super.initState();
    _loadCsv();
  }

  Future<void> _loadCsv() async {
    if (_cache != null) {
      _rows = _cache!;
      _filteredRows = _rows;
      _loading = false;
      await _loadFavorites();
      setState(() {});
      return;
    }
    final data = await rootBundle.loadString('assets/common_words.csv');
    final converter = const CsvToListConverter(fieldDelimiter: ',', eol: '\n');
    final list = converter.convert(data, shouldParseNumbers: false);
    final rows = list.map((e) => e.cast<String>()).toList();
    _cache = rows;
    _rows = rows;
    _filteredRows = rows;
    _loading = false;
    await _loadFavorites();
    setState(() {});
  }

  Future<void> _loadFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    final favs = <int>{};
    for (int i = 1; i < _rows.length; i++) {
      if (prefs.getBool('fav_word_$i') == true) favs.add(i);
    }
    _favorites = favs;
  }

  Future<void> _toggleFavorite(int index) async {
    final prefs = await SharedPreferences.getInstance();
    if (_favorites.contains(index)) {
      _favorites.remove(index);
      await prefs.remove('fav_word_$index');
    } else {
      _favorites.add(index);
      await prefs.setBool('fav_word_$index', true);
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context);
    final isRtl = locale.languageCode == 'ar';
    return Directionality(
      textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        appBar: AppBar(title: Text(AppLocalizations.of(context)!.commonWords)),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  headingRowHeight: 56,
                  dataRowHeight: 48,
                  columns: [
                    DataColumn(label: Text(AppLocalizations.of(context)!.arabic)),
                    DataColumn(label: Text(AppLocalizations.of(context)!.transliteration)),
                    DataColumn(label: Text(AppLocalizations.of(context)!.english)),
                    DataColumn(label: Icon(Icons.star)),
                  ],
                  rows: List.generate(_filteredRows.length, (i) {
                    final row = _filteredRows[i];
                    return DataRow(
                      cells: [
                        DataCell(Text(row[0], style: isRtl ? TextStyle(fontFamily: 'Amiri') : null)),
                        DataCell(Text(row[1])),
                        DataCell(Text(row[2])),
                        DataCell(IconButton(
                          icon: Icon(_favorites.contains(i) ? Icons.star : Icons.star_border),
                          onPressed: () => _toggleFavorite(i),
                        )),
                      ],
                    );
                  }),
                ),
              ),
      ),
    );
  }
}
