import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equip_sight/model/model.dart';
import 'package:equip_sight/providers/notification_provider.dart';
import 'package:equip_sight/providers/preferences_provider.dart';
import 'package:flutter/foundation.dart';

import 'user_provider.dart';

class MachineProvider with ChangeNotifier {
  List<Machine> _machines = [];
  bool _isLoading = false;
  List<Machine> get machines => _machines;
  bool get isLoading => _isLoading;
  Timer? _timerChecker;
  MachineProvider() {
    _startTimerChecker();
  }

  Future<void> loadMachines(DocumentReference dormRef) async {
    _isLoading = true;
    notifyListeners();

    try {
      final snapshot = await dormRef.collection('machines').get();

      _machines = snapshot.docs.map((doc) {
        final data = doc.data();
        return Machine(
          id: doc.id,
          nom: data['name'] ?? '',
          emplacement: data['emplacement'] ?? '',
          statut: MachineStatus.values.byName(data['statut'] ?? 'libre'),
          utilisateurActuel: data['utilisateurActuel'],
          endTime: data['endTime'],
        );
      }).toList();
    } catch (e) {
      if (kDebugMode) print("Erreur loadMachines: $e");
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> demarrerMachine({
    required String machineId,
    required UserProvider userProvider,
    required NotificationProvider notificationProvider,
    required PreferencesProvider preferencesProvider,
    int totalMinutes = 40,
  }) async {
    try {
      final currentUser = userProvider.currentUser;
      final dormRef = userProvider.dormRef;
      if (currentUser == null || dormRef == null) return;

      final machineIndex = _machines.indexWhere((m) => m.id == machineId);
      if (machineIndex == -1) return;

      _machines[machineIndex] = _machines[machineIndex].copyWith(
        statut: MachineStatus.occupe,
        utilisateurActuel: currentUser.displayName ?? currentUser.email,
      );

      final endTime = Timestamp.fromDate(
        DateTime.now().add(Duration(minutes: totalMinutes)),
      );

      await dormRef.collection('machines').doc(machineId).update({
        'statut': 'occupe',
        'utilisateurActuel': currentUser.id,
        'endTime': endTime,
        'lastUpdated': FieldValue.serverTimestamp(),
      });

      notifyListeners();
    } catch (e) {
      if (kDebugMode) print("Erreur demarrerMachine: $e");
      rethrow;
    }
  }

  int? getRemainingTimeFromEndTime(Timestamp? endTime) {
    if (endTime == null) return null;

    final now = DateTime.now();
    final end = endTime.toDate();

    final diff = end.difference(now).inMinutes;
    return diff > 0 ? diff : 0;
  }

  Future<void> libererMachine({
    required String machineId,
    required UserProvider userProvider,
    required NotificationProvider notificationProvider,
  }) async {
    try {
      final dormRef = userProvider.dormRef;
      if (dormRef == null) return;

      final machineIndex = _machines.indexWhere((m) => m.id == machineId);
      if (machineIndex == -1) return;

      _machines[machineIndex] = _machines[machineIndex].copyWith(
        statut: MachineStatus.libre,
        utilisateurActuel: null,
      );

      await dormRef.collection('machines').doc(machineId).update({
        'statut': 'libre',
        'utilisateurActuel': null,
        'lastUpdated': FieldValue.serverTimestamp(),
      });

      notifyListeners();
    } catch (e) {
      if (kDebugMode) print("Erreur libererMachine: $e");
      rethrow;
    }
  }

  void _startTimerChecker() {
    _timerChecker?.cancel();
    _timerChecker = Timer.periodic(const Duration(seconds: 60), (_) {
      notifyListeners();
    });
  }

  @override
  void dispose() {
    _timerChecker?.cancel();
    super.dispose();
  }
}
