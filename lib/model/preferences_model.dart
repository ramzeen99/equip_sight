class NotificationPreferences {
  final bool machineFinished;
  // FR : 🎉 Notifications : machines terminées
  // RU : 🎉 Уведомления: стирка завершена

  final bool machineAvailable;
  // FR : ✅ Notifications : machines disponibles
  // RU : ✅ Уведомления: доступные машины

  final bool reminders;
  // FR : ⏰ Rappels
  // RU : ⏰ Напоминания

  final bool maintenance;
  // FR : 🚧 Maintenance
  // RU : 🚧 Техническое обслуживание

  final bool system;
  // FR : ℹ️ Notifications système
  // RU : ℹ️ Системные уведомления

  final bool soundEnabled;
  // FR : 🔊 Son activé
  // RU : 🔊 Звук включён

  final bool vibrationEnabled;
  // FR : 📳 Vibration activée
  // RU : 📳 Вибрация включена

  final List<String> favoriteRooms;
  // FR : 🏠 Pièces favorites
  // RU : 🏠 Избранные комнаты

  NotificationPreferences({
    this.machineFinished = true,
    this.machineAvailable = true,
    this.reminders = true,
    this.maintenance = true,
    this.system = true,
    this.soundEnabled = true,
    this.vibrationEnabled = true,
    this.favoriteRooms = const [],
  });

  // 🗺️ FR : Conversion vers une Map (pour Firestore)
  // 🗺️ RU : Преобразование в Map (для Firestore)
  Map<String, dynamic> toMap() {
    return {
      'machineFinished': machineFinished,
      'machineAvailable': machineAvailable,
      'reminders': reminders,
      'maintenance': maintenance,
      'system': system,
      'soundEnabled': soundEnabled,
      'vibrationEnabled': vibrationEnabled,
      'favoriteRooms': favoriteRooms,
    };
  }

  // 🏭 FR : Factory pour reconstruire depuis Firestore
  // 🏭 RU : Factory-конструктор для восстановления данных из Firestore
  factory NotificationPreferences.fromMap(Map<String, dynamic> data) {
    return NotificationPreferences(
      machineFinished: data['machineFinished'] ?? true,
      machineAvailable: data['machineAvailable'] ?? true,
      reminders: data['reminders'] ?? true,
      maintenance: data['maintenance'] ?? true,
      system: data['system'] ?? true,
      soundEnabled: data['soundEnabled'] ?? true,
      vibrationEnabled: data['vibrationEnabled'] ?? true,
      favoriteRooms: List<String>.from(data['favoriteRooms'] ?? []),
    );
  }

  // 📝 FR : Copier l'objet en modifiant certaines valeurs
  // 📝 RU : Создать копию объекта с изменёнными значениями
  NotificationPreferences copyWith({
    bool? machineFinished,
    bool? machineAvailable,
    bool? reminders,
    bool? maintenance,
    bool? system,
    bool? soundEnabled,
    bool? vibrationEnabled,
    List<String>? favoriteRooms,
  }) {
    return NotificationPreferences(
      machineFinished: machineFinished ?? this.machineFinished,
      machineAvailable: machineAvailable ?? this.machineAvailable,
      reminders: reminders ?? this.reminders,
      maintenance: maintenance ?? this.maintenance,
      system: system ?? this.system,
      soundEnabled: soundEnabled ?? this.soundEnabled,
      vibrationEnabled: vibrationEnabled ?? this.vibrationEnabled,
      favoriteRooms: favoriteRooms ?? this.favoriteRooms,
    );
  }
}
