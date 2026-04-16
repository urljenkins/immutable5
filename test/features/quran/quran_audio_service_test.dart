import 'package:flutter_test/flutter_test.dart';
import 'package:immutable5/features/quran/quran_audio_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('QuranAudioService Validation Tests', () {
    late QuranAudioService service;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      service = QuranAudioService();
    });

    test(
      'getSurahAudioData should throw ArgumentError for invalid surahNumber (0)',
      () async {
        // This is expected to FAIL before the fix because no validation exists
        expect(
          () => service.getSurahAudioData(0, 'ar.alafasy'),
          throwsA(isA<ArgumentError>()),
        );
      },
    );

    test(
      'getSurahAudioData should throw ArgumentError for invalid surahNumber (115)',
      () async {
        // This is expected to FAIL before the fix because no validation exists
        expect(
          () => service.getSurahAudioData(115, 'ar.alafasy'),
          throwsA(isA<ArgumentError>()),
        );
      },
    );

    test(
      'getSurahAudioData should throw ArgumentError for invalid reciterId',
      () async {
        // This is expected to FAIL before the fix because no validation exists
        expect(
          () => service.getSurahAudioData(1, 'invalid reciter id!'),
          throwsA(isA<ArgumentError>()),
        );
      },
    );

    test(
      'getSurahAudioData should throw ArgumentError for reciterId with path traversal',
      () async {
        // This is expected to FAIL before the fix because no validation exists
        expect(
          () => service.getSurahAudioData(1, '../ar.alafasy'),
          throwsA(isA<ArgumentError>()),
        );
      },
    );
  });
}
