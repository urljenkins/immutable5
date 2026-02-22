import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:csv/csv.dart';
import '../../generated/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CommonWordsPage extends StatefulWidget {
  const CommonWordsPage({super.key});

  @override
  State<CommonWordsPage> createState() => _CommonWordsPageState();
}

class _CommonWordsPageState extends State<CommonWordsPage> {
  static List<List<String>>? _cache;
  Set<int> _memorized = {};
  List<int> _visibleIndices = [];
  List<List<String>> _rows = [];
  bool _loading = true;
  bool _showMemorized = true;
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadCsv();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.toLowerCase();
      });
      _applyFilters();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadCsv() async {
    if (_cache != null) {
      _rows = _cache!;
      _loading = false;
      await _loadMemorized();
      _applyFilters();
      return;
    }
    final data = await rootBundle.loadString('assets/common_words.csv');
    final converter = const CsvToListConverter(fieldDelimiter: ',', eol: '\n');
    final list = converter.convert(data, shouldParseNumbers: false);
    final rows = list.map((e) => e.cast<String>()).toList();
    final dataRows = rows.skip(1).toList(); // drop header row from display
    _cache = dataRows;
    _rows = dataRows;
    _loading = false;
    await _loadMemorized();
    _applyFilters();
  }

  Future<void> _loadMemorized() async {
    final prefs = await SharedPreferences.getInstance();
    final mem = <int>{};
    for (int i = 0; i < _rows.length; i++) {
      if (prefs.getBool('mem_word_${i + 1}') == true) mem.add(i);
    }
    _memorized = mem;
  }

  Future<void> _toggleMemorized(int index) async {
    final prefs = await SharedPreferences.getInstance();
    if (_memorized.contains(index)) {
      _memorized.remove(index);
      await prefs.remove('mem_word_${index + 1}');
    } else {
      _memorized.add(index);
      await prefs.setBool('mem_word_${index + 1}', true);
    }
  }

  void _applyFilters() {
    _visibleIndices = List.generate(_rows.length, (i) => i);
    if (!_showMemorized) {
      _visibleIndices =
          _visibleIndices.where((i) => !_memorized.contains(i)).toList();
    }
    if (_searchQuery.isNotEmpty) {
      _visibleIndices = _visibleIndices.where((i) {
        final row = _rows[i];
        return row[0].contains(_searchQuery) || // Arabic
            row[1].toLowerCase().contains(_searchQuery) || // Transliteration
            row[2].toLowerCase().contains(_searchQuery); // English
      }).toList();
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
        appBar: AppBar(
          title: _isSearching
              ? TextField(
                  controller: _searchController,
                  autofocus: true,
                  decoration: InputDecoration(
                    hintText: AppLocalizations.of(context)!.search,
                    border: InputBorder.none,
                    hintStyle: const TextStyle(color: Colors.white60),
                  ),
                  style: const TextStyle(color: Colors.white, fontSize: 18),
                )
              : Text(AppLocalizations.of(context)!.commonWords),
          actions: [
            if (!_loading) ...[
              IconButton(
                icon: Icon(_isSearching ? Icons.close : Icons.search),
                onPressed: () {
                  setState(() {
                    if (_isSearching) {
                      _searchController.clear();
                      _isSearching = false;
                    } else {
                      _isSearching = true;
                    }
                  });
                },
              ),
              Switch(
                value: _showMemorized,
                onChanged: (value) {
                  setState(() => _showMemorized = value);
                  _applyFilters();
                },
                activeThumbColor: Colors.greenAccent,
              ),
            ],
          ],
        ),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: _visibleIndices.length,
                itemBuilder: (context, i) {
                  final rowIndex = _visibleIndices[i];
                  final row = _rows[rowIndex];
                  final isMemorized = _memorized.contains(rowIndex);

                  return Dismissible(
                    key: ValueKey('word_$rowIndex'),
                    direction: DismissDirection.endToStart,
                    background: Container(
                      decoration: BoxDecoration(
                        color: Colors.green.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: const Icon(Icons.check, color: Colors.green),
                    ),
                    confirmDismiss: (_) async {
                      await _toggleMemorized(rowIndex);
                      if (_showMemorized) {
                        _applyFilters();
                        return false;
                      }
                      setState(() {
                        _visibleIndices.remove(rowIndex);
                      });
                      return true;
                    },
                    child: Opacity(
                      opacity: isMemorized && _showMemorized ? 0.4 : 1,
                      child: Card(
                        margin: const EdgeInsets.symmetric(vertical: 6),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      row[1],
                                      style: const TextStyle(
                                        fontStyle: FontStyle.italic,
                                        fontSize: 15,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      row[2],
                                      style: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 16),
                              Text(
                                row[0],
                                textAlign: TextAlign.right,
                                style: isRtl
                                    ? const TextStyle(
                                        fontFamily: 'Amiri',
                                        fontSize: 22,
                                      )
                                    : const TextStyle(fontSize: 22),
                              ),
                              if (isMemorized) ...[
                                const SizedBox(width: 8),
                                const Icon(Icons.check_circle,
                                    color: Colors.green),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }
}
