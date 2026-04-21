import 'package:flutter_test/flutter_test.dart';
import 'package:hijri/hijri_calendar.dart';
import 'package:immutable5/features/duas/contextual_dua_service.dart';
import 'package:immutable5/features/duas/dua_repository.dart';
import 'package:immutable5/features/duas/models/dua_model.dart';
import 'package:mocktail/mocktail.dart';

class MockDuaRepository extends Mock implements DuaRepository {}

void main() {
  late ContextualDuaService service;
  late MockDuaRepository mockRepository;

  setUp(() {
    mockRepository = MockDuaRepository();
    service = ContextualDuaService(mockRepository);
  });

  Dua createDua({
    required String id,
    int priority = 5,
    List<String> timeWindows = const [],
    List<String> hijriPeriods = const [],
    List<String> daysOfWeek = const [],
    List<String> conditions = const [],
  }) {
    return Dua(
      id: id,
      occasion: 'Occasion $id',
      tags: [],
      arabic: 'Arabic $id',
      transliteration: 'Trans $id',
      translationEn: 'Translation $id',
      priority: priority,
      displayContext: DisplayContext(
        timeWindows: timeWindows,
        hijriPeriods: hijriPeriods,
        daysOfWeek: daysOfWeek,
        conditions: conditions,
      ),
    );
  }

  group('ContextualDuaService Tests', () {
    test(
      'getBestContextualDua returns null when repository is empty',
      () async {
        when(() => mockRepository.getAllDuas()).thenAnswer((_) async => []);

        final result = await service.getBestContextualDua(
          now: DateTime(2023, 10, 27, 10, 0), // Friday morning
          hijriDate: HijriCalendar.fromDate(DateTime(2023, 10, 27)),
        );

        expect(result, isNull);
      },
    );

    test('getBestContextualDua selects morning dua in the morning', () async {
      final morningDua = createDua(id: 'morning_1', timeWindows: ['morning']);
      final eveningDua = createDua(id: 'evening_1', timeWindows: ['evening']);

      when(
        () => mockRepository.getAllDuas(),
      ).thenAnswer((_) async => [morningDua, eveningDua]);

      final result = await service.getBestContextualDua(
        now: DateTime(2023, 10, 27, 8, 0), // 8 AM
        hijriDate: HijriCalendar.fromDate(DateTime(2023, 10, 27)),
      );

      expect(result?.id, equals('morning_1'));
    });

    test('getBestContextualDua handles priority tie-breaking', () async {
      final duaLowPriority = createDua(
        id: 'low',
        priority: 10,
        timeWindows: ['morning'],
      );
      final duaHighPriority = createDua(
        id: 'high',
        priority: 1,
        timeWindows: ['morning'],
      );

      when(
        () => mockRepository.getAllDuas(),
      ).thenAnswer((_) async => [duaLowPriority, duaHighPriority]);

      final result = await service.getBestContextualDua(
        now: DateTime(2023, 10, 27, 8, 0),
        hijriDate: HijriCalendar.fromDate(DateTime(2023, 10, 27)),
      );

      expect(result?.id, equals('high'));
    });

    test('getBestContextualDua prefers more specific match (score)', () async {
      // Hijri period matches give 25 score, morning gives 10.
      final morningDua = createDua(id: 'morning', timeWindows: ['morning']);
      final ramadanDua = createDua(id: 'ramadan', hijriPeriods: ['ramadan']);

      when(
        () => mockRepository.getAllDuas(),
      ).thenAnswer((_) async => [morningDua, ramadanDua]);

      // Ramadan 1st, 1445 AH is approx March 11, 2024
      final ramadanDate = DateTime(2024, 3, 11, 8, 0);
      final hijriRamadan = HijriCalendar.fromDate(ramadanDate);
      // Ensure it is indeed Ramadan in the mock/logic
      // In contextual_dua_service.dart: date.hMonth == 9 => ramadan

      final result = await service.getBestContextualDua(
        now: ramadanDate,
        hijriDate: hijriRamadan,
      );

      expect(result?.id, equals('ramadan'));
    });

    test('getContextualDuas returns sorted list of matching duas', () async {
      final morning1 = createDua(
        id: 'm1',
        priority: 5,
        timeWindows: ['morning'],
      );
      final morning2 = createDua(
        id: 'm2',
        priority: 1,
        timeWindows: ['morning'],
      );
      final evening = createDua(id: 'e1', timeWindows: ['evening']);

      when(
        () => mockRepository.getAllDuas(),
      ).thenAnswer((_) async => [morning1, morning2, evening]);

      final results = await service.getContextualDuas(
        now: DateTime(2023, 10, 27, 8, 0),
        hijriDate: HijriCalendar.fromDate(DateTime(2023, 10, 27)),
      );

      expect(results.length, equals(2));
      expect(results[0].id, equals('m2')); // Higher priority (1 < 5)
      expect(results[1].id, equals('m1'));
    });

    test('getContextualMessage returns specific message for Jummah', () {
      final dua = createDua(id: 'walking_to_masjid_001');
      final friday = DateTime(2023, 10, 27); // Friday

      final message = service.getContextualMessage(
        dua,
        friday,
        null,
        HijriCalendar.fromDate(friday),
      );

      expect(message, contains('Jummah Mubarak'));
    });

    test('getContextualMessage returns Ramadan message', () {
      final dua = createDua(id: 'ramadan_iftar_001');
      final ramadanDate = DateTime(2024, 3, 11);
      final hijriRamadan = HijriCalendar.fromDate(ramadanDate);

      final message = service.getContextualMessage(
        dua,
        ramadanDate,
        null,
        hijriRamadan,
      );

      expect(message, contains('breaking your fast'));
    });

    test('getContextualMessage returns generic occasion message', () {
      final dua = createDua(
        id: 'travel_dua',
      ); // occasion: 'Occasion travel_dua'

      final message = service.getContextualMessage(
        dua,
        DateTime.now(),
        null,
        HijriCalendar.now(),
      );

      expect(message, equals('For occasion travel_dua'));
    });

    test('Advanced time windows with prayer times', () async {
      final preSunriseDua = createDua(
        id: 'pre_sunrise',
        timeWindows: ['pre_sunrise'],
      );

      when(
        () => mockRepository.getAllDuas(),
      ).thenAnswer((_) async => [preSunriseDua]);

      final sunrise = DateTime(2023, 10, 27, 6, 30);
      final now = DateTime(2023, 10, 27, 6, 15); // 15 mins before sunrise

      final prayerTimes = {
        'Fajr': DateTime(2023, 10, 27, 5, 0),
        'Sunrise': sunrise,
      };

      final result = await service.getBestContextualDua(
        now: now,
        hijriDate: HijriCalendar.fromDate(now),
        todayPrayerTimes: prayerTimes,
      );

      expect(result?.id, equals('pre_sunrise'));
    });

    test('Last third of night calculation', () async {
      final lastThirdDua = createDua(
        id: 'last_third',
        timeWindows: ['last_third_night'],
      );
      when(
        () => mockRepository.getAllDuas(),
      ).thenAnswer((_) async => [lastThirdDua]);

      // Maghrib: 18:00, Fajr (next day): 06:00
      // Night duration: 12 hours. Last third: 02:00 to 06:00.
      final maghrib = DateTime(2023, 10, 27, 18, 0);
      final fajr = DateTime(2023, 10, 28, 6, 0);
      final now = DateTime(2023, 10, 28, 3, 0); // In the last third

      final prayerTimes = {'Maghrib': maghrib, 'Fajr': fajr};

      final result = await service.getBestContextualDua(
        now: now,
        hijriDate: HijriCalendar.fromDate(now),
        todayPrayerTimes: prayerTimes,
      );

      expect(result?.id, equals('last_third'));
    });
  });
}
