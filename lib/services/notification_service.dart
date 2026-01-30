import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  late FlutterLocalNotificationsPlugin _plugin;
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  Future<void> initialize() async {
    _plugin = FlutterLocalNotificationsPlugin();
    tz.initializeTimeZones();
    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );

    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    final settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _plugin.initialize(
      settings,
      onDidReceiveNotificationResponse: _handleNotificationClick,
      onDidReceiveBackgroundNotificationResponse:
          _handleBackgroundNotificationClick,
    );
    await _createChannels();
  }

  Future<void> _createChannels() async {
    const mainChannel = AndroidNotificationChannel(
      'equip_sight_channel',
      'Уведомления EquipSight',
      description: 'Основные уведомления приложения',
      importance: Importance.high,
      playSound: true,
      enableVibration: true,
    );

    const reminderChannel = AndroidNotificationChannel(
      'reminder_channel',
      'Rappels machines',
      description: 'Уведомления о завершённых машинах',
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
      sound: RawResourceAndroidNotificationSound('notification_sound'),
    );

    final androidPlugin = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    if (androidPlugin != null) {
      await androidPlugin.createNotificationChannel(mainChannel);
      await androidPlugin.createNotificationChannel(reminderChannel);
    }
  }

  Future<void> showNotification({
    required String title,
    required String body,
    int? notificationId,
    String channelId = 'equip_sight_channel',
    String? payload,
  }) async {
    final id = notificationId ?? DateTime.now().millisecondsSinceEpoch;

    final androidDetails = AndroidNotificationDetails(
      channelId,
      channelId.replaceAll('_', ' ').toUpperCase(),
      importance: Importance.high,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
      autoCancel: true,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _plugin.show(id, title, body, details, payload: payload);
  }

  Future<void> scheduleNotification({
    required String title,
    required String body,
    required DateTime scheduledTime,
    int? notificationId,
    String channelId = 'reminder_channel',
    String? payload,
  }) async {
    final id = notificationId ?? DateTime.now().millisecondsSinceEpoch;

    final androidDetails = AndroidNotificationDetails(
      channelId,
      channelId.replaceAll('_', ' ').toUpperCase(),
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
      autoCancel: true,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _plugin.zonedSchedule(
      id,
      title,
      body,
      tz.TZDateTime.from(scheduledTime, tz.local),
      details,
      payload: payload,
      androidScheduleMode: AndroidScheduleMode.alarmClock,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  Future<void> scheduleMachineNotification({
    required String machineId,
    required String machineName,
    required DateTime endTime,
    String? userId,
    String channelId = 'reminder_channel',
  }) async {
    final notificationId = machineId.hashCode;
    final payload = 'machine_finished|$machineId|${userId ?? ''}';
    await scheduleNotification(
      title: 'Машина завершила работу',
      body: 'Ваша машина «$machineName» завершила цикл 🎉',
      scheduledTime: endTime,
      notificationId: notificationId,
      channelId: channelId,
      payload: payload,
    );
  }

  Future<void> cancelNotification(int notificationId) async {
    await _plugin.cancel(notificationId);
  }

  Future<void> cancelAllNotifications() async {
    await _plugin.cancelAll();
  }

  void _handleNotificationClick(NotificationResponse response) {
    _handleNotificationAction(response);
  }

  static Future<void> _handleBackgroundNotificationClick(
    NotificationResponse response,
  ) async {
    final instance = NotificationService();
    instance._handleNotificationAction(response);
  }

  void _handleNotificationAction(NotificationResponse response) {
    final payload = response.payload;
    if (payload == null) return;

    final parts = payload.split('|');
    if (parts.isEmpty) return;

    final action = parts[0];
    switch (action) {
      case 'machine_finished':
        final machineId = parts.length >= 2 ? parts[1] : null;
        if (machineId != null && navigatorKey.currentState != null) {
          navigatorKey.currentState!.pushNamed(
            '/machine',
            arguments: {'machineId': machineId},
          );
        }
        break;
      case 'reminder':
        final reminderId = parts.length >= 2 ? parts[1] : null;
        if (reminderId != null && navigatorKey.currentState != null) {
          navigatorKey.currentState!.pushNamed('/reminders');
        }
        break;
      default:
        navigatorKey.currentState?.pushNamed('/notifications');
    }
  }

  Future<bool> checkPermission() async {
    final androidPlugin = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    if (androidPlugin != null) {
      return await androidPlugin.areNotificationsEnabled() ?? false;
    }
    return true;
  }
}
