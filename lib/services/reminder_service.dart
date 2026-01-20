import 'dart:async';

import 'package:equip_sight/model/model.dart';
import 'package:equip_sight/model/notification_model.dart';
import 'package:equip_sight/providers/notification_provider.dart';
import 'package:equip_sight/providers/preferences_provider.dart';

class ReminderService {
  // Карта активных таймеров напоминаний
  // Map of active reminder timers
  static final Map<String, Timer> _activeTimers = {};

  // 🎯 Запланировать напоминание для машины
  // 🎯 Schedule a reminder for a machine
  static void scheduleReminder({
    required Machine machine,
    required NotificationProvider notificationProvider,
    required PreferencesProvider preferencesProvider,
  }) {
    // 🚫 Отменить любое существующее напоминание для этой машины
    // 🚫 Cancel any existing reminder for this machine
    cancelReminder(machine.id);

    // ⏰ Рассчитать время напоминания
    // ⏰ Calculate reminder timing
    final reminderTime = _calculateReminderTime(machine);

    if (reminderTime != null) {
      /*print(
        '⏰ Напоминание запланировано для ${machine.nom} через ${reminderTime.inMinutes} мин',
      );*/

      // 🕐 Создать таймер
      // 🕐 Create timer
      _activeTimers[machine.id] = Timer(reminderTime, () {
        _triggerReminder(machine, notificationProvider, preferencesProvider);
      });
    }
  }

  // 🧮 Рассчитать время напоминания
  // 🧮 Calculate reminder time
  static Duration? _calculateReminderTime(Machine machine) {
    if (machine.statut != MachineStatus.occupe) return null;
    if (machine.tempsRestant == null) return null;

    // 🎯 Интеллектуальные стратегии напоминаний:

    // 1. 📉 Напоминание когда осталось мало времени (20% от общего времени)
    // 1. 📉 Reminder when little time left (20% of total time)
    final totalTime = 5; // Общее время работы машины в минутах
    final remainingTime = machine.tempsRestant!;

    if (remainingTime <= (totalTime * 0.2)) {
      // 20% оставшегося времени
      return Duration(minutes: 1); // Напоминание через 1 минуту
    }

    // 2. ⏰ Напоминание если машина должна была завершиться, но не завершилась
    // 2. ⏰ Reminder if machine should have finished but hasn't
    final now = DateTime.now();
    final expectedEndTime = now.add(Duration(minutes: remainingTime));

    // Если прошло более 10 минут после ожидаемого времени завершения
    // If more than 10 minutes have passed since expected end time
    if (now.isAfter(expectedEndTime.add(Duration(minutes: 10)))) {
      return Duration.zero; // Мгновенное напоминание
    }

    // 3. 🎊 Напоминание "почти готово"
    // 3. 🎊 "Almost finished" reminder
    if (remainingTime <= 1) {
      return Duration(minutes: remainingTime); // Напоминание в конце
    }

    return null; // Напоминание не требуется
  }

  // 🔔 Активировать напоминание
  // 🔔 Trigger the reminder
  static void _triggerReminder(
    Machine machine,
    NotificationProvider notificationProvider,
    PreferencesProvider preferencesProvider,
  ) {
    // 🚫 Проверить, включены ли напоминания
    // 🚫 Check if reminders are enabled
    if (!preferencesProvider.isNotificationTypeEnabled(
      NotificationType.reminder,
    )) {
      //print('🔕 Напоминания отключены - уведомление не отправлено');
      return;
    }

    //print('🔔 Активация напоминания для ${machine.nom}');

    // 📝 Создать уведомление-напоминание
    // 📝 Create reminder notification
    final reminderNotification = AppNotification(
      id: 'reminder_${machine.id}_${DateTime.now().millisecondsSinceEpoch}',
      title: '⏰ Напоминание - ${machine.nom}',
      message: _generateReminderMessage(machine),
      timestamp: DateTime.now(),
      type: NotificationType.reminder,
      machineId: machine.id,
    );

    // ➕ Добавить уведомление
    // ➕ Add notification
    notificationProvider.addNotification(reminderNotification, context: null);

    // 🗑️ Очистить таймер
    // 🗑️ Clean up timer
    _activeTimers.remove(machine.id);
  }

  // 📝 Сгенерировать интеллектуальное сообщение напоминания
  // 📝 Generate intelligent reminder message
  static String _generateReminderMessage(Machine machine) {
    if (machine.tempsRestant == null) {
      return 'Не забудьте проверить ${machine.nom}';
    }

    if (machine.tempsRestant! <= 0) {
      return '${machine.nom} должна быть завершена - не забудьте освободить';
    }

    if (machine.tempsRestant! <= 1) {
      return '${machine.nom} завершится через ${machine.tempsRestant} мин';
    }

    return 'Не забудьте освободить ${machine.nom}, когда она будет готова';
  }

  // 🚫 Отменить напоминание
  // 🚫 Cancel a reminder
  static void cancelReminder(String machineId) {
    _activeTimers[machineId]?.cancel();
    _activeTimers.remove(machineId);
  }

  // 🗑️ Отменить все напоминания
  // 🗑️ Cancel all reminders
  static void cancelAllReminders() {
    _activeTimers.forEach((machineId, timer) {
      timer.cancel();
    });
    _activeTimers.clear();
    //print('🗑️ Все напоминания отменены');
  }

  // 📊 Статус активных напоминаний
  // 📊 Status of active reminders
  static Map<String, Duration> getActiveReminders() {
    final activeReminders = <String, Duration>{};

    _activeTimers.forEach((machineId, timer) {
      // TODO: Реализовать получение оставшегося времени таймеров
      // TODO: Implement getting remaining time of timers
      activeReminders[machineId] = Duration.zero;
    });

    return activeReminders;
  }
}
