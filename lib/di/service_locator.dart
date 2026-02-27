import 'package:get_it/get_it.dart';

import '../features/notifications/notification_service.dart';
import '../features/prayer/prayer_times_service.dart';
import '../features/quotes/quote_picker_service.dart';
import '../features/widget/prayer_widget_service.dart';
import '../features/home/home_controller.dart';
import '../features/prayer_tracking/prayer_tracking_service.dart';

import '../features/duas/dua_repository.dart';

import '../features/duas/contextual_dua_service.dart';

final getIt = GetIt.instance;

void setupLocator() {
  // Core services
  getIt.registerLazySingleton<NotificationService>(() => NotificationService());
  getIt.registerLazySingleton<QuotePickerService>(() => QuotePickerService());
  getIt.registerLazySingleton<DuaRepository>(() => DuaRepository());
  getIt.registerLazySingleton<ContextualDuaService>(
    () => ContextualDuaService(),
  );
  getIt.registerLazySingleton<PrayerTrackingService>(
    () => PrayerTrackingService(),
  );

  // Adapters/ports
  getIt.registerLazySingleton<NotificationPort>(
    () => NotificationServicePort(getIt<NotificationService>()),
  );
  getIt.registerLazySingleton<WidgetUpdatePort>(() => PrayerWidgetPort());

  // Factory for prayer service based on location/method/madhab
  getIt.registerFactory<PrayerTimesServiceFactory>(
    () =>
        (double lat, double lon, int method, int madhab) => PrayerTimesService(
          latitude: lat,
          longitude: lon,
          method: method,
          madhab: madhab,
        ),
  );
}

class NotificationServicePort implements NotificationPort {
  NotificationServicePort(this._service);
  final NotificationService _service;

  @override
  Future<void> schedulePrayerNotifications(
    Map<String, DateTime> prayerTimes,
  ) async {
    await _service.schedulePrayerNotifications(prayerTimes);
  }
}

class PrayerWidgetPort implements WidgetUpdatePort {
  @override
  Future<void> updateWidgetWithStoredSettings() =>
      PrayerWidgetService.updateWidgetWithStoredSettings();
}
