import '../duas/models/dua_model.dart';

class HomeState {
  final bool loading;
  final bool refreshing;
  final bool locationLoaded;
  final bool usingCache;
  final bool locationPermissionIssue;
  final String? locationError;
  final String? locationNotice;
  final DateTime? nextPrayerTime;
  final String? nextPrayerName;
  final Duration countdown;
  final String? quote;
  final Dua? contextualDua;
  final String? contextualMessage;

  const HomeState({
    this.loading = true,
    this.refreshing = false,
    this.locationLoaded = false,
    this.usingCache = false,
    this.locationPermissionIssue = false,
    this.locationError,
    this.locationNotice,
    this.nextPrayerTime,
    this.nextPrayerName,
    this.countdown = Duration.zero,
    this.quote,
    this.contextualDua,
    this.contextualMessage,
  });

  HomeState copyWith({
    bool? loading,
    bool? refreshing,
    bool? locationLoaded,
    bool? usingCache,
    bool? locationPermissionIssue,
    String? locationError,
    String? locationNotice,
    DateTime? nextPrayerTime,
    String? nextPrayerName,
    Duration? countdown,
    String? quote,
    Dua? contextualDua,
    String? contextualMessage,
  }) {
    return HomeState(
      loading: loading ?? this.loading,
      refreshing: refreshing ?? this.refreshing,
      locationLoaded: locationLoaded ?? this.locationLoaded,
      usingCache: usingCache ?? this.usingCache,
      locationPermissionIssue:
          locationPermissionIssue ?? this.locationPermissionIssue,
      locationError: locationError,
      locationNotice: locationNotice,
      nextPrayerTime: nextPrayerTime ?? this.nextPrayerTime,
      nextPrayerName: nextPrayerName ?? this.nextPrayerName,
      countdown: countdown ?? this.countdown,
      quote: quote ?? this.quote,
      contextualDua: contextualDua ?? this.contextualDua,
      contextualMessage: contextualMessage ?? this.contextualMessage,
    );
  }
}
