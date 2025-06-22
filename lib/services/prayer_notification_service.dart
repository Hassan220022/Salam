import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/models/cached_prayer_times.dart';

class PrayerNotificationService {
  static final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  static bool _isInitialized = false;

  static Future<void> initialize() async {
    if (_isInitialized) return;

    tz.initializeTimeZones();

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iOSSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iOSSettings,
    );

    await _notifications.initialize(initSettings);
    await _requestPermissions();
    _isInitialized = true;
  }

  static Future<void> _requestPermissions() async {
    if (await Permission.notification.isDenied) {
      await Permission.notification.request();
    }
  }

  /// Schedule notifications for all prayer times
  static Future<void> scheduleAllPrayerNotifications(
      CachedPrayerTimes prayerTimes) async {
    await initialize();
    await cancelAllNotifications();

    final prefs = await SharedPreferences.getInstance();
    final isEnabled = prefs.getBool('prayer_notifications_enabled') ?? true;
    final reminderMinutes = prefs.getInt('prayer_reminder_minutes') ?? 10;

    if (!isEnabled) return;

    final prayers = [
      {'name': 'Fajr', 'time': prayerTimes.fajr},
      {'name': 'Dhuhr', 'time': prayerTimes.dhuhr},
      {'name': 'Asr', 'time': prayerTimes.asr},
      {'name': 'Maghrib', 'time': prayerTimes.maghrib},
      {'name': 'Isha', 'time': prayerTimes.isha},
    ];

    for (int i = 0; i < prayers.length; i++) {
      final prayer = prayers[i];
      final prayerTime = DateTime.parse(prayer['time'] as String);
      final reminderTime =
          prayerTime.subtract(Duration(minutes: reminderMinutes));

      if (reminderTime.isAfter(DateTime.now())) {
        await _scheduleNotification(
          id: i * 2, // Prayer reminder
          title: '🕌 ${prayer['name']} Prayer Reminder',
          body: '${prayer['name']} prayer time is in $reminderMinutes minutes',
          scheduledTime: reminderTime,
        );

        await _scheduleNotification(
          id: i * 2 + 1, // Prayer time
          title: '🕌 ${prayer['name']} Prayer Time',
          body: 'It\'s time for ${prayer['name']} prayer',
          scheduledTime: prayerTime,
        );
      }
    }
  }

  static Future<void> _scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledTime,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'prayer_notifications',
      'Prayer Times',
      channelDescription: 'Notifications for Islamic prayer times',
      importance: Importance.high,
      priority: Priority.high,
      enableVibration: true,
    );

    const iOSDetails = DarwinNotificationDetails(
      sound: 'prayer_adhan.aiff',
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iOSDetails,
    );

    await _notifications.zonedSchedule(
      id,
      title,
      body,
      tz.TZDateTime.from(scheduledTime, tz.local),
      notificationDetails,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  /// Schedule daily Ayah notification
  static Future<void> scheduleDailyAyahNotification() async {
    await initialize();

    final prefs = await SharedPreferences.getInstance();
    final isEnabled = prefs.getBool('daily_ayah_enabled') ?? true;
    final hour = prefs.getInt('daily_ayah_hour') ?? 8;

    if (!isEnabled) return;

    const androidDetails = AndroidNotificationDetails(
      'daily_ayah',
      'Daily Ayah',
      channelDescription: 'Daily verse from the Quran',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
    );

    const iOSDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iOSDetails,
    );

    final now = DateTime.now();
    var scheduledTime = DateTime(now.year, now.month, now.day, hour);

    if (scheduledTime.isBefore(now)) {
      scheduledTime = scheduledTime.add(const Duration(days: 1));
    }

    await _notifications.zonedSchedule(
      999, // Daily ayah ID
      '📖 Daily Ayah',
      'Read today\'s verse from the Holy Quran',
      tz.TZDateTime.from(scheduledTime, tz.local),
      notificationDetails,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  /// Cancel all notifications
  static Future<void> cancelAllNotifications() async {
    await _notifications.cancelAll();
  }

  /// Cancel specific prayer notifications
  static Future<void> cancelPrayerNotifications() async {
    for (int i = 0; i < 10; i++) {
      await _notifications.cancel(i);
    }
  }

  /// Update notification settings
  static Future<void> updateNotificationSettings({
    bool? prayerNotificationsEnabled,
    int? reminderMinutes,
    bool? dailyAyahEnabled,
    int? dailyAyahHour,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    if (prayerNotificationsEnabled != null) {
      await prefs.setBool(
          'prayer_notifications_enabled', prayerNotificationsEnabled);
    }

    if (reminderMinutes != null) {
      await prefs.setInt('prayer_reminder_minutes', reminderMinutes);
    }

    if (dailyAyahEnabled != null) {
      await prefs.setBool('daily_ayah_enabled', dailyAyahEnabled);
    }

    if (dailyAyahHour != null) {
      await prefs.setInt('daily_ayah_hour', dailyAyahHour);
    }
  }

  /// Get current notification settings
  static Future<Map<String, dynamic>> getNotificationSettings() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'prayer_notifications_enabled':
          prefs.getBool('prayer_notifications_enabled') ?? true,
      'reminder_minutes': prefs.getInt('prayer_reminder_minutes') ?? 10,
      'daily_ayah_enabled': prefs.getBool('daily_ayah_enabled') ?? true,
      'daily_ayah_hour': prefs.getInt('daily_ayah_hour') ?? 8,
    };
  }
}
