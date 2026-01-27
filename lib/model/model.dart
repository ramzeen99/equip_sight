import 'package:cloud_firestore/cloud_firestore.dart';

enum MachineStatus { libre, occupe, termine }

class Machine {
  final String id;
  final String nom;
  final String emplacement;
  final MachineStatus statut;
  final int? heatLeft;
  final String? utilisateurActuel;
  final Timestamp? lastUpdate;
  final Timestamp? endTime;
  final Timestamp? startTime;
  final String? dormPath;

  Machine({
    required this.id,
    required this.nom,
    required this.emplacement,
    required this.statut,
    this.heatLeft,
    this.utilisateurActuel,
    this.lastUpdate,
    this.dormPath,
    this.endTime,
    this.startTime,
  });
  Machine copyWith({
    String? id,
    String? nom,
    String? emplacement,
    MachineStatus? statut,
    int? tempsRestant,
    String? utilisateurActuel,
    Timestamp? endTime,
    Timestamp? startTime,
  }) {
    return Machine(
      id: id ?? this.id,
      nom: nom ?? this.nom,
      emplacement: emplacement ?? this.emplacement,
      statut: statut ?? this.statut,
      utilisateurActuel: utilisateurActuel ?? this.utilisateurActuel,
      endTime: endTime ?? this.endTime,
      startTime: startTime ?? this.startTime,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nom': nom,
      'emplacement': emplacement,
      'statut': _statusToString(statut),
      'utilisateurActuel': utilisateurActuel,
      'heatLeft': heatLeft,
      'dormPath': dormPath,
      'endTime': endTime,
    };
  }

  factory Machine.fromFirebase(Map<String, dynamic> data) {
    return Machine(
      id: data['id'] ?? '',
      nom: data['nom'] ?? '',
      emplacement: data['emplacement'] ?? '',
      statut: _parseStatus(data['statut']),
      utilisateurActuel: data['utilisateurActuel'],
      heatLeft: data['heatLeft'],
      lastUpdate: data['lastUpdate'],
      dormPath: data['dormPath'],
      endTime: data['endTime'],
    );
  }

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

  String get lastUpdateFormatted {
    if (lastUpdate == null) return 'Неизвестно';
    final date = lastUpdate!.toDate();
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}
