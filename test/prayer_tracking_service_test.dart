import 'package:flutter_test/flutter_test.dart';
import 'package:immutable5/features/prayer_tracking/prayer_tracking_service.dart';
import 'package:mocktail/mocktail.dart';

import 'mocks.dart';

void main() {
  late MockSecureStorageProvider mockPrefs;
  late PrayerTrackingService service;

  setUp(() {
    mockPrefs = MockSecureStorageProvider();
    service = PrayerTrackingService(prefs: mockPrefs);

    // Default stubbing
    when(() => mockPrefs.setBool(any(), any())).thenAnswer((_) async => {});
    when(() => mockPrefs.setInt(any(), any())).thenAnswer((_) async => {});
    when(() => mockPrefs.getBool(any())).thenAnswer((_) async => null);
    when(() => mockPrefs.getInt(any())).thenAnswer((_) async => null);
  });

  group('PrayerTrackingService Tests', () {
    test('markPrayerCompleted stores true and timestamp', () async {
      final date = DateTime(2023, 10, 27);
      const prayer = 'Fajr';
      const key = 'prayer_Fajr_2023_10_27_completed';

      await service.markPrayerCompleted(prayer, date);

      verify(() => mockPrefs.setBool(key, true)).called(1);
      verify(() => mockPrefs.setInt('${key}_timestamp', any())).called(1);
    });

    test('isPrayerCompleted returns stored value', () async {
      final date = DateTime(2023, 10, 27);
      const prayer = 'Dhuhr';
      const key = 'prayer_Dhuhr_2023_10_27_completed';

      when(() => mockPrefs.getBool(key)).thenAnswer((_) async => true);

      final result = await service.isPrayerCompleted(prayer, date);

      expect(result, isTrue);
    });

    test(
      'getCompletedPrayersForDate returns map of completion status',
      () async {
        final date = DateTime(2023, 10, 27);

        when(() => mockPrefs.getBool(any())).thenAnswer((_) async => false);
        when(
          () => mockPrefs.getBool('prayer_Fajr_2023_10_27_completed'),
        ).thenAnswer((_) async => true);

        final result = await service.getCompletedPrayersForDate(date);

        expect(result['Fajr'], isTrue);
        expect(result['Dhuhr'], isFalse);
        expect(result.length, equals(5));
      },
    );

    test('getCurrentStreak calculates consecutive completed days', () async {
      // Mocking yesterday as fully completed, day before as not.
      final yesterday = DateTime.now().subtract(const Duration(days: 1));
      final dayBefore = DateTime.now().subtract(const Duration(days: 2));

      // Mock completions for yesterday
      for (final p in service.mainPrayers) {
        final key =
            'prayer_${p}_${yesterday.year}_${yesterday.month}_${yesterday.day}_completed';
        when(() => mockPrefs.getBool(key)).thenAnswer((_) async => true);
      }

      // Mock one failure for dayBefore
      final keyFail =
          'prayer_Fajr_${dayBefore.year}_${dayBefore.month}_${dayBefore.day}_completed';
      when(() => mockPrefs.getBool(keyFail)).thenAnswer((_) async => false);

      final streak = await service.getCurrentStreak();

      expect(streak, equals(1));
    });

    test('togglePrayerCompletion unmarks if already completed', () async {
      final date = DateTime(2023, 10, 27);
      const prayer = 'Asr';
      const key = 'prayer_Asr_2023_10_27_completed';

      when(() => mockPrefs.getBool(key)).thenAnswer((_) async => true);
      when(() => mockPrefs.remove(any())).thenAnswer((_) async => {});

      await service.togglePrayerCompletion(prayer, date);

      verify(() => mockPrefs.remove(key)).called(1);
      verify(() => mockPrefs.remove('${key}_timestamp')).called(1);
    });
  });
}
