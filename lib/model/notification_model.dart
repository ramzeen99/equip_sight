// lib/models/notification_model.dart

// FR : Types de notifications disponibles
// RU : Доступные типы уведомлений
enum NotificationType {
  machineFinished, // FR : Machine terminée — RU : Стирка завершена
  machineAvailable, // FR : Machine disponible — RU : Машина доступна
  reminder, // FR : Rappel — RU : Напоминание
  maintenance, // FR : Maintenance — RU : Техническое обслуживание
  system, // FR : Message système — RU : Системное сообщение
}

class AppNotification {
  // FR : Modèle représentant une notification dans l’application
  // RU : Модель, представляющая уведомление в приложении

  final String id; // FR : Identifiant de la notification — RU : ID уведомления
  final String title; // FR : Titre — RU : Заголовок
  final String message; // FR : Message — RU : Сообщение
  final DateTime timestamp; // FR : Date et heure — RU : Дата и время
  final bool isRead; // FR : Notification lue ou non — RU : Прочитано или нет
  final NotificationType type; // FR : Type de notification — RU : Тип уведомления
  final String? machineId; // FR : ID de la machine liée (si applicable) — RU : ID машины (если есть)
  final String? userId; // FR : ID utilisateur (si applicable) — RU : ID пользователя (если есть)

  AppNotification({
    required this.id,
    required this.title,
    required this.message,
    required this.timestamp,
    this.isRead = false,
    required this.type,
    this.machineId,
    this.userId,
  });

  // FR : Méthode copyWith pour cloner et modifier partiellement
  // RU : Метод copyWith для создания копии с изменёнными полями
  AppNotification copyWith({
    String? id,
    String? title,
    String? message,
    DateTime? timestamp,
    bool? isRead,
    NotificationType? type,
    String? machineId,
    String? userId,
  }) {
    return AppNotification(
      id: id ?? this.id,
      title: title ?? this.title,
      message: message ?? this.message,
      timestamp: timestamp ?? this.timestamp,
      isRead: isRead ?? this.isRead,
      type: type ?? this.type,
      machineId: machineId ?? this.machineId,
      userId: userId ?? this.userId,
    );
  }

  // FR : Conversion en Map pour stockage Firebase
  // RU : Преобразование в Map для сохранения в Firebase
  Map<String, dynamic> toMap() {
    return {
      'id': id,                 // FR : Identifiant — RU : Идентификатор
      'title': title,           // FR : Titre — RU : Заголовок
      'message': message,       // FR : Message — RU : Сообщение
      'timestamp': timestamp.millisecondsSinceEpoch, // FR : Horodatage — RU : Время в мс
      'isRead': isRead,         // FR : Lu ? — RU : Прочитано?
      'type': type.toString(),  // FR : Type — RU : Тип
      'machineId': machineId,   // FR : ID machine — RU : ID машины
      'userId': userId,         // FR : ID utilisateur — RU : ID пользователя
    };
  }
}
