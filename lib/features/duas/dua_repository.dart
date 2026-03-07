import 'dart:convert';
import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'models/dua_model.dart';

class DuaRepository {
  List<Dua> _duas = [];
  bool _initialized = false;

  /// Retrieves all cached Duas. Initializes if not already done.
  Future<List<Dua>> getAllDuas() async {
    if (!_initialized) {
      await initialize();
    }
    return _duas;
  }

  /// Initializes the repository. Optionally takes a jsonOverride for testing.
  Future<void> initialize({String? jsonOverride}) async {
    if (_initialized && jsonOverride == null) return;

    try {
      final jsonString =
          jsonOverride ?? await rootBundle.loadString('assets/duas.json');
      final jsonList = json.decode(jsonString) as List<dynamic>;

      _duas = jsonList
          .map((json) => Dua.fromJson(json as Map<String, dynamic>))
          .toList();
      _initialized = true;
      if (kDebugMode) {
        developer.log(
          'Successfully loaded ${_duas.length} duas',
          name: 'DuaRepository',
        );
      }
    } catch (e) {
      if (kDebugMode) {
        developer.log(
          'Error loading duas.json: $e',
          name: 'DuaRepository',
          error: e,
        );
      }
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
