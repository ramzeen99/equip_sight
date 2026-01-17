import 'package:cloud_firestore/cloud_firestore.dart';

class UniversityStatsService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<Map<String, int>> getUniversityStats(String universityId) async {
    final uniDoc = await _firestore
        .collection('universities')
        .doc(universityId)
        .get();

    if (!uniDoc.exists) {
      throw Exception('Université introuvable');
    }

    final data = uniDoc.data()!;

    final totalDorms = int.tryParse(data['totalDorms'].toString()) ?? 0;
    final activeMachines = int.tryParse(data['activeMachines'].toString()) ?? 0;
    final inactiveMachines =
        int.tryParse(data['inactiveMachines'].toString()) ?? 0;

    return {
      'dorms': totalDorms,
      'machines': activeMachines,
      'activeMachines': inactiveMachines,
      'inactiveMachines': inactiveMachines,
    };
  }
}
