import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:immutable5/features/hadith/hadith_repository.dart';

class MockAssetBundle extends Mock implements AssetBundle {}

void main() {
  group('HadithRepository Error Handling', () {
    late HadithRepository repository;
    late MockAssetBundle mockBundle;

    setUp(() {
      mockBundle = MockAssetBundle();
      repository = HadithRepository(bundle: mockBundle);
    });

    test('fallback to empty list when loadString throws exception', () async {
      when(
        () => mockBundle.loadString('assets/hadith.json'),
      ).thenThrow(Exception('Failed to load asset'));

      await repository.initialize();
      final hadiths = await repository.getAllHadiths();

      expect(hadiths, isEmpty);
    });

    test('fallback to empty list when JSON is invalid', () async {
      when(
        () => mockBundle.loadString('assets/hadith.json'),
      ).thenAnswer((_) async => 'invalid json');

      await repository.initialize();
      final hadiths = await repository.getAllHadiths();

      expect(hadiths, isEmpty);
    });

    test('fallback to empty list when JSON structure is incorrect', () async {
      // Missing required fields for Hadith.fromJson
      when(
        () => mockBundle.loadString('assets/hadith.json'),
      ).thenAnswer((_) async => '[{"invalid": "data"}]');

      await repository.initialize();
      final hadiths = await repository.getAllHadiths();

      expect(hadiths, isEmpty);
    });
  });
}
