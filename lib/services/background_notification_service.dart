import 'dart:convert';

import 'package:equip_sight/services/firebase_service.dart';
import 'package:equip_sight/services/local_notification_service.dart';
import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

const String _kScheduledAlarmsKey = 'scheduled_machine_alarms';
Future<void> timerFinishedCallback() async {
  WidgetsFlutterBinding.ensureInitialized();
  await LocalNotificationService.initialize();
  await FirebaseService.ensureInitialized();

  final prefs = await SharedPreferences.getInstance();
  final raw = prefs.getString(_kScheduledAlarmsKey);
  if (raw == null || raw.isEmpty) {
    return;
  }

  final List<dynamic> list = jsonDecode(raw) as List<dynamic>;
  final nowMillis = DateTime.now().millisecondsSinceEpoch;
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
        final title = '🎉 Машина готова!';
        final body =
            'Ваша ${machineName ?? "машина"} (${location ?? ""}) завершила работу';

        try {
          await LocalNotificationService.showNotification(
            title: title,
            body: body,
          );
        } catch (e) {
          // игнорировать / ignore
        }

        try {
          await FirebaseService.updateMachine(machineId, {
            'statut': 'termine',
            'tempsRestant': 0,
          });
        } catch (e) {
          // игнорировать / ignore
        }
      } else {
        remaining.add(map);
      }
    } catch (e) {
      continue;
    }
  }

  await prefs.setString(_kScheduledAlarmsKey, jsonEncode(remaining));
}
