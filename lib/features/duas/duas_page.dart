import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:csv/csv.dart';

class DuasPage extends StatefulWidget {
  const DuasPage({Key? key}) : super(key: key);

  @override
  State<DuasPage> createState() => _DuasPageState();
}

class _DuasPageState extends State<DuasPage> {
  List<Map<String, String>> _duas = [];
  List<Map<String, String>> _filteredDuas = [];
  List<String> _categories = ['All'];
  String _selectedCategory = 'All';
  bool _loading = true;
  Set<int> _favorites = {};

  @override
  void initState() {
    super.initState();
    _loadDuas();
  }

  Future<void> _loadDuas() async {
    try {
      final csvString = await rootBundle.loadString('assets/duas.csv');
      final List<List<dynamic>> rowsAsListOfValues =
          const CsvToListConverter().convert(csvString);

      final List<Map<String, String>> duas = [];
      final Set<String> categories = {};

      // Skip header row
      for (int i = 1; i < rowsAsListOfValues.length; i++) {
        final row = rowsAsListOfValues[i];
        if (row.length >= 5) {
          duas.add({
            'category': row[0].toString(),
            'arabic': row[1].toString(),
            'transliteration': row[2].toString(),
            'translation': row[3].toString(),
            'occasion': row[4].toString(),
          });
          categories.add(row[0].toString());
        }
      }

      setState(() {
        _duas = duas;
        _filteredDuas = duas;
        _categories = ['All', ...categories.toList()..sort()];
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _loading = false;
      });
    }
  }

  void _filterByCategory(String category) {
    setState(() {
      _selectedCategory = category;
      if (category == 'All') {
        _filteredDuas = _duas;
      } else {
        _filteredDuas = _duas.where((dua) => dua['category'] == category).toList();
      }
    });
  }

  void _toggleFavorite(int index) {
    setState(() {
      if (_favorites.contains(index)) {
        _favorites.remove(index);
      } else {
        _favorites.add(index);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Daily Duas'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Category Filter
                Container(
                  height: 60,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    itemCount: _categories.length,
                    itemBuilder: (context, index) {
                      final category = _categories[index];
                      final isSelected = category == _selectedCategory;
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: FilterChip(
                          label: Text(category),
                          selected: isSelected,
                          onSelected: (_) => _filterByCategory(category),
                          selectedColor: Theme.of(context).colorScheme.primary,
                          labelStyle: TextStyle(
                            color: isSelected ? Colors.white : null,
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const Divider(height: 1),

                // Duas List
                Expanded(
                  child: _filteredDuas.isEmpty
                      ? const Center(child: Text('No duas found'))
                      : ListView.builder(
                          itemCount: _filteredDuas.length,
                          itemBuilder: (context, index) {
                            final dua = _filteredDuas[index];
                            final actualIndex = _duas.indexOf(dua);
                            return _buildDuaCard(dua, actualIndex);
                          },
                        ),
                ),
              ],
            ),
    );
  }

  Widget _buildDuaCard(Map<String, String> dua, int index) {
    final isFavorite = _favorites.contains(index);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header with category and favorite
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getCategoryColor(dua['category']!),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    dua['category']!,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(
                    isFavorite ? Icons.bookmark : Icons.bookmark_border,
                    color: isFavorite ? Colors.amber : null,
                  ),
                  onPressed: () => _toggleFavorite(index),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Occasion
            Text(
              dua['occasion']!,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
                fontStyle: FontStyle.italic,
              ),
            ),
            const SizedBox(height: 12),

            // Arabic Text
            Text(
              dua['arabic']!,
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontSize: 24,
                fontFamily: 'Amiri',
                height: 2,
              ),
            ),
            const SizedBox(height: 12),

            // Transliteration
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                dua['transliteration']!,
                style: TextStyle(
                  fontSize: 14,
                  fontStyle: FontStyle.italic,
                  color: Colors.grey[800],
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Translation
            Text(
              dua['translation']!,
              style: const TextStyle(
                fontSize: 15,
                height: 1.5,
              ),
            ),

            // Copy Button
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                icon: const Icon(Icons.copy, size: 16),
                label: const Text('Copy'),
                onPressed: () {
                  Clipboard.setData(ClipboardData(
                    text: '${dua['arabic']}\n\n${dua['transliteration']}\n\n${dua['translation']}',
                  ));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Dua copied to clipboard'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'Morning':
        return Colors.orange;
      case 'Evening':
        return Colors.deepPurple;
      case 'Before Eating':
      case 'After Eating':
        return Colors.green;
      case 'Travel':
        return Colors.blue;
      case 'Entering Masjid':
      case 'Leaving Masjid':
        return Colors.teal;
      case 'Seeking Knowledge':
        return Colors.indigo;
      case 'Difficulty':
        return Colors.red[700]!;
      case 'Protection':
        return Colors.brown;
      default:
        return Colors.grey;
    }
  }
}
