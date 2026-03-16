import 'dart:convert';
import 'package:immutable5/di/service_locator.dart';
import 'package:immutable5/services/secure_storage_provider.dart';

/// Advanced cache manager with TTL, size limits, and automatic cleanup
class CacheManager {
  final SecureStorageProvider _prefs;

  CacheManager({SecureStorageProvider? prefs})
    : _prefs = prefs ?? getIt<SecureStorageProvider>();

  static const String _cacheMetaKey = 'cache_metadata';
  static const int _maxCacheSize = 5 * 1024 * 1024; // 5MB
  static const int _defaultTTL =
      24 * 60 * 60 * 1000; // 24 hours in milliseconds

  /// Store data in cache with optional TTL
  Future<void> set(String key, String value, {int? ttlMs}) async {
    final prefs = _prefs;
    final now = DateTime.now().millisecondsSinceEpoch;
    final expiry = now + (ttlMs ?? _defaultTTL);

    // Store the value
    await prefs.setString(key, value);

    // Update metadata
    final metadata = await _getMetadata();
    metadata[key] = {
      'size': value.length,
      'expiry': expiry,
      'lastAccessed': now,
    };
    await _saveMetadata(metadata);

    // Check cache size and clean if needed
    await _checkAndCleanCache();
  }

  /// Get data from cache if not expired
  Future<String?> get(String key) async {
    final prefs = _prefs;
    final metadata = await _getMetadata();

    if (!metadata.containsKey(key)) {
      return null;
    }

    final meta = metadata[key];
    final now = DateTime.now().millisecondsSinceEpoch;

    // Check if expired
    if (meta!['expiry'] < now) {
      await remove(key);
      return null;
    }

    // Update last accessed time
    meta['lastAccessed'] = now;
    metadata[key] = meta;
    await _saveMetadata(metadata);

    return await prefs.getString(key);
  }

  /// Remove item from cache
  Future<void> remove(String key) async {
    final prefs = _prefs;
    await prefs.remove(key);

    final metadata = await _getMetadata();
    metadata.remove(key);
    await _saveMetadata(metadata);
  }

  /// Clear all cache
  Future<void> clearAll() async {
    final prefs = _prefs;
    final metadata = await _getMetadata();

    // Parallelize removal of all cached items
    await Future.wait(metadata.keys.map((key) => prefs.remove(key)));

    await prefs.remove(_cacheMetaKey);
  }

  /// Get cache statistics
  Future<Map<String, dynamic>> getStats() async {
    final metadata = await _getMetadata();
    int totalSize = 0;
    int expiredCount = 0;
    final now = DateTime.now().millisecondsSinceEpoch;

    for (final meta in metadata.values) {
      totalSize += meta['size'] as int;
      if (meta['expiry'] < now) {
        expiredCount++;
      }
    }

    return {
      'totalItems': metadata.length,
      'totalSizeBytes': totalSize,
      'totalSizeKB': (totalSize / 1024).toStringAsFixed(2),
      'expiredItems': expiredCount,
      'maxSizeBytes': _maxCacheSize,
    };
  }

  /// Clean expired entries
  Future<void> cleanExpired() async {
    final metadata = await _getMetadata();
    final now = DateTime.now().millisecondsSinceEpoch;
    final prefs = _prefs;

    final keysToRemove = <String>[];

    for (final entry in metadata.entries) {
      if (entry.value['expiry'] < now) {
        keysToRemove.add(entry.key);
      }
    }

    if (keysToRemove.isEmpty) return;

    // Parallelize removal of expired items
    await Future.wait(keysToRemove.map((key) => prefs.remove(key)));

    for (final key in keysToRemove) {
      metadata.remove(key);
    }

    await _saveMetadata(metadata);
  }

  // Private methods

  Future<Map<String, dynamic>> _getMetadata() async {
    final prefs = _prefs;
    final metaJson = await prefs.getString(_cacheMetaKey);

    if (metaJson == null) {
      return {};
    }

    try {
      final decoded = json.decode(metaJson) as Map<String, dynamic>;
      return decoded.map(
        (key, value) => MapEntry(key, value as Map<String, dynamic>),
      );
    } catch (e) {
      return {};
    }
  }

  Future<void> _saveMetadata(Map<String, dynamic> metadata) async {
    final prefs = _prefs;
    await prefs.setString(_cacheMetaKey, json.encode(metadata));
  }

  Future<void> _checkAndCleanCache() async {
    final metadata = await _getMetadata();
    int totalSize = 0;

    for (final meta in metadata.values) {
      totalSize += meta['size'] as int;
    }

    if (totalSize > _maxCacheSize) {
      await _evictLRU(metadata);
    }
  }

  Future<void> _evictLRU(Map<String, dynamic> metadata) async {
    // Sort by last accessed time
    final entries = metadata.entries.toList();
    entries.sort((a, b) {
      final aTime = a.value['lastAccessed'] as int;
      final bTime = b.value['lastAccessed'] as int;
      return aTime.compareTo(bTime);
    });

    final prefs = _prefs;
    int totalSize = metadata.values.fold(
      0,
      (sum, meta) => sum + (meta['size'] as int),
    );

    // Identify oldest entries to remove until under limit
    final keysToRemove = <String>[];
    for (final entry in entries) {
      if (totalSize <= _maxCacheSize * 0.8) break; // Keep at 80% of max

      keysToRemove.add(entry.key);
      totalSize -= entry.value['size'] as int;
    }

    if (keysToRemove.isNotEmpty) {
      // Parallelize removal of evicted items
      await Future.wait(keysToRemove.map((key) => prefs.remove(key)));

      for (final key in keysToRemove) {
        metadata.remove(key);
      }
    }

    await _saveMetadata(metadata);
  }
}
