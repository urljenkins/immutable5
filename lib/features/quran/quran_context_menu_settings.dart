import 'package:immutable5/services/secure_storage_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Which actions to show in the Quran long-press context menu.
class QuranContextMenuSettings {
  const QuranContextMenuSettings({
    this.showCopy = true,
    this.showBookmark = true,
    this.showShare = true,
    this.showAyahInfo = true,
  });

  final bool showCopy;
  final bool showBookmark;
  final bool showShare;
  final bool showAyahInfo;

  // ── SharedPreferences keys ────────────────────────────────────────────────
  static const _kCopy = 'quranCtxMenu_copy';
  static const _kBookmark = 'quranCtxMenu_bookmark';
  static const _kShare = 'quranCtxMenu_share';
  static const _kAyahInfo = 'quranCtxMenu_ayahInfo';

  static Future<QuranContextMenuSettings> fromPrefs() async {
    final prefs = await SharedPreferences.getInstance();

    // Migration from SecureStorageProvider
    final migrated = prefs.getBool('quranCtxMenu_migrated') ?? false;
    if (!migrated) {
      final securePrefs = SecureStorageProvider();
      final oldCopy = await securePrefs.getBool(_kCopy);
      if (oldCopy != null) {
        await prefs.setBool(_kCopy, oldCopy);
        await prefs.setBool(
          _kBookmark,
          await securePrefs.getBool(_kBookmark) ?? true,
        );
        await prefs.setBool(
          _kShare,
          await securePrefs.getBool(_kShare) ?? true,
        );
        await prefs.setBool(
          _kAyahInfo,
          await securePrefs.getBool(_kAyahInfo) ?? true,
        );

        // Clean up old values
        await securePrefs.remove(_kCopy);
        await securePrefs.remove(_kBookmark);
        await securePrefs.remove(_kShare);
        await securePrefs.remove(_kAyahInfo);
      }
      await prefs.setBool('quranCtxMenu_migrated', true);
    }

    return QuranContextMenuSettings(
      showCopy: prefs.getBool(_kCopy) ?? true,
      showBookmark: prefs.getBool(_kBookmark) ?? true,
      showShare: prefs.getBool(_kShare) ?? true,
      showAyahInfo: prefs.getBool(_kAyahInfo) ?? true,
    );
  }

  Future<void> save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kCopy, showCopy);
    await prefs.setBool(_kBookmark, showBookmark);
    await prefs.setBool(_kShare, showShare);
    await prefs.setBool(_kAyahInfo, showAyahInfo);
  }

  QuranContextMenuSettings copyWith({
    bool? showCopy,
    bool? showBookmark,
    bool? showShare,
    bool? showAyahInfo,
  }) => QuranContextMenuSettings(
    showCopy: showCopy ?? this.showCopy,
    showBookmark: showBookmark ?? this.showBookmark,
    showShare: showShare ?? this.showShare,
    showAyahInfo: showAyahInfo ?? this.showAyahInfo,
  );
}
