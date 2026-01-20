// lib/services/background_notification_service.dart
import 'dart:convert';

import 'package:equip_sight/services/firebase_service.dart';
import 'package:equip_sight/services/local_notification_service.dart';
import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Ключ для хранения списка запланированных будильников
/// Clé pour stocker la liste des alarmes programmées
const String _kScheduledAlarmsKey = 'scheduled_machine_alarms';

/// Структура будильника: {
///   "machineId": "...",
///   "machineName": "...",
///   "location": "...",
///   "scheduledAt": 1234567890 (миллисекунды)
/// }
///
/// Callback верхнего уровня, вызываемый AndroidAlarmManager.oneShot.
/// ВАЖНО: этот callback должен быть верхнего уровня (не метод экземпляра).
/// Callback top-level appelé par AndroidAlarmManager.oneShot.
/// IMPORTANT: ce callback doit être top-level (pas de méthode d'instance).
Future<void> timerFinishedCallback() async {
  // Убедиться, что Flutter инициализирован (необходимо в isolate будильника)
  // S'assurer que Flutter est initialisé (nécessaire dans l'isolate d'alarm)
  WidgetsFlutterBinding.ensureInitialized();

  // Инициализировать необходимые сервисы
  // Initialiser les services nécessaires
  await LocalNotificationService.initialize();
  await FirebaseService.ensureInitialized(); // создать вспомогательный метод ниже, если нужно / crée une méthode helper ci-dessous si besoin

  final prefs = await SharedPreferences.getInstance();
  final raw = prefs.getString(_kScheduledAlarmsKey);
  if (raw == null || raw.isEmpty) {
    // Ничего не делать
    // Rien à faire
    return;
  }

  final List<dynamic> list = jsonDecode(raw) as List<dynamic>;
  final nowMillis = DateTime.now().millisecondsSinceEpoch;

  // Пройдемся по списку и обработаем будильники, у которых scheduledAt <= now
  // On parcourra la liste et traitera les alarmes dont scheduledAt <= now
  final List<dynamic> remaining = [];

  for (final item in list) {
    try {
      final map = item as Map<String, dynamic>;
      final scheduledAt = map['scheduledAt'] as int;
      final machineId = map['machineId'] as String?;
      final machineName = map['machineName'] as String?;
      final location = map['location'] as String?;

      if (machineId == null) {
        continue;
      }

      if (scheduledAt <= nowMillis) {
        // Этот будильник сработал -> уведомляем и обновляем Firebase
        // Cette alarme est due -> notifier et mettre à jour Firebase

        final title = '🎉 Машина готова!'; // Machine prête !
        final body =
            'Ваша ${machineName ?? "машина"} (${location ?? ""}) завершила работу'; // Votre ${machineName ?? "machine"} (${location ?? ""}) est terminée

        // Локальное уведомление
        // Notification locale
        try {
          await LocalNotificationService.showNotification(
            title: title,
            body: body,
          );
        } catch (e) {
          // игнорировать / ignore
        }

        // Обновить Firebase (статус завершен)
        // Mettre à jour Firebase (statut terminé)
        try {
          await FirebaseService.updateMachine(machineId, {
            'statut': 'termine',
            'tempsRestant': 0,
          });
        } catch (e) {
          // игнорировать / ignore
        }

        // ПРИМЕЧАНИЕ: если вы хотите также сохранить уведомление в Firestore или сделать что-то еще, вы можете сделать это здесь.
        // NOTE: si tu veux aussi stocker une notification dans Firestore ou faire autre chose, tu peux le faire ici.
      } else {
        // Еще не время -> сохранить для последующей обработки
        // Pas encore temps -> garder pour la suite
        remaining.add(map);
      }
    } catch (e) {
      // если элемент имеет неправильный формат, игнорируем его
      // si un élément est mal formé, on l'ignore
      continue;
    }
  }

  // Сохранить оставшийся список
  // Sauvegarder la liste restante
  await prefs.setString(_kScheduledAlarmsKey, jsonEncode(remaining));
}
