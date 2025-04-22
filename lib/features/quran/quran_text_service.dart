import 'package:flutter/services.dart';

/// Service for loading the Qur'an as plain text from assets.
class QuranTextService {
  String? _fullText;

  Future<void> _load() async {
    if (_fullText != null) return;
    _fullText = await rootBundle.loadString('assets/quran.txt');
  }

  /// Returns the entire Qur'an text.
  Future<String> getFullText() async {
    await _load();
    return _fullText ?? '';
  }

  /// Returns the text split by lines (e.g., verses).
  Future<List<String>> getLines() async {
    final txt = await getFullText();
    return txt.split('\n');
  }
}
