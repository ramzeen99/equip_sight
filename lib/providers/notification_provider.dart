// lib/providers/notification_provider.dart
// lib/providers/notification_provider.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:laundry_lens/model/notification_model.dart';
import 'package:laundry_lens/providers/preferences_provider.dart';
import 'package:laundry_lens/services/local_notification_service.dart';
import 'package:laundry_lens/services/notification_service.dart';
import 'package:laundry_lens/services/sound_vibration_service.dart';
//import 'user_provider.dart';

class NotificationProvider with ChangeNotifier {
  static late NotificationProvider instance;

  NotificationProvider() {
    instance = this;
  }

  /// Liste de toutes les notifications
  final List<AppNotification> _notifications = [];

  /// Nombre de notifications non lues
  int _unreadCount = 0;

  /// État de l'application (foreground/background)
  AppLifecycleState _appState = AppLifecycleState.resumed;

  /// Timers actifs par clé "dormPath/machineId"
  final Map<String, Timer> _activeTimers = {};

  // GETTERS
  List<AppNotification> get notifications => _notifications;
  int get unreadCount => _unreadCount;
  bool get isAppInForeground => _appState == AppLifecycleState.resumed;

  /// Mettre à jour l'état de l'application
  void updateAppState(AppLifecycleState state) {
    _appState = state;
  }

  /// 🔹 Démarrer un timer pour une machine dans un dortoir spécifique
  void startMachineTimer({
    required String machineId,
    required String dormPath,
    required int durationInSeconds,
    required PreferencesProvider preferencesProvider,
    required String machineName,
  }) {
    final key = "$dormPath/$machineId";

    // Annuler timer existant
    _activeTimers[key]?.cancel();

    int secondsRemaining = durationInSeconds;

    _activeTimers[key] = Timer.periodic(Duration(seconds: 1), (timer) async {
      secondsRemaining--;

      if (secondsRemaining <= 0) {
        timer.cancel();
        _activeTimers.remove(key);

        // Notification automatique quand le cycle est terminé
        await addQuickNotification(
          title: "Машина завершена",
          message: "La machine \"$machineName\" a terminé son cycle 🎉",
          //type: NotificationType.machineFinished,
          preferencesProvider: preferencesProvider,
        );
      }

      // Optionnel: mettre à jour UI ou compteur en temps réel
      notifyListeners();
    });
  }

  /// Annuler un timer pour une machine
  void cancelMachineTimer({
    required String machineId,
    required String dormPath,
  }) {
    final key = "$dormPath/$machineId";
    _activeTimers[key]?.cancel();
    _activeTimers.remove(key);
    notifyListeners();
  }

  /// Vérifie si une machine a un timer actif
  bool hasActiveTimer({
    required String machineId,
    required String dormPath,
  }) {
    final key = "$dormPath/$machineId";
    return _activeTimers.containsKey(key);
  }

  /// Ajouter une notification rapide (simple)
  Future<void> addQuickNotification({
    required String title,
    required String message,
   // required NotificationType type,
    PreferencesProvider? preferencesProvider,
    BuildContext? context,
    bool showAsPush = true,
  }) async {
    final notification = AppNotification(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      message: message,
      type: NotificationType.machineFinished,
      timestamp: DateTime.now(),
      isRead: false,
    );

    await addNotification(
      notification,
      preferencesProvider: preferencesProvider,
      context: context,
      showAsPush: showAsPush,
    );
  }

  /// Ajouter une notification complète
  Future<void> addNotification(
      AppNotification notification, {
        PreferencesProvider? preferencesProvider,
        BuildContext? context,
        bool showAsPush = true,
      }) async {
    _notifications.insert(0, notification);
    _unreadCount++;
    notifyListeners();

    // Son/vibration selon préférences
    if (preferencesProvider != null) {
      SoundVibrationService.playNotificationEffects(
        type: notification.type,
        preferences: preferencesProvider.preferences,
      );
    }

    final messenger = context != null ? ScaffoldMessenger.of(context) : null;

    // Notification locale
    try {
      await LocalNotificationService.showNotification(
        title: notification.title,
        body: notification.message,
      );
    } catch (e) {
      debugPrint('❌ Erreur notification locale: $e');
    }

    // Snackbar si app visible
    if (isAppInForeground && messenger != null) {
      messenger.showSnackBar(
        SnackBar(
          content: Text('${notification.title}: ${notification.message}'),
          duration: const Duration(seconds: 3),
          action: SnackBarAction(
            label: 'Voir',
            onPressed: () {
              Navigator.pushNamed(messenger.context, 'Notifications');
            },
          ),
        ),
      );
    }

    // Notification push si app en background
    if (!isAppInForeground && showAsPush) {
      try {
        await NotificationService().showNotification(
          title: notification.title,
          body: notification.message,
          notificationId: notification.id.hashCode,
        );
      } catch (e) {
        debugPrint('❌ Erreur push notification: $e');
      }
    }
  }

  /// Programmer une notification future
  Future<void> scheduleNotification({
    required String title,
    required String message,
    required NotificationType type,
    required DateTime scheduledTime,
    PreferencesProvider? preferencesProvider,
    BuildContext? context,
  }) async {
    final notification = AppNotification(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      message: message,
      type: type,
      timestamp: scheduledTime,
      isRead: false,
    );

    try {
      await NotificationService().scheduleNotification(
        title: title,
        body: message,
        scheduledTime: scheduledTime,
        notificationId: notification.id.hashCode,
      );
    } catch (e) {
      debugPrint('❌ Erreur programmation notification: $e');
    }
  }

  /// Marquer une notification comme lue
  void markAsRead(String notificationId) {
    final index = _notifications.indexWhere((n) => n.id == notificationId);
    if (index != -1 && !_notifications[index].isRead) {
      _notifications[index] = _notifications[index].copyWith(isRead: true);
      _unreadCount--;
      notifyListeners();
    }
  }

  /// Marquer toutes les notifications comme lues
  void markAllAsRead() {
    for (var i = 0; i < _notifications.length; i++) {
      if (!_notifications[i].isRead) {
        _notifications[i] = _notifications[i].copyWith(isRead: true);
      }
    }
    _unreadCount = 0;
    notifyListeners();
  }

  /// Supprimer une notification
  void removeNotification(String notificationId) {
    final notification = _notifications.firstWhere((n) => n.id == notificationId);

    if (!notification.isRead) _unreadCount--;

    _notifications.removeWhere((n) => n.id == notificationId);
    notifyListeners();
  }

  /// Nettoyer les notifications anciennes
  void clearOldNotifications({int days = 30}) {
    final cutoff = DateTime.now().subtract(Duration(days: days));
    _notifications.removeWhere((n) => n.timestamp.isBefore(cutoff));
    _unreadCount = _notifications.where((n) => !n.isRead).length;
    notifyListeners();
  }
}

/*import 'dart:async';
import 'package:flutter/material.dart';
import 'package:laundry_lens/model/notification_model.dart';
import 'package:laundry_lens/services/sound_vibration_service.dart';
import 'package:laundry_lens/services/notification_service.dart';
import 'package:laundry_lens/providers/preferences_provider.dart';
import 'package:laundry_lens/services/local_notification_service.dart';

class NotificationProvider with ChangeNotifier {
  static late NotificationProvider instance;
  NotificationProvider() {
    instance = this; // initialise le singleton / инициализирует синглтон
  }

  final List<AppNotification> _notifications = [];
  int _unreadCount = 0;
  AppLifecycleState _appState = AppLifecycleState.resumed;

  List<AppNotification> get notifications => _notifications;
  int get unreadCount => _unreadCount;
  bool get isAppInForeground => _appState == AppLifecycleState.resumed;

  /// Pour gérer plusieurs timers simultanés par machine
  /// Для управления несколькими таймерами одновременно для каждой машины
  final Map<String, Timer> _activeTimers = {};

  // 🔥 Mettre à jour l'état de l'application
  // 🔥 Обновить состояние приложения
  void updateAppState(AppLifecycleState state) {
    _appState = state;
  }

  /// Démarrer un timer pour une machine
  /// Запустить таймер для машины
  void startMachineTimer({
    required String machineName,
    required int durationInSeconds,
    required PreferencesProvider preferencesProvider,
  }) {
    // Si un timer existe déjà pour cette machine, on l'annule
    // Если таймер уже существует для этой машины, отменяем его
    _activeTimers[machineName]?.cancel();

    int secondsRemaining = durationInSeconds;

    _activeTimers[machineName] = Timer.periodic(Duration(seconds: 1), (timer) {
      secondsRemaining--;

      if (secondsRemaining <= 0) {
        timer.cancel();
        _activeTimers.remove(machineName);

        // Notification automatique
        // Автоматическое уведомление
        addQuickNotification(
          title: "Машина завершена", // "Machine terminée"
          message: "Машина \"$machineName\" завершила цикл 🎉", // "La machine \"$machineName\" a terminé son cycle 🎉"
          type: NotificationType.machineFinished,
          preferencesProvider: preferencesProvider,
          showAsPush: true,
        );
      }
    });
  }

  void cancelMachineTimer(String machineName) {
    _activeTimers[machineName]?.cancel();
    _activeTimers.remove(machineName);
  }

  /// Ajouter une notification complète
  /// Добавить полное уведомление
  Future<void> addNotification(
      AppNotification notification, {
        required BuildContext? context,
        PreferencesProvider? preferencesProvider,
        bool showAsPush = true,
      }) async {
    _notifications.insert(0, notification);
    _unreadCount++;
    notifyListeners();

    // Son/vibration
    if (preferencesProvider != null) {
      SoundVibrationService.playNotificationEffects(
        type: notification.type,
        preferences: preferencesProvider.preferences,
      );
    }

    // Si context fourni, créer une référence avant await
    final messenger = context != null ? ScaffoldMessenger.of(context) : null;

    // Notification locale
    await _sendLocalPhoneNotification(notification);

    // Snackbar (si app visible)
    if (isAppInForeground && messenger != null) {
      messenger.showSnackBar(
        SnackBar(
          content: Text('${notification.title}: ${notification.message}'),
          duration: const Duration(seconds: 3),
          action: SnackBarAction(
            label: 'Посмотреть',
            onPressed: () {
              Navigator.pushNamed(messenger.context, 'Notifications');
            },
          ),
        ),
      );
    }

    // Notification push système
    if (!isAppInForeground && showAsPush) {
      await _sendPushNotification(notification);
    }
  }


  Future<void> _sendLocalPhoneNotification(AppNotification notification) async {
    try {
      await LocalNotificationService.showNotification(
        title: notification.title,
        body: notification.message,
      );
      //print('📱 Локальное уведомление успешно отправлено'); // '📱 Notification locale envoyée avec succès'
    } catch (e) {
     // print('❌ Ошибка локального уведомления: $e'); // '❌ Erreur notification locale: $e'
    }
  }

 /* void _showInAppNotification(BuildContext context, AppNotification notification) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${notification.title}: ${notification.message}'),
        duration: const Duration(seconds: 3),
        action: SnackBarAction(
          label: 'Посмотреть', // 'Voir'
          onPressed: () {
            Navigator.pushNamed(context, 'Notifications');
          },
        ),
      ),
    );
  }*/

  Future<void> _sendPushNotification(AppNotification notification) async {
    try {
      await NotificationService().showPushNotification(
        title: notification.title,
        body: notification.message,
        notificationId: notification.id.hashCode,
      );
      //print('🔔 Push-уведомление отправлено'); // '🔔 Notification push envoyée'
    } catch (e) {
     // print('❌ Ошибка системного push-уведомления: $e'); // '❌ Erreur notification push système: $e'
    }
  }

  /// Méthode rapide pour créer une notification
  /// Быстрый метод создания уведомления
  Future<void> addQuickNotification({
    required String title,
    required String message,
    required NotificationType type,
    BuildContext? context,
    PreferencesProvider? preferencesProvider,
    bool showAsPush = true,
  }) async {
    final notification = AppNotification(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      message: message,
      type: type,
      timestamp: DateTime.now(),
      isRead: false,
    );

    await addNotification(
      notification,
      context: context,
      preferencesProvider: preferencesProvider,
      showAsPush: showAsPush,
    );
  }

  /// Programmer une notification future
  /// Запланировать уведомление на будущее
  Future<void> scheduleNotification({
    required String title,
    required String message,
    required NotificationType type,
    required DateTime scheduledTime,
    BuildContext? context,
    PreferencesProvider? preferencesProvider,
  }) async {
    final notification = AppNotification(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      message: message,
      type: type,
      timestamp: scheduledTime,
      isRead: false,
    );

    try {
      await NotificationService().scheduleNotification(
        title: title,
        body: message,
        scheduledTime: scheduledTime,
        notificationId: notification.id.hashCode,
      );
      //print('⏰ Уведомление запланировано на: $scheduledTime'); // '⏰ Notification programmée pour : $scheduledTime'
    } catch (e) {
      //print('❌ Ошибка планирования уведомления: $e'); // '❌ Erreur programmation notification: $e'
    }
  }

  // Marquer comme lu
  // Пометить как прочитанное
  void markAsRead(String notificationId) {
    final index = _notifications.indexWhere((n) => n.id == notificationId);
    if (index != -1 && !_notifications[index].isRead) {
      _notifications[index] = _notifications[index].copyWith(isRead: true);
      _unreadCount--;
      notifyListeners();
    }
  }

  void markAllAsRead() {
    for (var i = 0; i < _notifications.length; i++) {
      if (!_notifications[i].isRead) {
        _notifications[i] = _notifications[i].copyWith(isRead: true);
      }
    }
    _unreadCount = 0;
    notifyListeners();
  }

  void removeNotification(String notificationId) {
    final notification = _notifications.firstWhere(
          (n) => n.id == notificationId,
    );

    if (!notification.isRead) _unreadCount--;

    _notifications.removeWhere((n) => n.id == notificationId);
    notifyListeners();
  }

  void clearOldNotifications({int days = 30}) {
    final cutoff = DateTime.now().subtract(Duration(days: days));
    _notifications.removeWhere((n) => n.timestamp.isBefore(cutoff));
    _unreadCount = _notifications.where((n) => !n.isRead).length;
    notifyListeners();
  }
}
*/