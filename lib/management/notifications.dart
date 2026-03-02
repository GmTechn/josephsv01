// ignore_for_file: depend_on_referenced_packages

import 'package:flutter/foundation.dart';
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

  // ----------------------------
  // TIMEZONE
  // ----------------------------
  static Future<void> initTimeZone() async {
    tzdata.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('America/Montreal'));
  }

  // ----------------------------
  // SETTINGS FLAG
  // ----------------------------
  Future<bool> _isEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('notifications_enabled') ?? true;
  }

  // ----------------------------
  // INITIALIZE
  // ----------------------------
  Future<void> initialize() async {
    await initTimeZone();

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');

    const iosInit = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const macosInit = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const settings = InitializationSettings(
      android: androidInit,
      iOS: iosInit,
      macOS: macosInit,
    );

    await flutterLocalNotificationsPlugin.initialize(
      settings,
      onDidReceiveNotificationResponse: (_) {
        navigatorKey.currentState?.pushNamedAndRemoveUntil(
          '/dashboard',
          (_) => false,
        );
      },
    );

    await _createAndroidChannels();
    await requestAndroidPermissions();
  }

  // ----------------------------
  // ANDROID CHANNELS
  // ----------------------------
  Future<void> _createAndroidChannels() async {
    if (kIsWeb) return;

    final android = flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();

    if (android == null) return;

    const defaultChannel = AndroidNotificationChannel(
      'default_channel',
      'General Notifications',
      description: 'General app notifications',
      importance: Importance.max,
    );

    const scheduledChannel = AndroidNotificationChannel(
      'scheduled_channel',
      'Scheduled Notifications',
      description: 'Scheduled app notifications',
      importance: Importance.max,
    );

    await android.createNotificationChannel(defaultChannel);
    await android.createNotificationChannel(scheduledChannel);
  }

  // ----------------------------
  // ANDROID PERMISSIONS
  // ----------------------------
  Future<void> requestAndroidPermissions() async {
    final android = flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();

    if (android == null) return;

    await android.requestNotificationsPermission();
  }

  // ----------------------------
  // DEBUG (USED IN SETTINGS)
  // ----------------------------
  Future<String> debugPermissions() async {
    final android = flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();

    if (android == null) return "Android plugin not available";

    final enabled = await android.areNotificationsEnabled();
    return "Android notifications enabled: $enabled";
  }

  // ----------------------------
  // SHOW NOW
  // ----------------------------
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
        channelDescription: 'General app notifications',
        importance: Importance.max,
        priority: Priority.high,
      ),
    );

    await flutterLocalNotificationsPlugin.show(id, title, body, details);
  }

  // ----------------------------
  // SCHEDULE (NO iOS interpretation param to avoid your errors)
  // ----------------------------
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
        channelDescription: 'Scheduled app notifications',
        importance: Importance.max,
        priority: Priority.high,
      ),
    );

    await flutterLocalNotificationsPlugin.zonedSchedule(
      id,
      title,
      body,
      tz.TZDateTime.from(scheduledDate, tz.local),
      details,
      payload: 'open_dashboard',
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: null,
    );
  }

  // ----------------------------
  // CANCEL
  // ----------------------------
  Future<void> cancelNotification(int id) async {
    await flutterLocalNotificationsPlugin.cancel(id);
  }

  Future<void> cancelAll() async {
    await flutterLocalNotificationsPlugin.cancelAll();
  }
}
