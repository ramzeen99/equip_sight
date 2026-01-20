import 'package:equip_sight/model/notification_model.dart';
import 'package:equip_sight/model/preferences_model.dart';
import 'package:flutter/foundation.dart';

class PreferencesProvider with ChangeNotifier {
  NotificationPreferences _preferences = NotificationPreferences();

  NotificationPreferences get preferences => _preferences;

  Future<void> loadPreferences() async {
    // TODO: Загрузить из Firestore или SharedPreferences
    // TODO: Charger depuis Firestore ou SharedPreferences
    await Future.delayed(Duration(milliseconds: 500));
    notifyListeners();
  }

  Future<void> savePreferences(NotificationPreferences newPreferences) async {
    _preferences = newPreferences;
    // TODO: Сохранить в Firestore или SharedPreferences
    // TODO: Sauvegarder dans Firestore ou SharedPreferences
    notifyListeners();
  }

  Future<void> updatePreference(NotificationPreferences newPreferences) async {
    await savePreferences(newPreferences);
  }

  bool isNotificationTypeEnabled(NotificationType type) {
    switch (type) {
      case NotificationType.machineFinished:
        return _preferences.machineFinished;
      case NotificationType.machineAvailable:
        return _preferences.machineAvailable;
      case NotificationType.reminder:
        return _preferences.reminders;
      case NotificationType.maintenance:
        return _preferences.maintenance;
      case NotificationType.system:
        return _preferences.system;
    }
  }
}
