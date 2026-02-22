import 'package:flutter/material.dart';
import 'dart:developer' as developer;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;

    // Initialize timezone data
    tz.initializeTimeZones();

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    _initialized = true;
  }

  void _onNotificationTapped(NotificationResponse response) {
    // Handle notification tap - could navigate to prayer times page
    developer.log('Notification tapped: ${response.payload}',
        name: 'NotificationService');
  }

  Future<bool> requestPermissions() async {
    if (await Permission.notification.isDenied) {
      final status = await Permission.notification.request();
      return status.isGranted;
    }
    return await Permission.notification.isGranted;
  }

  Future<void> schedulePrayerNotifications(
      Map<String, DateTime> prayerTimes) async {
    if (!_initialized) await initialize();

    final prefs = await SharedPreferences.getInstance();
    final notificationsEnabled = prefs.getBool('notificationsEnabled') ?? false;

    if (!notificationsEnabled) {
      await cancelAllNotifications();
      return;
    }

    // Cancel existing notifications
    await cancelAllNotifications();

    final now = DateTime.now();
    int notificationId = 0;

    final jummahRemindersEnabled = prefs.getBool('jummahReminders') ?? true;
    final iftarRemindersEnabled = prefs.getBool('iftarReminders') ?? true;

    for (final entry in prayerTimes.entries) {
      final prayerName = entry.key;
      final prayerTime = entry.value;

      // Skip prayers that have already passed
      if (prayerTime.isBefore(now)) continue;

      // Skip non-essential prayer times (like Sunrise, Midnight, etc)
      if (!_isMainPrayer(prayerName)) continue;

      await _schedulePrayerNotification(
        notificationId++,
        prayerName,
        prayerTime,
      );

      // Contextual Notifications Logic
      // 1. Jummah Prep (1 hour before Dhuhr on Friday)
      if (prayerName == 'Dhuhr' &&
          prayerTime.weekday == DateTime.friday &&
          jummahRemindersEnabled) {
        final jummahPrepTime = prayerTime.subtract(const Duration(hours: 1));
        if (jummahPrepTime.isAfter(now)) {
          await _scheduleContextualNotification(
            notificationId++,
            'Jummah Preparation',
            'Time to get ready for Jummah prayer! Don\'t forget to read Surah Al-Kahf.',
            jummahPrepTime,
            'jummah_prep',
          );
        }
      }

      // 2. Iftar Prep (15 mins before Maghrib during Ramadan)
      // Note: Full Hijri calendar check requires hijri_calendar package, using simple check for demo purposes
      // The calling code should ideally pass whether it's Ramadan, but we will schedule it strictly here if enabled
      if (prayerName == 'Maghrib' && iftarRemindersEnabled) {
        final iftarPrepTime = prayerTime.subtract(const Duration(minutes: 15));
        if (iftarPrepTime.isAfter(now)) {
          // Ideally check HijriCalendar.now().hMonth == 9 here before scheduling
          await _scheduleContextualNotification(
            notificationId++,
            'Iftar Preparation',
            'Maghrib is in 15 minutes. Take this time to make abundant dua.',
            iftarPrepTime,
            'iftar_prep',
          );
        }
      }
    }
  }

  Future<void> _scheduleContextualNotification(
    int id,
    String title,
    String body,
    DateTime scheduledTime,
    String payload,
  ) async {
    const androidDetails = AndroidNotificationDetails(
      'contextual_reminders',
      'Contextual Reminders',
      channelDescription: 'Specific reminders for Sunnah acts and Duas',
      importance: Importance.high,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
      color: Color(0xFFD4AF37), // AppColors.accent equivalent
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    final tzScheduledTime = tz.TZDateTime.from(scheduledTime, tz.local);

    await _notifications.zonedSchedule(
      id,
      title,
      body,
      tzScheduledTime,
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      payload: payload,
    );
  }

  bool _isMainPrayer(String prayerName) {
    const mainPrayers = ['Fajr', 'Dhuhr', 'Asr', 'Maghrib', 'Isha'];
    return mainPrayers.contains(prayerName);
  }

  Future<void> _schedulePrayerNotification(
    int id,
    String prayerName,
    DateTime scheduledTime,
  ) async {
    const androidDetails = AndroidNotificationDetails(
      'prayer_times',
      'Prayer Times',
      channelDescription: 'Notifications for prayer times',
      importance: Importance.high,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    final tzScheduledTime = tz.TZDateTime.from(scheduledTime, tz.local);

    await _notifications.zonedSchedule(
      id,
      'Prayer Time',
      'Time for $prayerName prayer',
      tzScheduledTime,
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      payload: prayerName,
    );
  }

  Future<void> cancelAllNotifications() async {
    await _notifications.cancelAll();
  }

  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    return await _notifications.pendingNotificationRequests();
  }
}
