import 'dart:async';

import 'package:immutable5/services/secure_storage_provider.dart';

/// Battery optimization service to reduce power consumption
class BatteryOptimizer {
  static final BatteryOptimizer _instance = BatteryOptimizer._internal();
  factory BatteryOptimizer() => _instance;
  BatteryOptimizer._internal();

  static const String _keyBatteryMode = 'battery_saver_mode';
  static const String _keyLastNetworkCheck = 'last_network_check';

  // Network request throttling intervals (in seconds)
  static const int _normalInterval = 300; // 5 minutes
  static const int _batterySaverInterval = 900; // 15 minutes

  bool _batteryMode = false;
  DateTime? _lastNetworkRequest;
  final Map<String, DateTime> _requestTimestamps = {};

  /// Initialize battery optimizer
  Future<void> initialize() async {
    final prefs = SecureStorageProvider();
    _batteryMode = await prefs.getBool(_keyBatteryMode) ?? false;

    final lastCheck = await prefs.getInt(_keyLastNetworkCheck);
    if (lastCheck != null) {
      _lastNetworkRequest = DateTime.fromMillisecondsSinceEpoch(lastCheck);
    }
  }

  /// Enable/disable battery saver mode
  Future<void> setBatterySaverMode(bool enabled) async {
    _batteryMode = enabled;
    final prefs = SecureStorageProvider();
    await prefs.setBool(_keyBatteryMode, enabled);
  }

  /// Check if battery saver mode is enabled
  bool isBatterySaverEnabled() => _batteryMode;

  /// Check if a network request should be allowed (rate limiting)
  bool shouldAllowNetworkRequest(String requestKey) {
    final now = DateTime.now();
    final interval = _batteryMode ? _batterySaverInterval : _normalInterval;

    if (!_requestTimestamps.containsKey(requestKey)) {
      _requestTimestamps[requestKey] = now;
      return true;
    }

    final lastRequest = _requestTimestamps[requestKey]!;
    final difference = now.difference(lastRequest).inSeconds;

    if (difference >= interval) {
      _requestTimestamps[requestKey] = now;
      return true;
    }

    return false;
  }

  /// Record a network request
  Future<void> recordNetworkRequest() async {
    _lastNetworkRequest = DateTime.now();
    final prefs = SecureStorageProvider();
    await prefs.setInt(
      _keyLastNetworkCheck,
      _lastNetworkRequest!.millisecondsSinceEpoch,
    );
  }

  /// Get time until next allowed network request
  Duration getTimeUntilNextRequest(String requestKey) {
    if (!_requestTimestamps.containsKey(requestKey)) {
      return Duration.zero;
    }

    final now = DateTime.now();
    final lastRequest = _requestTimestamps[requestKey]!;
    final interval = _batteryMode ? _batterySaverInterval : _normalInterval;
    final elapsed = now.difference(lastRequest).inSeconds;

    if (elapsed >= interval) {
      return Duration.zero;
    }

    return Duration(seconds: interval - elapsed);
  }

  /// Get recommended update intervals
  Map<String, int> getUpdateIntervals() {
    return {
      'prayerTimes': _batteryMode ? 3600 : 1800, // 1h or 30min
      'widget': _batteryMode ? 1800 : 900, // 30min or 15min
      'notifications': _batteryMode ? 3600 : 1800, // 1h or 30min
    };
  }

  /// Optimize timer intervals based on battery mode
  Duration optimizeTimerInterval(Duration original) {
    if (!_batteryMode) return original;

    // In battery saver mode, extend timer intervals
    if (original.inSeconds < 60) {
      return original * 2; // Double short intervals
    } else if (original.inMinutes < 30) {
      return original * 1.5; // Extend medium intervals by 50%
    }

    return original;
  }

  /// Clear request cache (useful for testing)
  void clearRequestCache() {
    _requestTimestamps.clear();
  }

  /// Get battery optimization statistics
  Map<String, dynamic> getStats() {
    return {
      'batteryMode': _batteryMode,
      'trackedRequests': _requestTimestamps.length,
      'lastNetworkRequest': _lastNetworkRequest?.toIso8601String() ?? 'Never',
      'normalInterval': '$_normalInterval seconds',
      'batterySaverInterval': '$_batterySaverInterval seconds',
    };
  }
}
