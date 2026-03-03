import 'package:flutter_test/flutter_test.dart';
import 'package:immutable5/services/battery_optimizer.dart';
import 'package:mocktail/mocktail.dart';

import 'mocks.dart';

void main() {
  late MockSecureStorageProvider mockPrefs;
  late BatteryOptimizer optimizer;

  setUp(() {
    mockPrefs = MockSecureStorageProvider();

    // Default stubs
    when(() => mockPrefs.getBool(any())).thenAnswer((_) async => null);
    when(() => mockPrefs.getInt(any())).thenAnswer((_) async => null);
    when(() => mockPrefs.setBool(any(), any())).thenAnswer((_) async => {});
    when(() => mockPrefs.setInt(any(), any())).thenAnswer((_) async => {});

    optimizer = BatteryOptimizer(prefs: mockPrefs);
  });

  group('BatteryOptimizer Tests', () {
    test('initialize loads battery mode and last network check', () async {
      when(() => mockPrefs.getBool('battery_saver_mode'))
          .thenAnswer((_) async => true);
      when(() => mockPrefs.getInt('last_network_check'))
          .thenAnswer((_) async => 1000);

      await optimizer.initialize();

      expect(optimizer.isBatterySaverEnabled(), isTrue);
    });

    test('shouldAllowNetworkRequest handles normal interval', () async {
      const key = 'test_request';

      // First request allowed
      expect(optimizer.shouldAllowNetworkRequest(key), isTrue);

      // Immediate second request denied
      expect(optimizer.shouldAllowNetworkRequest(key), isFalse);
    });

    test('shouldAllowNetworkRequest respects battery saver interval', () async {
      const key = 'test_request';
      await optimizer.setBatterySaverMode(true);

      expect(optimizer.shouldAllowNetworkRequest(key), isTrue);
      expect(optimizer.shouldAllowNetworkRequest(key), isFalse);

      verify(() => mockPrefs.setBool('battery_saver_mode', true)).called(1);
    });

    test('optimizeTimerInterval extends intervals in battery saver mode',
        () async {
      await optimizer.setBatterySaverMode(true);

      const original = Duration(seconds: 30);
      final optimized = optimizer.optimizeTimerInterval(original);

      expect(optimized, equals(const Duration(seconds: 60)));
    });

    test('getUpdateIntervals returns correct values based on mode', () async {
      // Normal mode
      expect(optimizer.getUpdateIntervals()['prayerTimes'], equals(1800));

      // Battery saver mode
      await optimizer.setBatterySaverMode(true);
      expect(optimizer.getUpdateIntervals()['prayerTimes'], equals(3600));
    });
  });
}
