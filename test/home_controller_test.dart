import 'package:flutter_test/flutter_test.dart';
import 'package:hijri/hijri_calendar.dart';
import 'package:immutable5/features/duas/contextual_dua_service.dart';
import 'package:immutable5/features/duas/models/dua_model.dart';
import 'package:immutable5/features/home/home_controller.dart';
import 'package:immutable5/features/prayer/prayer_times_service.dart';
import 'package:immutable5/features/quotes/quote_picker_service.dart';

class FakeQuoteService extends QuotePickerService {
  @override
  Future<String> getQuote({String? topic}) async => 'Test Quote';
}

class FakeContextualDuaService implements ContextualDuaService {
  @override
  Future<Dua?> getBestContextualDua({
    required DateTime now,
    required HijriCalendar hijriDate,
    Map<String, DateTime>? todayPrayerTimes,
  }) async {
    return null;
  }

  @override
  Future<List<Dua>> getContextualDuas({
    required DateTime now,
    required HijriCalendar hijriDate,
    Map<String, DateTime>? todayPrayerTimes,
  }) async {
    return [];
  }

  @override
  String? getContextualMessage(
    Dua dua,
    DateTime now,
    Map<String, DateTime>? prayerTimes,
    HijriCalendar hijriDate,
  ) {
    return null;
  }
}

class FakeNotificationPort implements NotificationPort {
  bool called = false;
  @override
  Future<void> schedulePrayerNotifications(
    Map<String, DateTime> prayerTimes,
  ) async {
    called = true;
  }
}

class FakeWidgetPort implements WidgetUpdatePort {
  bool called = false;
  @override
  Future<void> updateWidgetWithStoredSettings() async {
    called = true;
  }
}

class FakePrayerTimesService extends PrayerTimesService {
  FakePrayerTimesService(this.nextPrayer, this.todayMap)
      : super(latitude: 0, longitude: 0, method: 2, madhab: 0);

  final MapEntry<String, DateTime> nextPrayer;
  final Map<String, DateTime> todayMap;

  @override
  Future<MapEntry<String, DateTime>> getNextPrayer({
    bool forceRefresh = false,
  }) async =>
      nextPrayer;

  @override
  Future<Map<String, DateTime>> getTodayPrayerTimes({
    bool forceRefresh = false,
  }) async =>
      todayMap;
}

void main() {
  test('HomeController loads cached data and populates state', () async {
    final now = DateTime.now();
    final nextPrayer = MapEntry('Fajr', now.add(const Duration(hours: 1)));
    final todayMap = {
      'Fajr': nextPrayer.value,
      'Dhuhr': now.add(const Duration(hours: 6)),
    };

    final fakePrayer = FakePrayerTimesService(nextPrayer, todayMap);
    final fakeNotify = FakeNotificationPort();
    final fakeWidget = FakeWidgetPort();
    final controller = HomeController(
      quoteService: FakeQuoteService(),
      notificationPort: fakeNotify,
      widgetPort: fakeWidget,
      prayerFactory: (_, __, ___, ____) => fakePrayer,
      initialPrayerService: fakePrayer,
      contextualDuaService: FakeContextualDuaService(),
    );

    await controller.loadData();
    final state = controller.state;

    expect(state.loading, isFalse);
    expect(state.nextPrayerName, equals('Fajr'));
    expect(state.nextPrayerTime, equals(nextPrayer.value));
    expect(state.quote, isNotEmpty);
    expect(fakeNotify.called, isTrue);
    expect(fakeWidget.called, isTrue);
  });
}
