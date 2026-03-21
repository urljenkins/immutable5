import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:immutable5/di/service_locator.dart';
import 'package:immutable5/features/places/places_page.dart';
import 'package:immutable5/features/places/services/places_service.dart';
import 'package:immutable5/features/prayer/prayer_times_service.dart';
import 'package:immutable5/l10n/app_localizations.dart';
import 'package:mocktail/mocktail.dart';

import 'mocks.dart';

/// Prevents real HTTP requests during tests by blocking all connections.
class _NoNetworkHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    final client = super.createHttpClient(context);
    client.findProxy = (_) => 'DIRECT';
    client.connectionFactory =
        (Uri uri, String? proxyHost, int? proxyPort) async {
          throw const SocketException('No network requests allowed in tests');
        };
    return client;
  }
}

void main() {
  late MockPlacesService mockPlacesService;
  late MockPrayerTimesService mockPrayerTimesService;
  late MockGeolocatorPlatform mockGeolocatorPlatform;

  setUpAll(() {
    registerFallbackValue(DateTime.now());
    HttpOverrides.global = _NoNetworkHttpOverrides();
  });

  tearDownAll(() {
    HttpOverrides.global = null;
  });

  setUp(() async {
    mockPlacesService = MockPlacesService();
    mockPrayerTimesService = MockPrayerTimesService();
    mockGeolocatorPlatform = MockGeolocatorPlatform();

    GeolocatorPlatform.instance = mockGeolocatorPlatform;

    await getIt.reset();
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

  testWidgets('Check PlacesPage map dimensions', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 1920);
    tester.view.devicePixelRatio = 3.0;

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
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    final mapFinder = find.byType(FlutterMap);
    final size = tester.getSize(mapFinder);
    debugPrint('FLUTTERMAP SIZE: $size');
  });
}
