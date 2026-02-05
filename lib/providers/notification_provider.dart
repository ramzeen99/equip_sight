import 'dart:async';

import 'package:equip_sight/model/notification_model.dart';
import 'package:equip_sight/providers/preferences_provider.dart';
import 'package:equip_sight/services/local_notification_service.dart';
import 'package:equip_sight/services/notification_service.dart';
import 'package:equip_sight/services/sound_vibration_service.dart';
import 'package:flutter/material.dart';

import '../main.dart';
import '../pages/notifications_page.dart';

class NotificationProvider with ChangeNotifier {
  final List<AppNotification> _notifications = [];
  int _unreadCount = 0;
  AppLifecycleState _appState = AppLifecycleState.resumed;
  final Map<String, Timer> _activeTimers = {};
  List<AppNotification> get notifications => _notifications;
  int get unreadCount => _unreadCount;
  bool get isAppInForeground => _appState == AppLifecycleState.resumed;
  void updateAppState(AppLifecycleState state) {
    _appState = state;
  }

  void startMachineTimer({
    required String machineId,
    required String dormPath,
    required int durationInSeconds,
    required PreferencesProvider preferencesProvider,
    required String machineName,
  }) {
    final key = "$dormPath/$machineId";
    _activeTimers[key]?.cancel();
    int secondsRemaining = durationInSeconds;

    _activeTimers[key] = Timer.periodic(Duration(seconds: 1), (timer) async {
      secondsRemaining--;

      if (secondsRemaining <= 0) {
        timer.cancel();
        _activeTimers.remove(key);
        await addQuickNotification(
          title: "Машина завершена",
          message: "Машина   \"$machineName\" закончила свой цикл 🎉",
          preferencesProvider: preferencesProvider,
        );
      }
      notifyListeners();
    });
  }

  void cancelMachineTimer({
    required String machineId,
    required String dormPath,
  }) {
    final key = "$dormPath/$machineId";
    _activeTimers[key]?.cancel();
    _activeTimers.remove(key);
    notifyListeners();
  }

  bool hasActiveTimer({required String machineId, required String dormPath}) {
    final key = "$dormPath/$machineId";
    return _activeTimers.containsKey(key);
  }

  Future<void> addQuickNotification({
    required String title,
    required String message,
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

  Future<void> addNotification(
    AppNotification notification, {
    PreferencesProvider? preferencesProvider,
    BuildContext? context,
    bool showAsPush = true,
  }) async {
    _notifications.insert(0, notification);
    _unreadCount++;
    notifyListeners();

    if (preferencesProvider != null) {
      SoundVibrationService.playNotificationEffects(
        type: notification.type,
        preferences: preferencesProvider.preferences,
      );
    }

    final messenger = context != null ? ScaffoldMessenger.of(context) : null;

    try {
      await LocalNotificationService.showNotification(
        title: notification.title,
        body: notification.message,
      );
    } catch (e) {
      debugPrint('❌ Ошибка локального уведомления: $e');
    }

    if (isAppInForeground && messenger != null) {
      ScaffoldMessenger.of(navigatorKey.currentContext!).showSnackBar(
        SnackBar(
          content: Text('${notification.title}: ${notification.message}'),
          duration: const Duration(seconds: 3),
          action: SnackBarAction(
            label: 'Просмотреть',
            onPressed: () {
              Navigator.pushNamed(
                navigatorKey.currentContext!,
                NotificationsPage.id,
              );
            },
          ),
        ),
      );
    }

    if (!isAppInForeground && showAsPush) {
      try {
        await NotificationService().showNotification(
          title: notification.title,
          body: notification.message,
          notificationId: notification.id.hashCode,
        );
      } catch (e) {
        debugPrint('❌ Ошибка push-уведомления: $e');
      }
    }
  }

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
      debugPrint('❌ Ошибка планирования уведомления:: $e');
    }
  }

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
