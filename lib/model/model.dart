import 'package:cloud_firestore/cloud_firestore.dart';

enum MachineStatus { libre, reservee, occupe, termine }

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
  final Timestamp? reservationEndTime;
  final String? reservedBy;

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
    this.reservationEndTime,
    this.reservedBy,
  });

  Machine copyWith({
    MachineStatus? statut,
    String? utilisateurActuel,
    String? reservedBy,
    Timestamp? reservationEndTime,
    Timestamp? startTime,
    Timestamp? endTime,
  }) {
    return Machine(
      id: id,
      nom: nom,
      emplacement: emplacement,
      statut: statut ?? this.statut,
      utilisateurActuel: utilisateurActuel ?? this.utilisateurActuel,
      reservedBy: reservedBy ?? this.reservedBy,
      reservationEndTime: reservationEndTime ?? this.reservationEndTime,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
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
      case 'reservee':
        return MachineStatus.reservee;
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
      case MachineStatus.reservee:
        return 'reservee';
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
      case MachineStatus.reservee:
        return '🟡';
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
      case MachineStatus.reservee:
        return 'ЗАРЕЗЕРВИРОВАНА';
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
