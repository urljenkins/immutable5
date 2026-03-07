// Handles logic for selecting a context-sensitive quote.

import 'dart:math';

import 'package:csv/csv.dart';
import 'package:flutter/services.dart';

import 'quote.dart';

/// Loads quotes from assets/quotes.csv and picks a random one.
class QuotePickerService {
  List<Quote>? _quotes;

  Future<void> _loadQuotes() async {
    if (_quotes != null) return;
    final raw = await rootBundle.loadString('assets/quotes.csv');
    final rows = const CsvToListConverter().convert(raw, eol: '\n');
    _quotes = rows.skip(1).map((row) {
      final source = row[0].toString();
      final text = row[1].toString();
      final topics = row[2].toString().split(';').map((s) => s.trim()).toList();
      return Quote(source: source, text: text, topics: topics);
    }).toList();
  }

  /// Returns list of all unique topics.
  Future<List<String>> getTopics() async {
    await _loadQuotes();
    final topicsSet = <String>{};
    for (final q in _quotes!) {
      topicsSet.addAll(q.topics);
    }
    final topics = topicsSet.toList()..sort();
    return topics;
  }

  /// Returns a random quote, optionally filtered by topic.
  Future<String> getQuote({String? topic}) async {
    await _loadQuotes();
    if (_quotes == null || _quotes!.isEmpty) return '';
    var list = _quotes!;
    if (topic != null && topic.isNotEmpty) {
      list = list.where((q) => q.topics.contains(topic)).toList();
    }
    if (list.isEmpty) {
      list = _quotes!;
    }
    final rnd = Random();
    final q = list[rnd.nextInt(list.length)];
    return '"${q.text}"\n— ${q.source}';
  }
}
