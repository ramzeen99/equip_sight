import 'package:laundry_lens/model/model.dart';
import 'package:laundry_lens/providers/notification_provider.dart';
import 'package:laundry_lens/model/notification_model.dart';
import 'package:laundry_lens/model/user_model.dart';

class PersonalizedNotificationService {
  // 🎯 Проверить, хочет ли пользователь это уведомление
  // 🎯 Vérifier si l'utilisateur veut cette notification
  static bool _shouldSendNotification(
      Machine machine,
      AppUser? user,
      NotificationType type,
      ) {
    if (user == null) return true; // ✅ По умолчанию = отправлять
    // ✅ Par défaut = envoyer

    // 🏠 Проверить настройки пользователя (настроить позже под вашу систему)
    // 🏠 Vérifier les préférences utilisateur (à adapter selon ton système)
    // Пока отправляем всё - позже можно добавить фильтры
    // Pour l'instant, on envoie tout - tu pourras ajouter des filtres plus tard
    final shouldSend = _checkUserPreferences(user, type);

    return shouldSend;
  }

  // 🔧 Проверить настройки пользователя (упрощённая версия)
  // 🔧 Vérifier les préférences utilisateur (version simplifiée)
  static bool _checkUserPreferences(AppUser user, NotificationType type) {
    // 🎯 Здесь позже можно будет интегрировать вашу систему настроек
    // 🎯 Ici tu pourras intégrer ton système de préférences plus tard
    // Пока отправляем все уведомления
    // Pour l'instant, on envoie toutes les notifications
    switch (type) {
      case NotificationType.machineFinished:
        return true; // ✅ Всегда отправлять о завершённых машинах
    // ✅ Toujours envoyer les machines terminées
      case NotificationType.machineAvailable:
        return true; // ✅ Всегда отправлять о доступности
    // ✅ Toujours envoyer les disponibilités
      case NotificationType.reminder:
        return true; // ✅ Всегда отправлять напоминания
    // ✅ Toujours envoyer les rappels
      case NotificationType.maintenance:
        return true; // ✅ Всегда отправлять о техническом обслуживании
    // ✅ Toujours envoyer les maintenances
      case NotificationType.system:
        return true; // ✅ Всегда отправлять системные уведомления
    // ✅ Toujours envoyer les systèmes
    }
  }

  // 📤 Отправить персонализированное уведомление
  // 📤 Envoyer une notification personnalisée
  static void sendPersonalizedNotification({
    required Machine machine,
    required NotificationType type,
    required AppUser? currentUser,
    required NotificationProvider notificationProvider,
  }) {
    // 🎯 Проверить, нужно ли отправлять
    // 🎯 Vérifier si on doit envoyer
    if (!_shouldSendNotification(machine, currentUser, type)) {
      //print('🔕 Уведомление отфильтровано для ${machine.nom}');
      // 🔕 Notification filtrée pour ${machine.nom}
      return;
    }

    // 🏗️ Создать адаптированное уведомление
    // 🏗️ Créer la notification adaptée
    final notification = _createPersonalizedNotification(
      machine,
      type,
      currentUser,
    );

    // ➕ Добавить в локальный провайдер
    // ➕ Ajouter au provider local
    notificationProvider.addNotification(notification, context: null);

    // 📲 Отправить push-уведомление
    // 📲 Envoyer la push notification
    _sendPushNotification(notification, currentUser);
  }

  // 🏗️ Создать персонализированное уведомление
  // 🏗️ Créer une notification personnalisée
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
        // 🎉 Machine prête !
        message = 'Ваша ${machine.nom} (${machine.emplacement}) завершена';
        // Votre ${machine.nom} (${machine.emplacement}) est terminée
        if (user != null) {
          // 👤 Использовать displayNameOrEmail вместо name
          // 👤 Utiliser displayNameOrEmail au lieu de name
          message +=
          ' ${user.displayNameOrEmail.split('@').first}'; // Только имя
          // Juste le prénom
        }
        break;

      case NotificationType.machineAvailable:
        title = '✅ Машина доступна';
        // ✅ Machine disponible
        message =
        '${machine.nom} (${machine.emplacement}) теперь свободна';
        // ${machine.nom} (${machine.emplacement}) est maintenant libre
        break;

      case NotificationType.reminder:
        title = '⏰ Напоминание';
        // ⏰ Rappel
        message = 'Не забудьте освободить ${machine.nom}';
        // N'oubliez pas de libérer ${machine.nom}
        if (user != null) {
          message += ' ${user.displayNameOrEmail.split('@').first}';
        }
        break;

      case NotificationType.maintenance:
        title = '🚧 Техническое обслуживание';
        // 🚧 Maintenance
        message = '${machine.nom} требует вмешательства';
        // ${machine.nom} nécessite une intervention
        break;

      case NotificationType.system:
        title = 'ℹ️ Информация';
        // ℹ️ Information
        message = 'Доступно новое обновление';
        // Nouvelle mise à jour disponible
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

  // 📲 Отправить персонализированное push-уведомление
  // 📲 Envoyer une push notification personnalisée
  static void _sendPushNotification(
      AppNotification notification,
      AppUser? user,
      ) {
    // TODO: Реализовать отправку через FCM
    // TODO: Implémenter l'envoi via FCM
    // Использовать user?.fcmToken для отправки конкретному пользователю
    // Utiliser le user?.fcmToken pour envoyer à un utilisateur spécifique

   /* print('''
    📲 Персонализированное push-уведомление:
    // 📲 Push notification personnalisée:
    Заголовок: ${notification.title}
    // Titre: ${notification.title}
    Сообщение: ${notification.message}
    // Message: ${notification.message}
    Пользователь: ${user?.email ?? 'Все'}
    // Utilisateur: ${user?.email ?? 'Tous'}
    Тип: ${notification.type}
    // Type: ${notification.type}
    ''');*/
  }

  // 🎯 Утилитарный метод для отправки тестового уведомления
  // 🎯 Méthode utilitaire pour envoyer une notification de test
  static void sendTestNotification({
    required NotificationProvider notificationProvider,
    AppUser? currentUser,
  }) {
    final testMachine = Machine(
      id: 'test_machine',
      nom: 'Тестовая машина',
      // Machine Test
      emplacement: 'Первый этаж',
      // Rez-de-chaussée
      statut: MachineStatus.termine,
    );

    sendPersonalizedNotification(
      machine: testMachine,
      type: NotificationType.machineFinished,
      currentUser: currentUser,
      notificationProvider: notificationProvider,
    );
  }

  // 🏠 Фильтровать по любимой комнате (на будущее)
  // 🏠 Filtrer par pièce favorite (pour plus tard)
  /*static bool _isFavoriteRoom(AppUser user, String room) {
    // 🎯 Реализовать, когда будет система настроек
    // 🎯 À implémenter quand tu auras le système de préférences
    // Пока все комнаты "любимые"
    // Pour l'instant, toutes les pièces sont "favorites"
    return true;
  }*/

  // 🔔 Проверить настройки уведомлений пользователя (на будущее)
  // 🔔 Vérifier les paramètres de notification utilisateur (pour plus tard)
  /*static bool _isNotificationTypeEnabled(AppUser user, NotificationType type) {
    // 🎯 Реализовать с вашим PreferencesProvider
    // 🎯 À implémenter avec ton PreferencesProvider
    // Пока все типы включены
    // Pour l'instant, tous les types sont activés
    return true;
  }*/
}