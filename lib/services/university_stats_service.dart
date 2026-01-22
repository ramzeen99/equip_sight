import 'package:cloud_firestore/cloud_firestore.dart';

class UniversityStatsService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<Map<String, int>> getUniversityStats(
    String universityId,
    String countryId,
    String cityId,
  ) async {
    final uniRef = _firestore
        .collection('countries')
        .doc(countryId)
        .collection('cities')
        .doc(cityId)
        .collection('universities')
        .doc(universityId);

    final uniSnap = await uniRef.get();
    if (!uniSnap.exists) {
      throw Exception('Université introuvable');
    }

    final dormSnap = await uniRef.collection('dorms').get();
    final totalDorms = dormSnap.size;

    int activeMachines = 0;
    int inactiveMachines = 0;

    for (final dormDoc in dormSnap.docs) {
      final machinesSnap = await dormDoc.reference.collection('machines').get();

      for (final machine in machinesSnap.docs) {
        final status = machine.data()['status'] ?? 'inactive';
        if (status == 'active') {
          activeMachines++;
        } else {
          inactiveMachines++;
        }
      }
    }

    return {
      'dorms': totalDorms,
      'machines': activeMachines + inactiveMachines,
      'activeMachines': activeMachines,
      'inactiveMachines': inactiveMachines,
    };
  }
}
