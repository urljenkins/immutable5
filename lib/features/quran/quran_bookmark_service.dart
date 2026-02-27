import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// A single bookmarked verse.
class QuranBookmark {
  const QuranBookmark({
    required this.surahNumber,
    required this.surahTitle,
    required this.verseIndex,
    required this.verseText,
    required this.savedAt,
  });

  final int surahNumber;
  final String surahTitle;
  final int verseIndex; // 0-based index within the chapter
  final String verseText;
  final DateTime savedAt;

  Map<String, dynamic> toJson() => {
    'surahNumber': surahNumber,
    'surahTitle': surahTitle,
    'verseIndex': verseIndex,
    'verseText': verseText,
    'savedAt': savedAt.toIso8601String(),
  };

  factory QuranBookmark.fromJson(Map<String, dynamic> json) => QuranBookmark(
    surahNumber: json['surahNumber'] as int,
    surahTitle: json['surahTitle'] as String,
    verseIndex: json['verseIndex'] as int,
    verseText: json['verseText'] as String,
    savedAt: DateTime.parse(json['savedAt'] as String),
  );

  @override
  bool operator ==(Object other) =>
      other is QuranBookmark &&
      other.surahNumber == surahNumber &&
      other.verseIndex == verseIndex;

  @override
  int get hashCode => Object.hash(surahNumber, verseIndex);
}

/// Manages Quran verse bookmarks persisted via [SharedPreferences].
///
/// Subscribe to [bookmarks] to receive reactive updates.
class QuranBookmarkService {
  QuranBookmarkService._();
  static final QuranBookmarkService instance = QuranBookmarkService._();

  static const _prefsKey = 'quranBookmarks';

  /// Reactive list of bookmarks, sorted newest-first.
  final ValueNotifier<List<QuranBookmark>> bookmarks = ValueNotifier(const []);

  /// Call once at app / page startup.
  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefsKey);
    if (raw == null) return;
    try {
      final list =
          (jsonDecode(raw) as List)
              .cast<Map<String, dynamic>>()
              .map(QuranBookmark.fromJson)
              .toList()
            ..sort((a, b) => b.savedAt.compareTo(a.savedAt));
      bookmarks.value = list;
    } catch (_) {
      // Corrupted data — ignore.
    }
  }

  bool isBookmarked(int surahNumber, int verseIndex) => bookmarks.value.any(
    (b) => b.surahNumber == surahNumber && b.verseIndex == verseIndex,
  );

  /// Adds a bookmark; no-op if already present. Returns `true` if added.
  Future<bool> add(QuranBookmark bookmark) async {
    if (isBookmarked(bookmark.surahNumber, bookmark.verseIndex)) return false;
    final updated = [bookmark, ...bookmarks.value];
    bookmarks.value = updated;
    await _persist();
    return true;
  }

  /// Removes a bookmark. Returns `true` if removed.
  Future<bool> remove(int surahNumber, int verseIndex) async {
    final before = bookmarks.value.length;
    final updated = bookmarks.value
        .where(
          (b) => !(b.surahNumber == surahNumber && b.verseIndex == verseIndex),
        )
        .toList();
    if (updated.length == before) return false;
    bookmarks.value = updated;
    await _persist();
    return true;
  }

  /// Toggles bookmark; returns `true` if now bookmarked.
  Future<bool> toggle(QuranBookmark bookmark) async {
    if (isBookmarked(bookmark.surahNumber, bookmark.verseIndex)) {
      await remove(bookmark.surahNumber, bookmark.verseIndex);
      return false;
    } else {
      await add(bookmark);
      return true;
    }
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(bookmarks.value.map((b) => b.toJson()).toList());
    await prefs.setString(_prefsKey, encoded);
  }
}
