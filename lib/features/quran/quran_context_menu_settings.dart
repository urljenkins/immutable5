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

  factory QuranContextMenuSettings.fromPrefs(SharedPreferences prefs) =>
      QuranContextMenuSettings(
        showCopy: prefs.getBool(_kCopy) ?? true,
        showBookmark: prefs.getBool(_kBookmark) ?? true,
        showShare: prefs.getBool(_kShare) ?? true,
        showAyahInfo: prefs.getBool(_kAyahInfo) ?? true,
      );

  Future<void> save(SharedPreferences prefs) async {
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
  }) =>
      QuranContextMenuSettings(
        showCopy: showCopy ?? this.showCopy,
        showBookmark: showBookmark ?? this.showBookmark,
        showShare: showShare ?? this.showShare,
        showAyahInfo: showAyahInfo ?? this.showAyahInfo,
      );
}
