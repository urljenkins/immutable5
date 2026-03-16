import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:immutable5/services/cache_manager.dart';
import 'package:mocktail/mocktail.dart';

import 'mocks.dart';

void main() {
  late MockSecureStorageProvider mockPrefs;
  late CacheManager cacheManager;

  setUp(() {
    mockPrefs = MockSecureStorageProvider();
    cacheManager = CacheManager(prefs: mockPrefs);

    // Default metadata stub
    when(
      () => mockPrefs.getString('cache_metadata'),
    ).thenAnswer((_) async => null);
    when(() => mockPrefs.setString(any(), any())).thenAnswer((_) async => {});
    when(() => mockPrefs.remove(any())).thenAnswer((_) async => {});
  });

  group('CacheManager Tests', () {
    test('set stores value and updates metadata', () async {
      const key = 'test_key';
      const value = 'test_value';

      await cacheManager.set(key, value);

      verify(() => mockPrefs.setString(key, value)).called(1);
      verify(() => mockPrefs.setString('cache_metadata', any())).called(1);
    });

    test('get returns null for non-existent key', () async {
      final result = await cacheManager.get('non_existent');
      expect(result, isNull);
    });

    test('get returns null and removes item if expired', () async {
      const key = 'expired_key';
      final metadata = {
        key: {
          'size': 10,
          'expiry': DateTime.now().millisecondsSinceEpoch - 1000,
          'lastAccessed': DateTime.now().millisecondsSinceEpoch - 2000,
        },
      };

      when(
        () => mockPrefs.getString('cache_metadata'),
      ).thenAnswer((_) async => json.encode(metadata));

      final result = await cacheManager.get(key);

      expect(result, isNull);
      verify(() => mockPrefs.remove(key)).called(1);
    });

    test('get returns value and updates lastAccessed if not expired', () async {
      const key = 'valid_key';
      const value = 'valid_value';
      final metadata = {
        key: {
          'size': value.length,
          'expiry': DateTime.now().millisecondsSinceEpoch + 10000,
          'lastAccessed': DateTime.now().millisecondsSinceEpoch - 1000,
        },
      };

      when(
        () => mockPrefs.getString('cache_metadata'),
      ).thenAnswer((_) async => json.encode(metadata));
      when(() => mockPrefs.getString(key)).thenAnswer((_) async => value);

      final result = await cacheManager.get(key);

      expect(result, equals(value));
      verify(() => mockPrefs.setString('cache_metadata', any())).called(1);
    });

    test(
      'clearAll removes all items in metadata and metadata itself',
      () async {
        const key1 = 'key1';
        const key2 = 'key2';
        final metadata = {
          key1: {'size': 10, 'expiry': 1000, 'lastAccessed': 1000},
          key2: {'size': 10, 'expiry': 1000, 'lastAccessed': 1000},
        };

        when(
          () => mockPrefs.getString('cache_metadata'),
        ).thenAnswer((_) async => json.encode(metadata));

        await cacheManager.clearAll();

        verify(() => mockPrefs.remove(key1)).called(1);
        verify(() => mockPrefs.remove(key2)).called(1);
        verify(() => mockPrefs.remove('cache_metadata')).called(1);
      },
    );
  });
}
