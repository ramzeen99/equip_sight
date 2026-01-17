import 'package:cloud_firestore/cloud_firestore.dart';

class DormitoryStatsService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<Map<String, int>> getDormitoryStats(String dormId) async {
    final machinesSnap = await _firestore
        .collection('machines')
        .where('dormId', isEqualTo: dormId)
        .get();

    final active = machinesSnap.docs
        .where((m) => m['status'] == 'active')
        .length;

    final inactive = machinesSnap.docs
        .where((m) => m['status'] != 'active')
        .length;

    return {
      'machines': machinesSnap.size,
      'active': active,
      'inactive': inactive,
    };
  }
}
