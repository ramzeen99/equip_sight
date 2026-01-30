class NotificationPreferences {
  final bool machineFinished;
  final bool machineAvailable;
  final bool reminders;
  final bool maintenance;
  final bool system;
  final bool soundEnabled;
  final bool vibrationEnabled;
  final List<String> favoriteRooms;

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
