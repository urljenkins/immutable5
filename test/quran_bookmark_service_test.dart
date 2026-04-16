import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:immutable5/features/quran/quran_bookmark_service.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'mocks.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('QuranBookmark model', () {
    final now = DateTime(2023, 10, 27, 10, 0);
    final bookmark = QuranBookmark(
      surahNumber: 1,
      surahTitle: 'Al-Fatiha',
      verseIndex: 0,
      verseText: 'In the name of Allah...',
      savedAt: now,
    );

    test('toJson and fromJson', () {
      final json = bookmark.toJson();
      expect(json['surahNumber'], 1);
      expect(json['surahTitle'], 'Al-Fatiha');
      expect(json['verseIndex'], 0);
      expect(json['verseText'], 'In the name of Allah...');
      expect(json['savedAt'], now.toIso8601String());

      final fromJson = QuranBookmark.fromJson(json);
      expect(fromJson.surahNumber, bookmark.surahNumber);
      expect(fromJson.surahTitle, bookmark.surahTitle);
      expect(fromJson.verseIndex, bookmark.verseIndex);
      expect(fromJson.verseText, bookmark.verseText);
      expect(fromJson.savedAt, bookmark.savedAt);
    });

    test('equality and hashCode', () {
      final bookmark2 = QuranBookmark(
        surahNumber: 1,
        surahTitle: 'Al-Fatiha',
        verseIndex: 0,
        verseText: 'Different text',
        savedAt: DateTime.now(),
      );
      final bookmark3 = QuranBookmark(
        surahNumber: 2,
        surahTitle: 'Al-Baqarah',
        verseIndex: 0,
        verseText: 'In the name of Allah...',
        savedAt: now,
      );

      expect(bookmark, equals(bookmark2));
      expect(bookmark.hashCode, equals(bookmark2.hashCode));
      expect(bookmark, isNot(equals(bookmark3)));
    });
  });

  group('QuranBookmarkService', () {
    late MockSecureStorageProvider mockSecureStorage;
    late QuranBookmarkService service;
    const prefsKey = 'quranBookmarks';

    setUp(() {
      mockSecureStorage = MockSecureStorageProvider();
      service = QuranBookmarkService(secureStorage: mockSecureStorage);
      SharedPreferences.setMockInitialValues(<String, Object>{});

      when(() => mockSecureStorage.getString(any()))
          .thenAnswer((_) async => null);
      when(() => mockSecureStorage.remove(any())).thenAnswer((_) async => {});
    });

    test('load() should load from SharedPreferences if available', () async {
      final now = DateTime(2023, 10, 27);
      final bookmark = QuranBookmark(
        surahNumber: 1,
        surahTitle: 'Al-Fatiha',
        verseIndex: 0,
        verseText: 'Text',
        savedAt: now,
      );
      final encoded = jsonEncode(<Map<String, dynamic>>[bookmark.toJson()]);
      SharedPreferences.setMockInitialValues(<String, Object>{prefsKey: encoded});

      await service.load();

      expect(service.bookmarks.value.length, 1);
      expect(service.bookmarks.value.first, bookmark);
    });

    test(
        'load() should migrate from SecureStorageProvider to SharedPreferences',
        () async {
      final now = DateTime(2023, 10, 27);
      final bookmark = QuranBookmark(
        surahNumber: 1,
        surahTitle: 'Al-Fatiha',
        verseIndex: 0,
        verseText: 'Text',
        savedAt: now,
      );
      final encoded = jsonEncode(<Map<String, dynamic>>[bookmark.toJson()]);

      when(() => mockSecureStorage.getString(prefsKey))
          .thenAnswer((_) async => encoded);
      when(() => mockSecureStorage.remove(prefsKey)).thenAnswer((_) async => {});

      await service.load();

      expect(service.bookmarks.value.length, 1);
      expect(service.bookmarks.value.first, bookmark);

      verify(() => mockSecureStorage.getString(prefsKey)).called(1);
      verify(() => mockSecureStorage.remove(prefsKey)).called(1);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString(prefsKey), encoded);
    });

    test('load() should sort bookmarks by savedAt newest-first', () async {
      final oldDate = DateTime(2023, 10, 20);
      final newDate = DateTime(2023, 10, 27);
      final oldBookmark = QuranBookmark(
        surahNumber: 1,
        surahTitle: 'Al-Fatiha',
        verseIndex: 0,
        verseText: 'Old',
        savedAt: oldDate,
      );
      final newBookmark = QuranBookmark(
        surahNumber: 2,
        surahTitle: 'Al-Baqarah',
        verseIndex: 0,
        verseText: 'New',
        savedAt: newDate,
      );

      final encoded = jsonEncode(
        <Map<String, dynamic>>[oldBookmark.toJson(), newBookmark.toJson()],
      );
      SharedPreferences.setMockInitialValues(<String, Object>{prefsKey: encoded});

      await service.load();

      expect(service.bookmarks.value.length, 2);
      expect(service.bookmarks.value.first, newBookmark);
      expect(service.bookmarks.value.last, oldBookmark);
    });

    test('isBookmarked() returns true if verse is in bookmarks', () async {
      final bookmark = QuranBookmark(
        surahNumber: 1,
        surahTitle: 'Al-Fatiha',
        verseIndex: 0,
        verseText: 'Text',
        savedAt: DateTime.now(),
      );
      service.bookmarks.value = [bookmark];

      expect(service.isBookmarked(1, 0), isTrue);
      expect(service.isBookmarked(1, 1), isFalse);
      expect(service.isBookmarked(2, 0), isFalse);
    });

    test('add() adds a bookmark and persists', () async {
      final bookmark = QuranBookmark(
        surahNumber: 1,
        surahTitle: 'Al-Fatiha',
        verseIndex: 0,
        verseText: 'Text',
        savedAt: DateTime.now(),
      );

      final result = await service.add(bookmark);

      expect(result, isTrue);
      expect(service.bookmarks.value.length, 1);
      expect(service.bookmarks.value.first, bookmark);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString(prefsKey), isNotNull);
    });

    test('add() does not add duplicate bookmark', () async {
      final bookmark = QuranBookmark(
        surahNumber: 1,
        surahTitle: 'Al-Fatiha',
        verseIndex: 0,
        verseText: 'Text',
        savedAt: DateTime.now(),
      );
      service.bookmarks.value = [bookmark];

      final result = await service.add(bookmark);

      expect(result, isFalse);
      expect(service.bookmarks.value.length, 1);
    });

    test('remove() removes bookmark and persists', () async {
      final bookmark = QuranBookmark(
        surahNumber: 1,
        surahTitle: 'Al-Fatiha',
        verseIndex: 0,
        verseText: 'Text',
        savedAt: DateTime.now(),
      );
      service.bookmarks.value = [bookmark];

      final result = await service.remove(1, 0);

      expect(result, isTrue);
      expect(service.bookmarks.value, isEmpty);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString(prefsKey), jsonEncode([]));
    });

    test('remove() returns false if bookmark not found', () async {
      final result = await service.remove(1, 0);
      expect(result, isFalse);
    });

    test('toggle() adds or removes bookmark', () async {
      final bookmark = QuranBookmark(
        surahNumber: 1,
        surahTitle: 'Al-Fatiha',
        verseIndex: 0,
        verseText: 'Text',
        savedAt: DateTime.now(),
      );

      // Toggle to add
      final added = await service.toggle(bookmark);
      expect(added, isTrue);
      expect(service.isBookmarked(1, 0), isTrue);

      // Toggle to remove
      final removed = await service.toggle(bookmark);
      expect(removed, isFalse);
      expect(service.isBookmarked(1, 0), isFalse);
    });
  });
}
