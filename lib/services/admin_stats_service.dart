import 'package:cloud_firestore/cloud_firestore.dart';

class AdminStatsService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<int> countCountries() async {
    final snap = await _firestore.collection('countries').get();
    return snap.size;
  }

  Future<int> countDorms() async {
    final snap = await _firestore.collection('dorms').get();
    return snap.size;
  }

  Future<int> countMachines() async {
    final snap = await _firestore.collection('machines').get();
    return snap.size;
  }

  Future<int> countUsers() async {
    final snap = await _firestore.collection('users').get();
    return snap.size;
  }

  Future<Map<String, int>> getGlobalStats() async {
    final results = await Future.wait([
      countCountries(),
      countDorms(),
      countMachines(),
      countUsers(),
    ]);

    return {
      'Страны': results[0],
      'Общежития': results[1],
      'Машины': results[2],
      'Пользователи': results[3],
    };
  }
}
