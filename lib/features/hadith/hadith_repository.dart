import 'package:flutter/services.dart';
import 'models/hadith.dart';

class HadithRepository {
  List<Hadith>? _cachedHadiths;
  bool _isLoading = false;

  Future<List<Hadith>> getAllHadiths() async {
    if (_cachedHadiths != null) {
      return _cachedHadiths!;
    }

    if (_isLoading) {
      // Simple wait if already loading (prevent multiple simultaneous reads)
      while (_isLoading) {
        await Future.delayed(const Duration(milliseconds: 50));
      }
      if (_cachedHadiths != null) return _cachedHadiths!;
    }

    _isLoading = true;
    try {
      final jsonString = await rootBundle.loadString('assets/hadith.json');
      _cachedHadiths = Hadith.listFromJsonString(jsonString);
      return _cachedHadiths!;
    } catch (e) {
      // Fallback to empty list or rethrow depending on app policy
      _cachedHadiths = [];
      rethrow;
    } finally {
      _isLoading = false;
    }
  }

  Future<Hadith?> getHadithById(String id) async {
    final hadiths = await getAllHadiths();
    try {
      return hadiths.firstWhere((h) => h.hadithId == id);
    } catch (_) {
      return null; // Not found
    }
  }

  Future<List<Hadith>> searchHadiths(String query) async {
    final hadiths = await getAllHadiths();
    if (query.isEmpty) return hadiths;

    final lowerQuery = query.toLowerCase();
    return hadiths.where((h) {
      return h.translationEn.toLowerCase().contains(lowerQuery) ||
          h.arabic.contains(lowerQuery) ||
          h.topics.any((t) => t.toLowerCase().contains(lowerQuery)) ||
          h.summaryEn.toLowerCase().contains(lowerQuery);
    }).toList();
  }

  Future<List<Hadith>> getHadithsByTopic(String topic) async {
    final hadiths = await getAllHadiths();
    return hadiths.where((h) => h.topics.contains(topic)).toList();
  }

  Future<List<String>> getAllTopics() async {
    final hadiths = await getAllHadiths();
    final topics = <String>{};
    for (final h in hadiths) {
      topics.addAll(h.topics);
    }
    final sortedTopics = topics.toList()..sort();
    return sortedTopics;
  }
}
