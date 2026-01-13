// ignore_for_file: depend_on_referenced_packages

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import 'package:josephs_vs_01/main.dart' show navigatorKey;

class NotificationServices {
  NotificationServices._();
  static final NotificationServices instance = NotificationServices._();

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static Future<void> initTimeZone() async {
    tzdata.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('America/Montreal'));
  }

  Future<bool> _isEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('notifications_enabled') ?? true;
  }

  Future<void> initialize() async {
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');

    const iosInit = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    // =========================
    // ✅ CHANGE #1: ADD macOS init settings
    // =========================
    const macosInit = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    // =========================
    // ✅ CHANGE #2: Include macOS in InitializationSettings
    // =========================
    const settings = InitializationSettings(
      android: androidInit,
      iOS: iosInit,
      macOS: macosInit, // ✅ ADD THIS
    );

    await flutterLocalNotificationsPlugin.initialize(
      settings,
      onDidReceiveNotificationResponse: (NotificationResponse response) async {
        // ✅ Click notif -> Dashboard
        navigatorKey.currentState?.pushNamedAndRemoveUntil(
          '/dashboard',
          (_) => false,
        );
      },
    );
  }

  Future<void> requestIOSPermissions() async {
    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >()
        ?.requestPermissions(alert: true, badge: true, sound: true);
  }

  // =========================
  // ✅ OPTIONAL: request macOS permissions too
  // =========================
  Future<void> requestMacOSPermissions() async {
    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
          MacOSFlutterLocalNotificationsPlugin
        >()
        ?.requestPermissions(alert: true, badge: true, sound: true);
  }

  Future<void> showNotification({
    required String title,
    required String body,
    int id = 0,
  }) async {
    if (!await _isEnabled()) return;

    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        'default_channel',
        'General Notifications',
        importance: Importance.max,
        priority: Priority.high,
      ),
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
      // (No extra macOS details required here; DarwinNotificationDetails covers it)
    );

    await flutterLocalNotificationsPlugin.show(
      id,
      title,
      body,
      details,
      payload: 'open_dashboard',
    );
  }

  Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
  }) async {
    if (!await _isEnabled()) return;
    if (scheduledDate.isBefore(DateTime.now())) return;

    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        'scheduled_channel',
        'Scheduled Notifications',
        importance: Importance.max,
        priority: Priority.high,
      ),
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    );

    await flutterLocalNotificationsPlugin.zonedSchedule(
      id,
      title,
      body,
      tz.TZDateTime.from(scheduledDate, tz.local),
      details,
      payload: 'open_dashboard',
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: null,
    );
  }

  Future<void> cancelNotification(int id) async {
    await flutterLocalNotificationsPlugin.cancel(id);
  }

  Future<void> cancelAll() async {
    await flutterLocalNotificationsPlugin.cancelAll();
  }

  Future<String> debugPermissions() async {
    final ios = flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >();

    if (ios == null) return "Not iOS / iOS plugin not available";

    final result = await ios.requestPermissions(
      alert: true,
      badge: true,
      sound: true,
    );

    return result == true
        ? "iOS permissions: GRANTED ✅"
        : "iOS permissions: DENIED ❌";
  }
}
