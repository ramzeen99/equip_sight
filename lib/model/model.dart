import 'package:cloud_firestore/cloud_firestore.dart';

// FR : Statut possible d'une machine
// RU : Возможные статусы машины
enum MachineStatus { libre, occupe, termine }

class Machine {
  final String id;
  final String nom;
  final String emplacement;
  final MachineStatus statut;
  final int? tempsRestant;
  final int? heatLeft;
  final String? utilisateurActuel;
  final Timestamp? lastUpdate;

  // Nouveau champ pour filtrer selon le dortoir / New field for dorm filtering
  final String? dormPath;

  Machine({
    required this.id,
    required this.nom,
    required this.emplacement,
    required this.statut,
    this.tempsRestant,
    this.heatLeft,
    this.utilisateurActuel,
    this.lastUpdate,
    this.dormPath,
  });
  Machine copyWith({
    String? id,
    String? nom,
    String? emplacement,
    MachineStatus? statut,
    int? tempsRestant,
    String? utilisateurActuel,
  }) {
    return Machine(
      id: id ?? this.id,
      nom: nom ?? this.nom,
      emplacement: emplacement ?? this.emplacement,
      statut: statut ?? this.statut,
      tempsRestant: tempsRestant ?? this.tempsRestant,
      utilisateurActuel: utilisateurActuel ?? this.utilisateurActuel,
    );
  }
  // FR : Convertir l'objet Machine en Map (pour Firebase)
  // RU : Преобразование объекта Machine в карту (для Firebase)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nom': nom,
      'emplacement': emplacement,
      'statut': _statusToString(statut),
      'tempsRestant': tempsRestant,
      'utilisateurActuel': utilisateurActuel,
      'heatLeft': heatLeft,
      'dormPath': dormPath,
      //'lastUpdate': FieldValue.serverTimestamp(),
    };
  }

  // FR : Créer une instance Machine à partir des données Firebase
  // RU : Создание экземпляра Machine из данных Firebase
  factory Machine.fromFirebase(Map<String, dynamic> data) {
    return Machine(
      id: data['id'] ?? '',
      nom: data['nom'] ?? '',
      emplacement: data['emplacement'] ?? '',
      statut: _parseStatus(data['statut']),
      tempsRestant: data['tempsRestant'],
      utilisateurActuel: data['utilisateurActuel'],
      heatLeft: data['heatLeft'],
      lastUpdate: data['lastUpdate'],
      dormPath: data['dormPath'],
    );
  }

  // FR : Convertit un texte Firebase en statut MachineStatus
  // RU : Преобразует текст из Firebase в статус MachineStatus
  static MachineStatus _parseStatus(String? status) {
    switch (status) {
      case 'libre':
        return MachineStatus.libre;
      case 'occupe':
        return MachineStatus.occupe;
      case 'termine':
        return MachineStatus.termine;
      default:
        return MachineStatus.libre;
    }
  }

  // FR : Convertit un statut MachineStatus en texte (stocké dans Firebase)
  // RU : Преобразует статус MachineStatus в текст (хранится в Firebase)
  static String _statusToString(MachineStatus status) {
    switch (status) {
      case MachineStatus.libre:
        return 'libre';
      case MachineStatus.occupe:
        return 'occupe';
      case MachineStatus.termine:
        return 'termine';
    }
  }

  // FR : Emoji correspondant au statut
  // RU : Эмодзи, соответствующий статусу
  String get emojiStatut {
    switch (statut) {
      case MachineStatus.libre:
        return '🟢';
      case MachineStatus.occupe:
        return '🔴';
      case MachineStatus.termine:
        return '🟠';
    }
  }

  // FR : Texte du statut (affiché dans l’UI) → traduit en russe
  // RU : Текст статуса (показывается в интерфейсе)
  String get texteStatut {
    switch (statut) {
      case MachineStatus.libre:
        return 'СВОБОДНА';
      case MachineStatus.occupe:
        return 'ЗАНЯТА';
      case MachineStatus.termine:
        return 'ЗАВЕРШЕНО';
    }
  }

  // FR : Formatage lisible de la dernière mise à jour
  // RU : Читаемый формат последнего обновления
  String get lastUpdateFormatted {
    if (lastUpdate == null) return 'Неизвестно';
    final date = lastUpdate!.toDate();
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}
