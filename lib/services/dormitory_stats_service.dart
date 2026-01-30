import 'package:cloud_firestore/cloud_firestore.dart';

class DormitoryStatsService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<Map<String, int>> getDormitoryStats({
    required String countryId,
    required String cityId,
    required String universityId,
    required String dormId,
  }) async {
    final dormRef = _firestore
        .collection('countries')
        .doc(countryId)
        .collection('cities')
        .doc(cityId)
        .collection('universities')
        .doc(universityId)
        .collection('dorms')
        .doc(dormId);

    final dormSnap = await dormRef.get();
    if (!dormSnap.exists) {
      throw Exception('Общежитие не найдено');
    }

    final machinesSnap = await dormRef.collection('machines').get();

    int active = 0;
    int inactive = 0;

    for (final machine in machinesSnap.docs) {
      final status = machine.data()['status'] ?? 'inactive';
      if (status == 'active') {
        active++;
      } else {
        inactive++;
      }
    }

    return {
      'machines': machinesSnap.size,
      'active': active,
      'inactive': inactive,
    };
  }
}
