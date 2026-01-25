import 'package:equip_sight/model/model.dart';
import 'package:equip_sight/model/notification_model.dart';
import 'package:equip_sight/providers/notification_provider.dart';
import 'package:equip_sight/providers/preferences_provider.dart';

class ReminderService {
  static String _generateReminderMessage(Machine machine) {
    if (machine.endTime == null) {
      return 'Не забудьте проверить ${machine.nom}';
    }

    final remaining = machine.endTime!
        .toDate()
        .difference(DateTime.now())
        .inMinutes;

    if (remaining <= 0) {
      return '${machine.nom} должна быть завершена — не забудьте освободить';
    }

    if (remaining <= 1) {
      return '${machine.nom} завершится через $remaining мин';
    }

    return 'Не забудьте освободить ${machine.nom}, когда она будет готова';
  }

  static void _triggerReminder(
    Machine machine,
    NotificationProvider notificationProvider,
    PreferencesProvider preferencesProvider,
  ) {
    if (!preferencesProvider.isNotificationTypeEnabled(
      NotificationType.reminder,
    )) {
      return;
    }

    final reminderNotification = AppNotification(
      id: 'reminder_${machine.id}_${DateTime.now().millisecondsSinceEpoch}',
      title: '⏰ Напоминание - ${machine.nom}',
      message: _generateReminderMessage(machine),
      timestamp: DateTime.now(),
      type: NotificationType.reminder,
      machineId: machine.id,
    );

    notificationProvider.addNotification(reminderNotification, context: null);
  }
}
