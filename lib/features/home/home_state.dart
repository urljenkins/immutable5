import '../duas/models/dua_model.dart';
import '../hadith/models/hadith_model.dart';

class HomeState {
  final bool loading;
  final bool refreshing;
  final bool locationLoaded;
  final bool usingCache;
  final bool locationPermissionIssue;
  final String? locationError;
  final String? locationNotice;
  final bool showPastPrayer;
  final DateTime? nextPrayerTime;
  final String? nextPrayerName;
  final String? pastPrayerName;
  final Duration countdown;
  final String? quote;
  final Dua? contextualDua;
  final Hadith? contextualHadith;
  final String? contextualMessage;

  const HomeState({
    this.loading = true,
    this.refreshing = false,
    this.locationLoaded = false,
    this.usingCache = false,
    this.locationPermissionIssue = false,
    this.locationError,
    this.locationNotice,
    this.showPastPrayer = false,
    this.nextPrayerTime,
    this.nextPrayerName,
    this.pastPrayerName,
    this.countdown = Duration.zero,
    this.quote,
    this.contextualDua,
    this.contextualHadith,
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
    bool? showPastPrayer,
    DateTime? nextPrayerTime,
    String? nextPrayerName,
    String? pastPrayerName,
    Duration? countdown,
    String? quote,
    Dua? contextualDua,
    Hadith? contextualHadith,
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
      showPastPrayer: showPastPrayer ?? this.showPastPrayer,
      nextPrayerTime: nextPrayerTime ?? this.nextPrayerTime,
      nextPrayerName: nextPrayerName ?? this.nextPrayerName,
      pastPrayerName: pastPrayerName ?? this.pastPrayerName,
      countdown: countdown ?? this.countdown,
      quote: quote ?? this.quote,
      contextualDua: contextualDua,
      contextualHadith: contextualHadith,
      contextualMessage: contextualMessage ?? this.contextualMessage,
    );
  }
}
