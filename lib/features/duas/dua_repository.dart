import 'dart:convert';
import 'package:flutter/services.dart';

import 'models/dua_model.dart';
import 'dart:developer' as developer;

class DuaRepository {
  static final DuaRepository _instance = DuaRepository._internal();
  factory DuaRepository() => _instance;

  DuaRepository._internal();

  List<Dua> _duas = [];
  bool _initialized = false;

  /// Retrieves all cached Duas. Initializes if not already done.
  Future<List<Dua>> getAllDuas() async {
    if (!_initialized) {
      await initialize();
    }
    return _duas;
  }

  /// Initializes the repository by loading and parsing `assets/duas.json`.
  Future<void> initialize() async {
    if (_initialized) return;

    try {
      final jsonString = await rootBundle.loadString('assets/duas.json');
      final List<dynamic> jsonList = json.decode(jsonString);

      _duas = jsonList.map((json) => Dua.fromJson(json)).toList();
      _initialized = true;
      developer.log(
        'Successfully loaded ${_duas.length} duas',
        name: 'DuaRepository',
      );
    } catch (e) {
      developer.log(
        'Error loading duas.json: $e',
        name: 'DuaRepository',
        error: e,
      );
      _duas = [];
    }
  }

  /// Finds a specific dua by its unique ID.
  Future<Dua?> getDuaById(String id) async {
    if (!_initialized) {
      await initialize();
    }
    try {
      return _duas.firstWhere((dua) => dua.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Returns duas matching a specific category.
  Future<List<Dua>> getDuasByCategory(String category) async {
    if (!_initialized) {
      await initialize();
    }
    return _duas.where((dua) => dua.category == category).toList();
  }
}
