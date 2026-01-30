import 'package:equip_sight/model/model.dart';
import 'package:equip_sight/model/notification_model.dart';
import 'package:equip_sight/model/user_model.dart';
import 'package:equip_sight/providers/notification_provider.dart';

class PersonalizedNotificationService {
  static bool _shouldSendNotification(
    Machine machine,
    AppUser? user,
    NotificationType type,
  ) {
    if (user == null) return true;
    final shouldSend = _checkUserPreferences(user, type);

    return shouldSend;
  }

  static bool _checkUserPreferences(AppUser user, NotificationType type) {
    switch (type) {
      case NotificationType.machineFinished:
        return true;
      case NotificationType.machineAvailable:
        return true;
      case NotificationType.reminder:
        return true;
      case NotificationType.maintenance:
        return true;
      case NotificationType.system:
        return true;
    }
  }

  static void sendPersonalizedNotification({
    required Machine machine,
    required NotificationType type,
    required AppUser? currentUser,
    required NotificationProvider notificationProvider,
  }) {
    if (!_shouldSendNotification(machine, currentUser, type)) {
      return;
    }

    final notification = _createPersonalizedNotification(
      machine,
      type,
      currentUser,
    );
    notificationProvider.addNotification(notification, context: null);

    _sendPushNotification(notification, currentUser);
  }

  static AppNotification _createPersonalizedNotification(
    Machine machine,
    NotificationType type,
    AppUser? user,
  ) {
    String title = '';
    String message = '';

    switch (type) {
      case NotificationType.machineFinished:
        title = '🎉 Машина готова!';
        message = 'Ваша ${machine.nom} (${machine.emplacement}) завершена';
        if (user != null) {
          message += ' ${user.displayNameOrEmail.split('@').first}';
        }
        break;

      case NotificationType.machineAvailable:
        title = '✅ Машина доступна';
        message = '${machine.nom} (${machine.emplacement}) теперь свободна';
        break;
      case NotificationType.reminder:
        title = '⏰ Напоминание';
        message = 'Не забудьте освободить ${machine.nom}';
        if (user != null) {
          message += ' ${user.displayNameOrEmail.split('@').first}';
        }
        break;

      case NotificationType.maintenance:
        title = '🚧 Техническое обслуживание';
        message = '${machine.nom} требует вмешательства';
        break;

      case NotificationType.system:
        title = 'ℹ️ Информация';
        message = 'Доступно новое обновление';
        break;
    }

    return AppNotification(
      id: '${machine.id}_${type.name}_${DateTime.now().millisecondsSinceEpoch}',
      title: title,
      message: message,
      timestamp: DateTime.now(),
      type: type,
      machineId: machine.id,
      userId: user?.id,
    );
  }

  static void _sendPushNotification(
    AppNotification notification,
    AppUser? user,
  ) {
    // TODO: Реализовать отправку через FCM
    // TODO: Implémenter l'envoi via FCM
  }
  static void sendTestNotification({
    required NotificationProvider notificationProvider,
    AppUser? currentUser,
  }) {
    final testMachine = Machine(
      id: 'test_machine',
      nom: 'Тестовая машина',
      emplacement: 'Первый этаж',
      statut: MachineStatus.termine,
    );

    sendPersonalizedNotification(
      machine: testMachine,
      type: NotificationType.machineFinished,
      currentUser: currentUser,
      notificationProvider: notificationProvider,
    );
  }
}
