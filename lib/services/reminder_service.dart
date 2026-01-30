import 'package:equip_sight/model/model.dart';
import 'package:equip_sight/model/notification_model.dart';
import 'package:equip_sight/providers/notification_provider.dart';
import 'package:equip_sight/providers/preferences_provider.dart';

class ReminderService {
  static void checkAndTriggerReminder({
    required Machine machine,
    required NotificationProvider notificationProvider,
    required PreferencesProvider preferencesProvider,
  }) {
    if (!preferencesProvider.isNotificationTypeEnabled(
      NotificationType.reminder,
    )) {
      return;
    }

    if (machine.endTime == null || machine.statut != MachineStatus.occupe) {
      return;
    }

    final remainingMinutes = machine.endTime!
        .toDate()
        .difference(DateTime.now())
        .inMinutes;

    if (remainingMinutes <= 0) {
      _triggerReminder(
        machine,
        notificationProvider,
        '⏰ ${machine.nom} завершена',
        'Машина готова. Пожалуйста, освободите её.',
      );
      return;
    }

    if (remainingMinutes <= 5 && remainingMinutes > 4) {
      _triggerReminder(
        machine,
        notificationProvider,
        '⏰ Скоро завершение',
        '${machine.nom} закончится через 5 минут.',
      );
    }
  }

  static void _triggerReminder(
    Machine machine,
    NotificationProvider notificationProvider,
    String title,
    String message,
  ) {
    final notification = AppNotification(
      id: 'reminder_${machine.id}_${title.hashCode}',
      title: title,
      message: message,
      timestamp: DateTime.now(),
      type: NotificationType.reminder,
      machineId: machine.id,
    );

    notificationProvider.addNotification(notification, context: null);
  }
}
