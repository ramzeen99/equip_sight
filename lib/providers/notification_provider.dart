import 'dart:async';

import 'package:equip_sight/model/notification_model.dart';
import 'package:equip_sight/providers/preferences_provider.dart';
import 'package:equip_sight/services/local_notification_service.dart';
import 'package:equip_sight/services/notification_service.dart';
import 'package:equip_sight/services/sound_vibration_service.dart';
import 'package:flutter/material.dart';

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
  bool hasActiveTimer({required String machineId, required String dormPath}) {
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
    final notification = _notifications.firstWhere(
      (n) => n.id == notificationId,
    );

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
