import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equip_sight/data/donnees.dart';

import '../model/model.dart';

Future<void> migrateMachines() async {
  const String dormPath =
      "countries/idRussianCountries/cities/idMoscouCities/Universities/idMoscowPolitech/dorms/dorm_1";

  for (var machine in DonneesExemple.machines) {
    await FirebaseFirestore.instance
        .doc(dormPath)
        .collection("machines")
        .doc(machine.id)
        .set({
          "name": machine.nom,
          "status": machine.statut == MachineStatus.libre
              ? "available"
              : "occupied",
          "tempsRestant": machine.tempsRestant,
          "heatLeft": machine.heatLeft,
          "utilisateurActuel": machine.utilisateurActuel,
          "lastUpdate": FieldValue.serverTimestamp(),
        });
  }
}
