import 'package:flutter_test/flutter_test.dart';
import 'package:immutable5/features/duas/dua_repository.dart';

void main() {
  late DuaRepository repository;

  const mockJson = '''
  [
    {
      "id": "1",
      "occasion": "Dua 1",
      "arabic": "Arabic 1",
      "transliteration": "Trans 1",
      "translation_en": "Trans 1",
      "category": "morning",
      "tags": ["tag1"]
    },
    {
      "id": "2",
      "occasion": "Dua 2",
      "arabic": "Arabic 2",
      "transliteration": "Trans 2",
      "translation_en": "Trans 2",
      "category": "evening",
      "tags": ["tag2"]
    }
  ]
  ''';

  setUp(() {
    repository = DuaRepository();
  });

  group('DuaRepository Tests', () {
    test('initialize loads and parses JSON', () async {
      await repository.initialize(jsonOverride: mockJson);

      final duas = await repository.getAllDuas();
      expect(duas.length, equals(2));
      expect(duas.first.id, equals('1'));
      expect(duas.last.category, equals('evening'));
    });

    test('getDuaById returns correct dua', () async {
      await repository.initialize(jsonOverride: mockJson);

      final dua = await repository.getDuaById('2');
      expect(dua, isNotNull);
      expect(dua?.occasion, equals('Dua 2'));
    });

    test('getDuaById returns null for missing id', () async {
      await repository.initialize(jsonOverride: mockJson);

      final dua = await repository.getDuaById('99');
      expect(dua, isNull);
    });

    test('getDuasByCategory returns matching duas', () async {
      await repository.initialize(jsonOverride: mockJson);

      final morningDuas = await repository.getDuasByCategory('morning');
      expect(morningDuas.length, equals(1));
      expect(morningDuas.first.id, equals('1'));
    });

    test('getDuasByCategory returns empty list if no match', () async {
      await repository.initialize(jsonOverride: mockJson);

      final travelDuas = await repository.getDuasByCategory('travel');
      expect(travelDuas, isEmpty);
    });
  });
}
