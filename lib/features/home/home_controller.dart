import 'dart:async';
import 'dart:convert';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:hijri/hijri_calendar.dart';
import 'package:http/http.dart' as http;
import 'package:immutable5/services/secure_storage_provider.dart';

import '../../di/service_locator.dart';
import '../duas/contextual_dua_service.dart';
import '../hadith/hadith_repository.dart';
import '../hadith/models/hadith.dart';
import '../prayer/prayer_times_service.dart';
import '../quotes/quote_picker_service.dart';
import 'home_state.dart';

abstract class NotificationPort {
  Future<void> schedulePrayerNotifications(Map<String, DateTime> prayerTimes);
}

abstract class WidgetUpdatePort {
  Future<void> updateWidgetWithStoredSettings();
}

class HomeController extends ChangeNotifier {
  HomeController({
    required this.quoteService,
    required this.notificationPort,
    required this.widgetPort,
    required this.prayerFactory,
    this.defaultLatitude = 21.3891,
    this.defaultLongitude = 39.8579,
    PrayerTimesService? initialPrayerService,
    ContextualDuaService? contextualDuaService,
    HadithRepository? hadithRepository,
    SecureStorageProvider? prefs,
  })  : contextualDuaService =
            contextualDuaService ?? getIt<ContextualDuaService>(),
        hadithRepository = hadithRepository ?? getIt<HadithRepository>(),
        _prefs = prefs ?? getIt<SecureStorageProvider>() {
    if (initialPrayerService != null) {
      _prayerTimesService = initialPrayerService;
      _state = _state.copyWith(loading: false, locationLoaded: true);
    }
  }

  final QuotePickerService quoteService;
  final NotificationPort notificationPort;
  final WidgetUpdatePort widgetPort;
  final PrayerTimesServiceFactory prayerFactory;
  final ContextualDuaService contextualDuaService;
  final HadithRepository hadithRepository;
  final SecureStorageProvider _prefs;

  final double defaultLatitude;
  final double defaultLongitude;

  PrayerTimesService? _prayerTimesService;
  Timer? _timer;

  DateTime? _cachedNextPrayerTime;
  String? _cachedNextPrayerName;
  String? _cachedPastPrayerName;
  DateTime? _cachedDataTimestamp;
  String? _cachedQuote;
  DateTime? _cachedQuoteTimestamp;

  static const Duration _dataCacheTtl = Duration(minutes: 5);
  static const Duration _quoteCacheTtl = Duration(minutes: 30);

  HomeState _state = const HomeState();
  HomeState get state => _state;

  void _update(HomeState newState) {
    _state = newState;
    notifyListeners();
  }

  Future<void> init() async {
    _update(_state.copyWith(loading: true));
    await _initLocationAndLoadData();
  }

  Future<void> disposeController() async {
    _timer?.cancel();
  }

  Future<void> _initLocationAndLoadData() async {
    try {
      bool serviceEnabled = true;
      if (!(kIsWeb ||
          Platform.isLinux ||
          Platform.isWindows ||
          Platform.isMacOS)) {
        serviceEnabled = await Geolocator.isLocationServiceEnabled();
      }

      if (kIsWeb) {
        // Simple fallback or basic browser geolocation for web
        final handled = await _useFallbackLocation(
          notice: 'Location on web. Using saved or default.',
        );
        if (!handled) {
          _update(
            _state.copyWith(
              loading: false,
              locationError: 'Failed to initialize location on web.',
            ),
          );
        }
        return;
      }

      serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        final handled = await _useFallbackLocation(
          notice: 'Location services disabled. Using saved or default.',
          permissionIssue: true,
        );
        if (!handled) {
          _update(
            _state.copyWith(
              loading: false,
              locationError: 'Location services disabled.',
            ),
          );
        }
        return;
      }
      LocationPermission permission = LocationPermission.always;
      if (!(kIsWeb ||
          Platform.isLinux ||
          Platform.isWindows ||
          Platform.isMacOS)) {
        permission = await Geolocator.checkPermission();
        if (permission == LocationPermission.denied) {
          permission = await Geolocator.requestPermission();
          if (permission == LocationPermission.denied) {
            final handled = await _useFallbackLocation(
              notice: 'Location permission denied. Using saved or default.',
              permissionIssue: true,
            );
            if (!handled) {
              _update(
                _state.copyWith(
                  loading: false,
                  locationError: 'Location permission denied.',
                ),
              );
            }
            return;
          }
        }
        if (permission == LocationPermission.deniedForever) {
          final handled = await _useFallbackLocation(
            notice: 'Location permanently denied. Using saved or default.',
            permissionIssue: true,
          );
          if (!handled) {
            _update(
              _state.copyWith(
                loading: false,
                locationError: 'Location permanently denied.',
              ),
            );
          }
          return;
        }
      }

      Position? position;
      if (!(kIsWeb ||
          Platform.isLinux ||
          Platform.isWindows ||
          Platform.isMacOS)) {
        position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
          timeLimit: const Duration(seconds: 10),
        );
      } else {
        // Fallback to IP-based location for desktop/web
        try {
          final response = await http
              .get(Uri.parse('https://ip-api.com/json/'))
              .timeout(const Duration(seconds: 5));
          if (response.statusCode == 200) {
            final data = jsonDecode(response.body);
            if (data['status'] == 'success' &&
                data['lat'] != null &&
                data['lon'] != null) {
              position = Position(
                latitude: (data['lat'] as num).toDouble(),
                longitude: (data['lon'] as num).toDouble(),
                timestamp: DateTime.now(),
                accuracy: 0.0,
                altitude: 0.0,
                heading: 0.0,
                speed: 0.0,
                speedAccuracy: 0.0,
                headingAccuracy: 0.0,
                altitudeAccuracy: 0.0,
              );
            }
          }
        } catch (_) {
          // Fall back to default location
        }
      }

      final latitude = position?.latitude ?? defaultLatitude;
      final longitude = position?.longitude ?? defaultLongitude;

      final prefs = _prefs;
      await _configurePrayerService(
        latitude: latitude,
        longitude: longitude,
        prefs: prefs,
        clearNotice: true,
      );
      await loadData();
    } catch (e) {
      final handled = await _useFallbackLocation(
        notice: 'Using cached/default location.',
      );
      if (!handled) {
        _update(
          _state.copyWith(
            loading: false,
            locationError: 'Failed to get location: $e',
          ),
        );
      }
    }
  }

  Future<void> _configurePrayerService({
    required double latitude,
    required double longitude,
    SecureStorageProvider? prefs,
    bool clearNotice = false,
  }) async {
    final prefsInstance = prefs ?? SecureStorageProvider();
    final calcMethodRaw = await prefsInstance.get('calculationMethod') ??
        'Method 2 (University of Islamic Sciences)';
    final calcMethodString = calcMethodRaw.toString();
    final method = calcMethodString.contains('4') ? 4 : 2;

    final madhabRaw = await prefsInstance.get('madhab') ?? 'Shafi';
    final madhabString = madhabRaw.toString();
    const madhabList = ['Shafi', 'Hanafi', 'Maliki', 'Hanbali'];
    var madhab = madhabList.indexOf(madhabString);
    final madhabIndex = int.tryParse(madhabString);
    if (madhabIndex != null &&
        madhabIndex >= 0 &&
        madhabIndex < madhabList.length) {
      madhab = madhabIndex;
    }
    if (madhab == -1) madhab = 0;

    await prefsInstance.setDouble('location_latitude', latitude);
    await prefsInstance.setDouble('location_longitude', longitude);
    await prefsInstance.setInt('calculation_method', method);
    await prefsInstance.setInt('madhab', madhab);

    _prayerTimesService = prayerFactory(latitude, longitude, method, madhab);
    _update(
      _state.copyWith(
        loading: false,
        locationLoaded: true,
        locationNotice: clearNotice ? null : _state.locationNotice,
        locationPermissionIssue:
            clearNotice ? false : _state.locationPermissionIssue,
      ),
    );
  }

  Future<bool> _useFallbackLocation({
    String? notice,
    bool permissionIssue = false,
  }) async {
    try {
      final prefs = _prefs;
      final savedLat = await prefs.getDouble('location_latitude');
      final savedLon = await prefs.getDouble('location_longitude');
      final latitude = savedLat ?? defaultLatitude;
      final longitude = savedLon ?? defaultLongitude;

      await _configurePrayerService(
        latitude: latitude,
        longitude: longitude,
        prefs: prefs,
      );
      await loadData();
      if (notice != null) {
        _update(
          _state.copyWith(
            locationNotice: notice,
            locationPermissionIssue: permissionIssue,
          ),
        );
      }
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> loadData({bool forceRefresh = false}) async {
    if (_prayerTimesService == null) return;

    final now = DateTime.now();
    final cacheFresh = _cachedDataTimestamp != null &&
        now.difference(_cachedDataTimestamp!) < _dataCacheTtl &&
        _cachedNextPrayerTime != null &&
        _cachedNextPrayerTime!.isAfter(now);

    if (!forceRefresh && cacheFresh) {
      final prefs = _prefs;
      final showPastPrayer = await prefs.getBool('show_past_prayer') ?? false;

      _update(
        _state.copyWith(
          loading: false,
          usingCache: true,
          showPastPrayer: showPastPrayer,
          nextPrayerTime: _cachedNextPrayerTime,
          nextPrayerName: _cachedNextPrayerName,
          pastPrayerName: _cachedPastPrayerName,
          quote: _cachedQuote,
          countdown: _cachedNextPrayerTime!.difference(DateTime.now()),
        ),
      );
      _startTimer();
      return;
    }

    _update(_state.copyWith(loading: _state.loading));

    try {
      final nextPrayer = await _prayerTimesService!.getNextPrayer(
        forceRefresh: forceRefresh,
      );
      final nextPrayerTime = nextPrayer.value;
      final nextPrayerName = nextPrayer.key;

      final pastPrayerName = await _prayerTimesService!.getPastPrayerName();

      String? quote = _cachedQuote;
      final quoteFresh = _cachedQuoteTimestamp != null &&
          now.difference(_cachedQuoteTimestamp!) < _quoteCacheTtl;
      if (forceRefresh || quote == null || !quoteFresh) {
        quote = await quoteService
            .getQuote(); // Deprecated or changed API? Will fix compilation later if need be.
        _cachedQuote = quote;
        _cachedQuoteTimestamp = DateTime.now();
      }

      final prayerTimes = await _prayerTimesService!.getTodayPrayerTimes(
        forceRefresh: forceRefresh,
      );

      if (!kIsWeb) {
        await notificationPort.schedulePrayerNotifications(prayerTimes);
        await widgetPort.updateWidgetWithStoredSettings();
      }

      _cachedNextPrayerTime = nextPrayerTime;
      _cachedNextPrayerName = nextPrayerName;
      _cachedPastPrayerName = pastPrayerName;
      _cachedDataTimestamp = DateTime.now();

      final prefs = _prefs;
      final showPastPrayer = await prefs.getBool('show_past_prayer') ?? false;

      // Check for Contextual Dua
      final hijriDate = HijriCalendar.now();
      final contextualDua = await contextualDuaService.getBestContextualDua(
        now: now,
        hijriDate: hijriDate,
        todayPrayerTimes: prayerTimes,
      );

      String? contextualMsg;
      Hadith? contextualHadith;

      if (contextualDua != null) {
        contextualMsg = contextualDuaService.getContextualMessage(
          contextualDua,
          now,
          prayerTimes,
          hijriDate,
        );
      } else {
        // If no contextual dua, pick a random high-priority hadith
        final allHadiths = await hadithRepository.getAllHadiths();
        if (allHadiths.isNotEmpty) {
          final priority1 = allHadiths.where((h) => h.priority == 1).toList();
          final source = priority1.isNotEmpty ? priority1 : allHadiths;
          // Use a simple day-based pick for "of the day" feel
          contextualHadith = source[now.day % source.length];
          contextualMsg = 'Hadith of the Day';
        }
      }

      _update(
        _state.copyWith(
          loading: false,
          usingCache: false,
          showPastPrayer: showPastPrayer,
          nextPrayerTime: nextPrayerTime,
          nextPrayerName: nextPrayerName,
          pastPrayerName: pastPrayerName,
          quote: quote,
          countdown: nextPrayerTime.difference(DateTime.now()),
          contextualDua: contextualDua,
          contextualHadith: contextualHadith,
          contextualMessage: contextualMsg,
        ),
      );
      _startTimer();
    } catch (e) {
      // fallback to cached times if available
      try {
        final cachedTimes = await _prayerTimesService!.getTodayPrayerTimes();
        final upcoming =
            cachedTimes.entries.where((e) => e.value.isAfter(now)).toList();
        if (upcoming.isNotEmpty) {
          upcoming.sort((a, b) => a.value.compareTo(b.value));
          final nextPrayer = upcoming.first;

          // Check for Contextual Dua (fallback mode)
          final hijriDate = HijriCalendar.now();
          final contextualDua = await contextualDuaService.getBestContextualDua(
            now: now,
            hijriDate: hijriDate,
            todayPrayerTimes: cachedTimes,
          );
          String? contextualMsg;
          Hadith? contextualHadith;

          if (contextualDua != null) {
            contextualMsg = contextualDuaService.getContextualMessage(
              contextualDua,
              now,
              cachedTimes,
              hijriDate,
            );
          } else {
            final allHadiths = await hadithRepository.getAllHadiths();
            if (allHadiths.isNotEmpty) {
              final priority1 =
                  allHadiths.where((h) => h.priority == 1).toList();
              final source = priority1.isNotEmpty ? priority1 : allHadiths;
              contextualHadith = source[now.day % source.length];
              contextualMsg = 'Hadith of the Day';
            }
          }

          final pastPrayerName = await _prayerTimesService!.getPastPrayerName();
          final prefs = _prefs;
          final showPastPrayer =
              await prefs.getBool('show_past_prayer') ?? false;

          _update(
            _state.copyWith(
              loading: false,
              usingCache: true,
              showPastPrayer: showPastPrayer,
              nextPrayerTime: nextPrayer.value,
              nextPrayerName: nextPrayer.key,
              pastPrayerName: pastPrayerName,
              countdown: nextPrayer.value.difference(now),
              locationError: 'Using cached prayer times',
              contextualDua: contextualDua,
              contextualHadith: contextualHadith,
              contextualMessage: contextualMsg,
            ),
          );
          _startTimer();
        } else {
          _update(
            _state.copyWith(
              loading: false,
              locationError: 'Failed to load prayer times: $e',
            ),
          );
        }
      } catch (_) {
        _update(
          _state.copyWith(
            loading: false,
            locationError: 'Failed to load prayer times: $e',
          ),
        );
      }
    }
  }

  Future<void> refresh() async {
    if (_state.refreshing) return;
    _update(_state.copyWith(refreshing: true));
    await loadData(forceRefresh: true);
    _update(_state.copyWith(refreshing: false));
  }

  void _startTimer() {
    _timer?.cancel();
    if (_state.nextPrayerTime == null) return;
    // Check prohibited time immediately, then every tick
    _checkProhibitedTime();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final target = _state.nextPrayerTime;
      if (target == null) return;
      final diff = target.difference(DateTime.now());
      if (diff.isNegative) {
        timer.cancel();
        loadData();
      } else {
        _update(_state.copyWith(countdown: diff));
        _checkProhibitedTime();
      }
    });
  }

  void _checkProhibitedTime() {
    if (_prayerTimesService == null) return;
    _prayerTimesService!.isProhibitedPrayerTime().then((prohibited) {
      if (prohibited != _state.isProhibitedTime) {
        _update(_state.copyWith(isProhibitedTime: prohibited));
      }
    });
  }

  Future<void> togglePrayerDisplayOption() async {
    final prefs = _prefs;
    final newValue = !_state.showPastPrayer;
    await prefs.setBool('show_past_prayer', newValue);
    // Since this simply changes what we display, and the data is already in state,
    // we can just update the state directly without a full load.
    _update(_state.copyWith(showPastPrayer: newValue));
  }
}
