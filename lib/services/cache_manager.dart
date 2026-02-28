import 'dart:convert';

import 'package:immutable5/services/secure_storage_provider.dart';
/// Advanced cache manager with TTL, size limits, and automatic cleanup
class CacheManager {
  static final CacheManager _instance = CacheManager._internal();
  factory CacheManager() => _instance;
  CacheManager._internal();

  static const String _cacheMetaKey = 'cache_metadata';
  static const int _maxCacheSize = 5 * 1024 * 1024; // 5MB
  static const int _defaultTTL =
      24 * 60 * 60 * 1000; // 24 hours in milliseconds

  /// Store data in cache with optional TTL
  Future<void> set(String key, String value, {int? ttlMs}) async {
    final prefs = SecureStorageProvider();
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
    final prefs = SecureStorageProvider();
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
    final prefs = SecureStorageProvider();
    await prefs.remove(key);

    final metadata = await _getMetadata();
    metadata.remove(key);
    await _saveMetadata(metadata);
  }

  /// Clear all cache
  Future<void> clearAll() async {
    final prefs = SecureStorageProvider();
    final metadata = await _getMetadata();

    for (final key in metadata.keys) {
      await prefs.remove(key);
    }

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
    final prefs = SecureStorageProvider();

    final keysToRemove = <String>[];

    for (final entry in metadata.entries) {
      if (entry.value['expiry'] < now) {
        keysToRemove.add(entry.key);
      }
    }

    for (final key in keysToRemove) {
      await prefs.remove(key);
      metadata.remove(key);
    }

    await _saveMetadata(metadata);
  }

  // Private methods

  Future<Map<String, dynamic>> _getMetadata() async {
    final prefs = SecureStorageProvider();
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
    final prefs = SecureStorageProvider();
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

    final prefs = SecureStorageProvider();
    int totalSize = metadata.values.fold(
      0,
      (sum, meta) => sum + (meta['size'] as int),
    );

    // Remove oldest entries until under limit
    for (final entry in entries) {
      if (totalSize <= _maxCacheSize * 0.8) break; // Keep at 80% of max

      await prefs.remove(entry.key);
      totalSize -= entry.value['size'] as int;
      metadata.remove(entry.key);
    }

    await _saveMetadata(metadata);
  }
}
