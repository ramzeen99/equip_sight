import 'package:cloud_firestore/cloud_firestore.dart';

class UniversityStatsService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<Map<String, int>> getUniversityStats(
    String universityId,
    String countryId,
    String cityId,
  ) async {
    final _ = _firestore
        .collectionGroup('universities')
        .where(FieldPath.documentId, isEqualTo: universityId)
        .limit(1);

    final uniSnap = await _firestore
        .collection('universities')
        .doc(universityId)
        .get();
    if (!uniSnap.exists) {
      throw Exception('Université introuvable');
    }

    final dormSnap = await _firestore
        .collection('countries')
        .doc(countryId)
        .collection('cities')
        .doc(cityId)
        .collection('universities')
        .doc(universityId)
        .collection('dorms')
        .get();

    int totalDorms = dormSnap.size;

    int activeMachines = 0;
    int inactiveMachines = 0;

    for (var dormDoc in dormSnap.docs) {
      final machinesSnap = await dormDoc.reference.collection('machines').get();
      for (var machine in machinesSnap.docs) {
        if (machine.data()['status'] == 'active') {
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
