// lib/services/notification_service.dart
// lib/services/notification_service.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;

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
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');

    // Paramètres iOS
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    final settings = InitializationSettings(android: androidSettings, iOS: iosSettings);

    await _plugin.initialize(
      settings,
      onDidReceiveNotificationResponse: _handleNotificationClick,
      onDidReceiveBackgroundNotificationResponse: _handleBackgroundNotificationClick,
    );

    // Créer les canaux de notification
    await _createChannels();
  }

  /// Création des canaux de notification Android
  Future<void> _createChannels() async {
    const mainChannel = AndroidNotificationChannel(
      'laundry_channel',
      'Notifications Laundry',
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

    final androidPlugin = _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
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
    String channelId = 'laundry_channel',
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

    final details = NotificationDetails(android: androidDetails, iOS: iosDetails);

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

    final details = NotificationDetails(android: androidDetails, iOS: iosDetails);

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

  static Future<void> _handleBackgroundNotificationClick(NotificationResponse response) async {
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
          navigatorKey.currentState!.pushNamed('/machine', arguments: {'machineId': machineId});
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
    final androidPlugin = _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    if (androidPlugin != null) {
      return await androidPlugin.areNotificationsEnabled() ?? false;
    }
    return true;
  }
}

/*import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'package:flutter/material.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  late FlutterLocalNotificationsPlugin notificationsPlugin;
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  Future<void> initialize() async {
    notificationsPlugin = FlutterLocalNotificationsPlugin();

    // Инициализация временных зон / Initialisation des fuseaux horaires
    tz.initializeTimeZones();

    // Настройки Android / Configuration Android
    const AndroidInitializationSettings androidSettings =
    AndroidInitializationSettings('@mipmap/ic_launcher');

    // Настройки iOS / Configuration iOS
    const DarwinInitializationSettings iosSettings =
    DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
      //onDidReceiveLocalNotification: _onDidReceiveLocalNotification,
    );

    final InitializationSettings initializationSettings =
    InitializationSettings(android: androidSettings, iOS: iosSettings);

    await notificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: _handleNotificationClick,
      onDidReceiveBackgroundNotificationResponse:
      _handleBackgroundNotificationClick,
    );

    // Создать каналы уведомлений / Créer les canaux de notification
    await _createNotificationChannels();

    //print('✅ Служба уведомлений инициализирована / NotificationService initialisé');
  }

  // Сохранить старый метод для совместимости / Garder l'ancienne méthode pour la compatibilité
  static void _onDidReceiveLocalNotification(
      int id,
      String? title,
      String? body,
      String? payload,
      ) {
    //print('📱 Уведомление iOS получено: $title / Notification iOS reçue: $title');
  }

  // Создать каналы уведомлений / Créer les canaux de notification
  Future<void> _createNotificationChannels() async {
    // Основной канал / Canal principal
    const AndroidNotificationChannel mainChannel = AndroidNotificationChannel(
      'laundry_channel',
      'Уведомления прачечной', // Notifications Laundry
      importance: Importance.high,
      description: 'Основные уведомления приложения', // Notifications principales de l'application
      playSound: true,
      enableVibration: true,
    );

    // Канал для напоминаний / Canal pour les rappels
    const AndroidNotificationChannel reminderChannel =
    AndroidNotificationChannel(
      'reminder_channel',
      'Напоминания о машинах', // Rappels machines
      importance: Importance.max,
      description: 'Напоминания о завершении работы машин', // Rappels lorsque les machines sont terminées
      playSound: true,
      sound: RawResourceAndroidNotificationSound('notification_sound'),
      enableVibration: true,
      // vibrationPattern: Int64List.fromList([0, 500, 250, 500]),
    );

    // Только для Android / Pour Android seulement
    final androidPlugin = notificationsPlugin
        .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin
    >();

    if (androidPlugin != null) {
      await androidPlugin.createNotificationChannel(mainChannel);
      await androidPlugin.createNotificationChannel(reminderChannel);
      //print('✅ Каналы уведомлений созданы / Canaux de notification créés');
    }
  }

  // Старый метод для совместимости / Ancienne méthode pour la compatibilité
  Future<void> showPushNotification({
    required String title,
    required String body,
    int notificationId = 0,
    String? payload,
  }) async {
    await _showNotification(
      title: title,
      body: body,
      notificationId: notificationId,
      payload: payload,
      channelId: 'laundry_channel',
    );
  }

  // Новый метод с большими возможностями / Nouvelle méthode avec plus d'options
  Future<void> _showNotification({
    required String title,
    required String body,
    required int notificationId,
    String? payload,
    String channelId = 'laundry_channel',
    String? channelName,
    Importance importance = Importance.high,
    Priority priority = Priority.high,
    bool showWhen = true,
    bool autoCancel = true,
    String? sound,
  }) async {
    final androidPlatformChannelSpecifics = AndroidNotificationDetails(
      channelId,
      channelName ?? channelId.replaceAll('_', ' ').toUpperCase(),
      importance: importance,
      priority: priority,
      showWhen: showWhen,
      autoCancel: autoCancel,
      sound: sound != null ? RawResourceAndroidNotificationSound(sound) : null,
    );

    const iosPlatformChannelSpecifics = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: iosPlatformChannelSpecifics,
    );

    await notificationsPlugin.show(
      notificationId,
      title,
      body,
      platformChannelSpecifics,
      payload: payload,
    );
  }

  // Старый метод для совместимости / Ancienne méthode pour la compatibilité
  Future<void> scheduleNotification({
    required String title,
    required String body,
    required DateTime scheduledTime,
    int notificationId = 0,
  }) async {
    await _scheduleExactNotification(
      title: title,
      body: body,
      scheduledTime: scheduledTime,
      notificationId: notificationId,
    );
  }

  // Новый метод с будильником / Nouvelle méthode avec alarm clock
  Future<void> _scheduleExactNotification({
    required String title,
    required String body,
    required DateTime scheduledTime,
    required int notificationId,
    String? payload,
    bool allowWhileIdle = true,
  }) async {
    final androidPlatformChannelSpecifics = AndroidNotificationDetails(
      'reminder_channel',
      'Напоминания о машинах', // Rappels machines
      importance: Importance.max,
      priority: Priority.high,
      enableLights: true,
      color: const Color(0xFF459380),
      ledColor: const Color(0xFF459380),
      ledOnMs: 1000,
      ledOffMs: 500,
    );

    const iosPlatformChannelSpecifics = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: iosPlatformChannelSpecifics,
    );

    try {
      await notificationsPlugin.zonedSchedule(
        notificationId,
        title,
        body,
        tz.TZDateTime.from(scheduledTime, tz.local),
        platformChannelSpecifics,
        // androidAllowWhileIdle: allowWhileIdle,
        //uiLocalNotificationDateInterpretation:
        // UILocalNotificationDateInterpretation.absoluteTime,
        payload: payload,
        matchDateTimeComponents: DateTimeComponents.time,
        androidScheduleMode: AndroidScheduleMode.alarmClock,
      );

      //print('✅ Уведомление запланировано на: $scheduledTime / Notification programmée pour: $scheduledTime');
    } catch (e) {
     // print('❌ Ошибка планирования уведомления: $e / Erreur programmation notification: $e');
    }
  }

  // Метод для планирования уведомления о машине / Méthode pour programmer une notification de machine
  Future<void> scheduleMachineNotification({
    required String machineId,
    required String machineName,
    required DateTime endTime,
    String? userId,
  }) async {
    final notificationId = machineId.hashCode;
    final payload = 'machine_finished|$machineId|$userId';

    await _scheduleExactNotification(
      title: 'Машина завершила работу', // Machine terminée
      body: 'Ваша машина "$machineName" готова', // Votre machine "$machineName" est prête
      scheduledTime: endTime,
      notificationId: notificationId,
      payload: payload,
      allowWhileIdle: true,
    );
  }

  // Метод для планирования напоминания / Méthode pour programmer un rappel
  Future<void> scheduleReminder({
    required String reminderId,
    required String title,
    required String body,
    required DateTime scheduledTime,
    int minutesBefore = 5,
  }) async {
    final reminderTime = scheduledTime.subtract(
      Duration(minutes: minutesBefore),
    );

    await _scheduleExactNotification(
      title: 'Напоминание: $title', // Rappel: $title
      body: body,
      scheduledTime: reminderTime,
      notificationId: reminderId.hashCode,
      payload: 'reminder|$reminderId',
    );
  }

  // Отменить запланированное уведомление / Annuler une notification programmée
  Future<void> cancelScheduledNotification(int notificationId) async {
    await notificationsPlugin.cancel(notificationId);
    //print('❌ Уведомление отменено: $notificationId / Notification annulée: $notificationId');
  }

  // Отменить все уведомления / Annuler toutes les notifications
  Future<void> cancelAllNotifications() async {
    await notificationsPlugin.cancelAll();
    //print('❌ Все уведомления отменены / Toutes les notifications annulées');
  }

  // Обработать клик по уведомлению / Gérer le clic sur notification
  void _handleNotificationClick(NotificationResponse response) {
    _handleNotificationAction(response);
  }

  // Обработать клик в фоновом режиме / Gérer le clic en arrière-plan
  static Future<void> _handleBackgroundNotificationClick(
      NotificationResponse response,
      ) async {
    // Эта функция статическая для вызова в фоне / Cette fonction est statique pour être appelée en background
    final instance = NotificationService();
    instance._handleNotificationAction(response);
  }

  void _handleNotificationAction(NotificationResponse response) {
    //print('🖱️ Уведомление нажато: ${response.payload} / Notification cliquée: ${response.payload}');

    // Разобрать полезную нагрузку для действия / Parser le payload pour l'action
    final payload = response.payload;
    if (payload != null) {
      final parts = payload.split('|');
      if (parts.isNotEmpty) {
        final action = parts[0];

        switch (action) {
          case 'machine_finished':
            if (parts.length >= 2) {
              final machineId = parts[1];
              _navigateToMachine(machineId);
            }
            break;
          case 'reminder':
            if (parts.length >= 2) {
              final reminderId = parts[1];
              _navigateToReminder(reminderId);
            }
            break;
        }
      }
    }

    // Навигация по умолчанию на страницу уведомлений / Navigation par défaut vers la page notifications
    _navigateToNotificationsPage();
  }

  void _navigateToMachine(String machineId) {
    if (navigatorKey.currentState != null) {
      // Перейти на страницу машины с ID / Naviguer vers la page machine avec l'ID
      navigatorKey.currentState!.pushNamed(
        '/machine',
        arguments: {'machineId': machineId},
      );
    }
  }

  void _navigateToReminder(String reminderId) {
    if (navigatorKey.currentState != null) {
      // Перейти на страницу напоминаний / Naviguer vers la page rappels
      navigatorKey.currentState!.pushNamed('/reminders');
    }
  }

  void _navigateToNotificationsPage() {
    if (navigatorKey.currentState != null) {
      navigatorKey.currentState!.pushNamed('/notifications');
    }
  }

  // Вспомогательный метод для генерации уникального ID / Méthode utilitaire pour générer un ID unique
  int generateNotificationId({String? seed}) {
    final seedString = seed ?? DateTime.now().millisecondsSinceEpoch.toString();
    return seedString.hashCode;
  }

  // Проверить разрешения Android (для Android 13+) / Vérifier les permissions Android (pour Android 13+)
  Future<bool> checkNotificationPermission() async {
    final androidPlugin = notificationsPlugin
        .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin
    >();

    if (androidPlugin != null) {
      return await androidPlugin.areNotificationsEnabled() ?? false;
    }
    return true; // Для iOS и других, предположить, что включено / Pour iOS et autres, supposer que c'est activé
  }

  // Получить все запланированные уведомления (только Android) / Obtenir toutes les notifications programmées (Android seulement)
  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    return await notificationsPlugin.pendingNotificationRequests();
  }

  // Очистить все уведомления / Nettoyer les notifications
  Future<void> clearAllNotifications() async {
    final androidPlugin = notificationsPlugin
        .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin
    >();

    if (androidPlugin != null) {
      await androidPlugin.cancelAll();
    } else {
      await notificationsPlugin.cancelAll();
    }
  }
}*/

/*import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  // Инициализация / Initialisation
  Future<void> initialize() async {
    // Инициализация временных зон / Initialiser timezone
    tz.initializeTimeZones();

    // Настройки Android / Configuration Android
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    // Настройки iOS / Configuration iOS
    const DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings(
          requestAlertPermission: true,
          requestBadgePermission: true,
          requestSoundPermission: true,
        );

    final InitializationSettings settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    // Инициализировать плагин / Initialiser le plugin
    await _notificationsPlugin.initialize(
      settings,
      onDidReceiveNotificationResponse: _onNotificationTap,
    );

    // Создать канал уведомлений / Créer le canal de notification
    await _createNotificationChannel();
  }

  // Создать канал уведомлений Android / Créer le canal de notification Android
  Future<void> _createNotificationChannel() async {
    if (Platform.isAndroid) {
      const AndroidNotificationChannel channel = AndroidNotificationChannel(
        'laundry_lens_channel',
        'Уведомления Laundry Lens', // Laundry Lens Notifications
        description: 'Уведомления для Laundry Lens', // Notifications pour Laundry Lens
        importance: Importance.high,
        playSound: true,
        enableVibration: true,
        ledColor: Colors.blue,
        showBadge: true,
      );

      await _notificationsPlugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.createNotificationChannel(channel);
    }
  }

  // Обработать клик по уведомлению / Gérer le clic sur notification
  static void _onNotificationTap(NotificationResponse response) {
    print('Уведомление нажато: ${response.payload} / Notification cliquée: ${response.payload}');
  }

  // Показать немедленное уведомление - ПРОСТОЕ / Afficher une notification immédiate - SIMPLE
  Future<void> showSimpleNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          'laundry_lens_channel',
          'Уведомления Laundry Lens', // Laundry Lens Notifications
          channelDescription: 'Уведомления для Laundry Lens', // Notifications pour Laundry Lens
          importance: Importance.high,
          priority: Priority.high,
          playSound: true,
          enableVibration: true,
          color: Colors.blue,
          icon: '@mipmap/ic_launcher',
          showWhen: true,
          autoCancel: true,
        );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final NotificationDetails details = const NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notificationsPlugin.show(id, title, body, details, payload: payload);
  }

  // Запланировать уведомление - ОЧЕНЬ ПРОСТАЯ ВЕРСИЯ / Planifier une notification - VERSION TRÈS SIMPLE
  Future<void> scheduleSimpleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledTime,
    String? payload,
  }) async {
    try {
      // Конвертировать в местную временную зону / Convertir en timezone locale
      final tz.TZDateTime tzScheduledTime = tz.TZDateTime.from(
        scheduledTime,
        tz.local,
      );

      // Детали Android / Détails Android
      const AndroidNotificationDetails androidDetails =
          AndroidNotificationDetails(
            'laundry_lens_channel',
            'Уведомления Laundry Lens', // Laundry Lens Notifications
            channelDescription: 'Запланированные уведомления', // Notifications planifiées
            importance: Importance.high,
            priority: Priority.high,
            playSound: true,
            enableVibration: true,
          );

      // Детали iOS / Détails iOS
      const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      final NotificationDetails details = const NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      // Запланировать уведомление - БЕЗ ПРОБЛЕМНЫХ ПАРАМЕТРОВ / Planifier la notification - SANS PARAMÈTRES PROBLÉMATIQUES
      await _notificationsPlugin.zonedSchedule(
        id,
        title,
        body,
        tzScheduledTime,
        details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        payload: payload,
      );
    } catch (e) {
      print('Ошибка при планировании: $e / Erreur lors de la planification: $e');
      // Запасной вариант: немедленное уведомление / Fallback: notification immédiate
      await showSimpleNotification(
        id: id,
        title: title,
        body: 'Ошибка планирования: $body', // Erreur de planification: $body
        payload: payload,
      );
    }
  }

  // Запланировать ежедневное уведомление / Planifier une notification quotidienne
  Future<void> scheduleDailyNotification({
    required int id,
    required String title,
    required String body,
    required TimeOfDay time,
    String? payload,
  }) async {
    final now = DateTime.now();
    final scheduledTime = DateTime(
      now.year,
      now.month,
      now.day,
      time.hour,
      time.minute,
    );

    // Если время уже прошло сегодня, запланировать на завтра / Si l'heure est déjà passée aujourd'hui, planifier pour demain
    final actualTime = scheduledTime.isBefore(now)
        ? scheduledTime.add(const Duration(days: 1))
        : scheduledTime;

    await scheduleSimpleNotification(
      id: id,
      title: title,
      body: body,
      scheduledTime: actualTime,
      payload: payload,
    );
  }

  // Отменить уведомление / Annuler une notification
  Future<void> cancelNotification(int id) async {
    await _notificationsPlugin.cancel(id);
  }

  // Отменить все уведомления / Annuler toutes les notifications
  Future<void> cancelAllNotifications() async {
    await _notificationsPlugin.cancelAll();
  }

  // Получить ожидающие уведомления / Obtenir les notifications en attente
  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    return await _notificationsPlugin.pendingNotificationRequests();
  }
}
*/