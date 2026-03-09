import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:immutable5/di/service_locator.dart';
import 'package:immutable5/features/places/places_page.dart';
import 'package:immutable5/features/places/services/places_service.dart';
import 'package:immutable5/features/prayer/prayer_times_service.dart';
import 'package:immutable5/l10n/app_localizations.dart';
import 'package:mocktail/mocktail.dart';

import 'mocks.dart';

void main() {
  late MockPlacesService mockPlacesService;
  late MockPrayerTimesService mockPrayerTimesService;
  late MockGeolocatorPlatform mockGeolocatorPlatform;

  setUpAll(() {
    registerFallbackValue(DateTime.now());
  });

  setUp(() {
    mockPlacesService = MockPlacesService();
    mockPrayerTimesService = MockPrayerTimesService();
    mockGeolocatorPlatform = MockGeolocatorPlatform();

    GeolocatorPlatform.instance = mockGeolocatorPlatform;

    getIt.reset();
    getIt.registerLazySingleton<PlacesService>(() => mockPlacesService);
    getIt.registerFactory<PrayerTimesServiceFactory>(
      () =>
          (lat, lon, method, madhab) => mockPrayerTimesService,
    );

    // Default stubbing
    when(
      () => mockGeolocatorPlatform.checkPermission(),
    ).thenAnswer((_) async => LocationPermission.always);
    when(
      () => mockGeolocatorPlatform.getCurrentPosition(
        locationSettings: any(named: 'locationSettings'),
      ),
    ).thenAnswer(
      (_) async => Position(
        latitude: 21.3891,
        longitude: 39.8579,
        timestamp: DateTime.now(),
        accuracy: 0,
        altitude: 0,
        heading: 0,
        speed: 0,
        speedAccuracy: 0,
        altitudeAccuracy: 0,
        headingAccuracy: 0,
      ),
    );
    when(
      () => mockPlacesService.getNearbyPlaces(any(), any()),
    ).thenAnswer((_) async => []);
    when(
      () => mockPlacesService.getPendingPlaces(),
    ).thenAnswer((_) async => []);
    when(() => mockPrayerTimesService.getNextPrayer()).thenAnswer(
      (_) async =>
          MapEntry('Fajr', DateTime.now().add(const Duration(hours: 1))),
    );
  });

  testWidgets('PlacesPage builds without error', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        localizationsDelegates: [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: PlacesPage(),
      ),
    );

    // Use pump instead of pumpAndSettle if there are infinite animations
    // or if pumpAndSettle times out.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.byType(PlacesPage), findsOneWidget);
  });
}
