import 'dart:convert';
import 'dart:developer' as developer;

import 'package:flutter/services.dart';

import 'models/hadith.dart';

class HadithRepository {
  List<Hadith> _hadiths = [];
  bool _initialized = false;

  /// Retrieves all cached Hadiths. Initializes if not already done.
  Future<List<Hadith>> getAllHadiths() async {
    if (!_initialized) {
      await initialize();
    }
    return _hadiths;
  }

  /// Initializes the repository by loading and parsing `assets/hadith.json`.
  Future<void> initialize() async {
    if (_initialized) return;

    try {
      final jsonString = await rootBundle.loadString('assets/hadith.json');
      final jsonList = json.decode(jsonString) as List<dynamic>;

      _hadiths = jsonList
          .map((json) => Hadith.fromJson(json as Map<String, dynamic>))
          .toList();
      _initialized = true;
      developer.log(
        'Successfully loaded ${_hadiths.length} hadiths',
        name: 'HadithRepository',
      );
    } catch (e) {
      developer.log(
        'Error loading hadith.json: $e',
        name: 'HadithRepository',
        error: e,
      );
      _hadiths = [];
    }
  }

  /// Finds a specific hadith by its unique ID.
  Future<Hadith?> getHadithById(String id) async {
    if (!_initialized) {
      await initialize();
    }
    try {
      return _hadiths.firstWhere((h) => h.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Returns hadiths matching a specific topic.
  Future<List<Hadith>> getHadithsByTopic(String topic) async {
    if (!_initialized) {
      await initialize();
    }
    return _hadiths.where((h) => h.topics.contains(topic)).toList();
  }

  /// Returns hadiths matching a specific collection.
  Future<List<Hadith>> getHadithsByCollection(String collection) async {
    if (!_initialized) {
      await initialize();
    }
    return _hadiths.where((h) => h.collection == collection).toList();
  }
}
