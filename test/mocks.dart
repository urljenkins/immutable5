import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geolocator_platform_interface/geolocator_platform_interface.dart';
import 'package:immutable5/features/places/services/places_service.dart';
import 'package:immutable5/features/prayer/prayer_times_service.dart';
import 'package:immutable5/services/secure_storage_provider.dart';
import 'package:mocktail/mocktail.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockPlacesService extends Mock implements PlacesService {}

class MockPrayerTimesService extends Mock implements PrayerTimesService {}

class MockFlutterSecureStorage extends Mock implements FlutterSecureStorage {}

class MockSecureStorageProvider extends Mock implements SecureStorageProvider {}

class MockGeolocatorPlatform extends Mock
    with MockPlatformInterfaceMixin
    implements GeolocatorPlatform {}
