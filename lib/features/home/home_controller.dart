import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:hijri/hijri_calendar.dart';
import 'package:immutable5/services/secure_storage_provider.dart';

import 'home_state.dart';
import '../prayer/prayer_times_service.dart';
import '../quotes/quote_picker_service.dart';
import '../duas/contextual_dua_service.dart';
import '../../di/service_locator.dart';

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
  }) : contextualDuaService =
            contextualDuaService ?? getIt<ContextualDuaService>() {
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

  final double defaultLatitude;
  final double defaultLongitude;

  PrayerTimesService? _prayerTimesService;
  Timer? _timer;

  DateTime? _cachedNextPrayerTime;
  String? _cachedNextPrayerName;
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
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
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
      LocationPermission permission = await Geolocator.checkPermission();
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
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );
      final prefs = SecureStorageProvider();
      await _configurePrayerService(
        latitude: position.latitude,
        longitude: position.longitude,
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
        locationError: null,
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
      final prefs = SecureStorageProvider();
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
      _update(
        _state.copyWith(
          loading: false,
          locationError: null,
          usingCache: true,
          nextPrayerTime: _cachedNextPrayerTime,
          nextPrayerName: _cachedNextPrayerName,
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
      await notificationPort.schedulePrayerNotifications(prayerTimes);
      await widgetPort.updateWidgetWithStoredSettings();

      _cachedNextPrayerTime = nextPrayerTime;
      _cachedNextPrayerName = nextPrayerName;
      _cachedDataTimestamp = DateTime.now();

      // Check for Contextual Dua
      final hijriDate = HijriCalendar.now();
      final contextualDua = await contextualDuaService.getBestContextualDua(
        now: now,
        hijriDate: hijriDate,
        todayPrayerTimes: prayerTimes,
      );

      String? contextualMsg;
      if (contextualDua != null) {
        contextualMsg = contextualDuaService.getContextualMessage(
          contextualDua,
          now,
          prayerTimes,
          hijriDate,
        );
      }

      _update(
        _state.copyWith(
          loading: false,
          usingCache: false,
          locationError: null,
          nextPrayerTime: nextPrayerTime,
          nextPrayerName: nextPrayerName,
          quote: quote,
          countdown: nextPrayerTime.difference(DateTime.now()),
          contextualDua: contextualDua,
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
          if (contextualDua != null) {
            contextualMsg = contextualDuaService.getContextualMessage(
              contextualDua,
              now,
              cachedTimes,
              hijriDate,
            );
          }

          _update(
            _state.copyWith(
              loading: false,
              usingCache: true,
              nextPrayerTime: nextPrayer.value,
              nextPrayerName: nextPrayer.key,
              countdown: nextPrayer.value.difference(now),
              locationError: 'Using cached prayer times',
              contextualDua: contextualDua,
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
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final target = _state.nextPrayerTime;
      if (target == null) return;
      final diff = target.difference(DateTime.now());
      if (diff.isNegative) {
        timer.cancel();
        loadData();
      } else {
        _update(_state.copyWith(countdown: diff));
      }
    });
  }
}
