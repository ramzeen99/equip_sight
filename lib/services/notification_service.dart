// lib/services/notification_service.dart
// lib/services/notification_service.dart
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

/// Service singleton pour gérer toutes les notifications locales et push
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  late FlutterLocalNotificationsPlugin _plugin;

  /// Navigator key pour gérer la navigation depuis la notification
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  /// Initialise le service
  Future<void> initialize() async {
    _plugin = FlutterLocalNotificationsPlugin();

    // Initialisation des fuseaux horaires
    tz.initializeTimeZones();

    // Paramètres Android
    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );

    // Paramètres iOS
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

    // Créer les canaux de notification
    await _createChannels();
  }

  /// Création des canaux de notification Android
  Future<void> _createChannels() async {
    const mainChannel = AndroidNotificationChannel(
      'equip_sight_channel',
      'Notifications EquipSight',
      description: 'Notifications principales de l’application',
      importance: Importance.high,
      playSound: true,
      enableVibration: true,
    );

    const reminderChannel = AndroidNotificationChannel(
      'reminder_channel',
      'Rappels machines',
      description: 'Notifications pour les machines terminées',
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

  /// Affiche une notification immédiate
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

  /// Planifie une notification à une date et heure précises
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
      //uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  /// Planifie une notification spécifique à une machine
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
      title: 'Machine terminée',
      body: 'Votre machine "$machineName" a terminé son cycle 🎉',
      scheduledTime: endTime,
      notificationId: notificationId,
      channelId: channelId,
      payload: payload,
    );
  }

  /// Annule une notification planifiée
  Future<void> cancelNotification(int notificationId) async {
    await _plugin.cancel(notificationId);
  }

  /// Annule toutes les notifications
  Future<void> cancelAllNotifications() async {
    await _plugin.cancelAll();
  }

  /// Gestion du clic sur notification
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

  /// Vérifie si les notifications sont autorisées (Android 13+)
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
