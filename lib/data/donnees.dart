import 'package:equip_sight/model/model.dart';

class DonneesExemple {
  static List<Machine> get machines => [
    Machine(
      id: '1',
      nom: 'Машина 1',
      emplacement: 'Подвал / большие',
      statut: MachineStatus.libre,
      tempsRestant: 32,
      heatLeft: 5,
      utilisateurActuel: "",
    ),
    Machine(
      id: '2',
      nom: 'Машина 2',
      emplacement: 'Подвал / большие',
      statut: MachineStatus.termine,
      tempsRestant: 25,
      heatLeft: 4,
      utilisateurActuel: "etudiant2@dorm.com",
    ),
    Machine(
      id: '3',
      nom: 'Машина 3',
      emplacement: 'Подвал / большие',
      statut: MachineStatus.libre,
      tempsRestant: 0,
      heatLeft: 0,
      utilisateurActuel: "",
    ),
    Machine(
      id: '4',
      nom: 'Машина 4',
      emplacement: 'Подвал / большие',
      statut: MachineStatus.occupe,
      tempsRestant: 14,
      heatLeft: 2,
      utilisateurActuel: "",
    ),
    Machine(
      id: '5',
      nom: 'Машина 5',
      emplacement: 'Подвал / маленькие',
      statut: MachineStatus.libre,
      tempsRestant: 20,
      heatLeft: 3,
      utilisateurActuel: "",
    ),
    Machine(
      id: '6',
      nom: 'Машина 6',
      emplacement: 'Подвал / маленькие',
      statut: MachineStatus.occupe,
      tempsRestant: 8,
      heatLeft: 1,
      utilisateurActuel: "",
    ),
  ];
}
