import 'package:flutter_test/flutter_test.dart';
import 'package:immutable5/services/secure_storage_provider.dart';
import 'package:mocktail/mocktail.dart';

import 'mocks.dart';

void main() {
  late MockFlutterSecureStorage mockStorage;
  late SecureStorageProvider provider;

  setUp(() {
    mockStorage = MockFlutterSecureStorage();
    provider = SecureStorageProvider(storage: mockStorage);
  });

  group('SecureStorageProvider Tests', () {
    test('getString calls read', () async {
      when(() => mockStorage.read(key: 'key')).thenAnswer((_) async => 'value');

      final result = await provider.getString('key');

      expect(result, equals('value'));
      verify(() => mockStorage.read(key: 'key')).called(1);
    });

    test('setString calls write', () async {
      when(() => mockStorage.write(key: 'key', value: 'value'))
          .thenAnswer((_) async => {});

      await provider.setString('key', 'value');

      verify(() => mockStorage.write(key: 'key', value: 'value')).called(1);
    });

    test('getBool returns true for "true"', () async {
      when(() => mockStorage.read(key: 'key')).thenAnswer((_) async => 'true');

      final result = await provider.getBool('key');

      expect(result, isTrue);
    });

    test('getBool returns false for "false"', () async {
      when(() => mockStorage.read(key: 'key')).thenAnswer((_) async => 'false');

      final result = await provider.getBool('key');

      expect(result, isFalse);
    });

    test('getInt parses string correctly', () async {
      when(() => mockStorage.read(key: 'key')).thenAnswer((_) async => '123');

      final result = await provider.getInt('key');

      expect(result, equals(123));
    });

    test('remove calls delete', () async {
      when(() => mockStorage.delete(key: 'key')).thenAnswer((_) async => {});

      await provider.remove('key');

      verify(() => mockStorage.delete(key: 'key')).called(1);
    });

    test('clear calls deleteAll', () async {
      when(() => mockStorage.deleteAll()).thenAnswer((_) async => {});

      await provider.clear();

      verify(() => mockStorage.deleteAll()).called(1);
    });
  });
}
