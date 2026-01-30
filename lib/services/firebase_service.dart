import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equip_sight/data/donnees.dart';
import 'package:firebase_core/firebase_core.dart';

Future<void> syncMachinesToFirebase() async {
  final firestore = FirebaseFirestore.instance;

  for (var machine in DonneesExemple.machines) {
    await firestore.collection('machines').doc(machine.id).set({
      'id': machine.id,
      'nom': machine.nom,
      'emplacement': machine.emplacement,
      'statut': machine.statut.name,
    });
  }
}

class FirebaseService {
  static bool _isInitialized = false;
  static Future<void> ensureInitialized() async {
    if (!_isInitialized) {
      await Firebase.initializeApp();
      _isInitialized = true;
    }
  }

  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static CollectionReference get machinesCollection =>
      _firestore.collection('machines');
  static Stream<QuerySnapshot> getMachinesStream() {
    return machinesCollection.snapshots();
  }

  static Future<void> updateMachine(
    String machineId,
    Map<String, dynamic> data,
  ) {
    return machinesCollection.doc(machineId).update({
      ...data,
      'lastUpdate': FieldValue.serverTimestamp(),
    });
  }

  static Future<void> createMachine(Map<String, dynamic> data) {
    return machinesCollection.doc(data['id']).set({
      ...data,
      'lastUpdate': FieldValue.serverTimestamp(),
    });
  }

  static Future<DocumentSnapshot> getMachine(String machineId) {
    return machinesCollection.doc(machineId).get();
  }

  static Future<void> initializeTestData() async {
    final snapshot = await machinesCollection.get();

    if (snapshot.docs.isEmpty) {
      for (final machine in DonneesExemple.machines) {
        await machinesCollection.doc(machine.id).set(machine.toMap());
      }
    }
  }

  static Future<void> diagnoseFirebase() async {
    try {
      final snapshot = await machinesCollection.get();

      if (snapshot.docs.isEmpty) {
        await initializeTestData();
      }
    } catch (e) {
      //print('❌ Ошибка диагностики: $e');
    }
  }
}
