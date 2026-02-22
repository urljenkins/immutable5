import 'package:flutter_test/flutter_test.dart';
import 'package:immutable5/features/quran/quran_text_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('Qur\'an text parses into chapters and verses', () async {
    final service = QuranTextService();
    final chapters = await service.getChapters();

    expect(chapters.length, 114);
    expect(chapters.first.title, 'THE OPENING');
    expect(chapters.first.verses.first, startsWith('1. In the name of Allah'));

    final last = chapters.last;
    expect(last.number, 114);
    expect(last.title, 'MANKIND');
    expect(last.verses.first, startsWith('In the name of Allah'));
  });
}
