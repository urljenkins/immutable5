import '../duas/models/dua_model.dart';
import '../hadith/models/hadith.dart';

class _Sentinel {
  const _Sentinel();
}

const _sentinel = _Sentinel();

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
  final bool isProhibitedTime;
  final bool showSurahKahfReminder;

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
    this.isProhibitedTime = false,
    this.showSurahKahfReminder = false,
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
    Object? contextualDua = _sentinel,
    Object? contextualHadith = _sentinel,
    String? contextualMessage,
    bool? isProhibitedTime,
    bool? showSurahKahfReminder,
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
      contextualDua: contextualDua == _sentinel
          ? this.contextualDua
          : contextualDua as Dua?,
      contextualHadith: contextualHadith == _sentinel
          ? this.contextualHadith
          : contextualHadith as Hadith?,
      contextualMessage: contextualMessage ?? this.contextualMessage,
      isProhibitedTime: isProhibitedTime ?? this.isProhibitedTime,
      showSurahKahfReminder:
          showSurahKahfReminder ?? this.showSurahKahfReminder,
    );
  }
}
