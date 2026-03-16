import 'dart:convert';
import 'dart:async';

// Mocking some simple stuff to avoid Flutter dependencies
class MockSecureStorageProvider {
  final Map<String, String> _storage = {};

  Future<String?> getString(String key) async {
    await Future.delayed(Duration(milliseconds: 10));
    return _storage[key];
  }

  Future<void> setString(String key, String value) async {
    await Future.delayed(Duration(milliseconds: 10));
    _storage[key] = value;
  }

  Future<void> remove(String key) async {
    await Future.delayed(Duration(milliseconds: 10));
    _storage.remove(key);
  }
}

class CacheManager {
  final MockSecureStorageProvider _prefs;

  CacheManager(this._prefs);

  static const String _cacheMetaKey = 'cache_metadata';
  static const int _maxCacheSize = 5 * 1024 * 1024; // 5MB

  Future<void> clearAll(Map<String, dynamic> metadata) async {
    for (final key in metadata.keys) {
      await _prefs.remove(key);
    }
    await _prefs.remove(_cacheMetaKey);
  }

  Future<void> cleanExpired(Map<String, dynamic> metadata) async {
    final keysToRemove = metadata.keys
        .toList(); // Assume all are expired for benchmark
    for (final key in keysToRemove) {
      await _prefs.remove(key);
      metadata.remove(key);
    }
    await _prefs.setString(_cacheMetaKey, json.encode(metadata));
  }

  Future<void> evictLRU(Map<String, dynamic> metadata) async {
    final entries = metadata.entries.toList();
    entries.sort(
      (a, b) => (a.value['lastAccessed'] as int).compareTo(
        b.value['lastAccessed'] as int,
      ),
    );

    int totalSize = metadata.values.fold(
      0,
      (sum, meta) => sum + (meta['size'] as int),
    );

    for (final entry in entries) {
      if (totalSize <= _maxCacheSize * 0.8) break;
      await _prefs.remove(entry.key);
      totalSize -= entry.value['size'] as int;
      metadata.remove(entry.key);
    }
    await _prefs.setString(_cacheMetaKey, json.encode(metadata));
  }
}

// Optimized CacheManager
class OptimizedCacheManager {
  final MockSecureStorageProvider _prefs;

  OptimizedCacheManager(this._prefs);

  static const String _cacheMetaKey = 'cache_metadata';
  static const int _maxCacheSize = 5 * 1024 * 1024; // 5MB

  Future<void> clearAll(Map<String, dynamic> metadata) async {
    await Future.wait(metadata.keys.map((key) => _prefs.remove(key)));
    await _prefs.remove(_cacheMetaKey);
  }

  Future<void> cleanExpired(Map<String, dynamic> metadata) async {
    final keysToRemove = metadata.keys.toList();
    await Future.wait(keysToRemove.map((key) => _prefs.remove(key)));
    for (final key in keysToRemove) {
      metadata.remove(key);
    }
    await _prefs.setString(_cacheMetaKey, json.encode(metadata));
  }

  Future<void> evictLRU(Map<String, dynamic> metadata) async {
    final entries = metadata.entries.toList();
    entries.sort(
      (a, b) => (a.value['lastAccessed'] as int).compareTo(
        b.value['lastAccessed'] as int,
      ),
    );

    int totalSize = metadata.values.fold(
      0,
      (sum, meta) => sum + (meta['size'] as int),
    );

    final keysToRemove = <String>[];
    for (final entry in entries) {
      if (totalSize <= _maxCacheSize * 0.8) break;
      keysToRemove.add(entry.key);
      totalSize -= entry.value['size'] as int;
    }

    await Future.wait(keysToRemove.map((key) => _prefs.remove(key)));
    for (final key in keysToRemove) {
      metadata.remove(key);
    }
    await _prefs.setString(_cacheMetaKey, json.encode(metadata));
  }
}

void main() async {
  const int itemCount = 100;
  final prefs = MockSecureStorageProvider();
  final cache = CacheManager(prefs);
  final optCache = OptimizedCacheManager(prefs);

  print('--- BASELINE ---');
  Map<String, dynamic> metadata = {};
  for (int i = 0; i < itemCount; i++)
    metadata['key_$i'] = {'size': 100 * 1024, 'lastAccessed': i};

  Stopwatch sw = Stopwatch()..start();
  await cache.clearAll(Map.from(metadata));
  print('clearAll: ${sw.elapsedMilliseconds}ms');

  sw.reset();
  sw.start();
  await cache.cleanExpired(Map.from(metadata));
  print('cleanExpired: ${sw.elapsedMilliseconds}ms');

  sw.reset();
  sw.start();
  await cache.evictLRU(Map.from(metadata));
  print('evictLRU: ${sw.elapsedMilliseconds}ms');

  print('\n--- OPTIMIZED ---');
  sw.reset();
  sw.start();
  await optCache.clearAll(Map.from(metadata));
  print('clearAll: ${sw.elapsedMilliseconds}ms');

  sw.reset();
  sw.start();
  await optCache.cleanExpired(Map.from(metadata));
  print('cleanExpired: ${sw.elapsedMilliseconds}ms');

  sw.reset();
  sw.start();
  await optCache.evictLRU(Map.from(metadata));
  print('evictLRU: ${sw.elapsedMilliseconds}ms');
}
