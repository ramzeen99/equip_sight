import 'package:flutter/foundation.dart';
import 'package:laundry_lens/model/preferences_model.dart';
import 'package:laundry_lens/model/notification_model.dart';

class PreferencesProvider with ChangeNotifier {
  NotificationPreferences _preferences = NotificationPreferences();

  NotificationPreferences get preferences => _preferences;

  // 💾 Загрузка предпочтений / Chargement des préférences
  Future<void> loadPreferences() async {
    // TODO: Загрузить из Firestore или SharedPreferences
    // TODO: Charger depuis Firestore ou SharedPreferences
    await Future.delayed(Duration(milliseconds: 500)); // Имитация / Simulation
    notifyListeners();
  }

  // 💾 Сохранение предпочтений / Sauvegarder les préférences
  Future<void> savePreferences(NotificationPreferences newPreferences) async {
    _preferences = newPreferences;
    // TODO: Сохранить в Firestore или SharedPreferences
    // TODO: Sauvegarder dans Firestore ou SharedPreferences
    notifyListeners();
  }

  // 🔧 Обновление предпочтения / Mettre à jour une préférence
  Future<void> updatePreference(NotificationPreferences newPreferences) async {
    await savePreferences(newPreferences);
  }

  // 🎯 Проверка, включен ли тип уведомления / Vérifier si un type de notification est activé
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