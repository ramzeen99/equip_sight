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

  Timer? _ticker;

  void startTicker({
    required NotificationProvider notificationProvider,
    required PreferencesProvider preferencesProvider,
  }) {
    _ticker?.cancel();

    _ticker = Timer.periodic(const Duration(seconds: 30), (_) {
      _checkFinishedMachines(notificationProvider, preferencesProvider);
    });
  }

  void _checkFinishedMachines(
    NotificationProvider notificationProvider,
    PreferencesProvider preferencesProvider,
  ) {
    final now = DateTime.now();

    for (int i = 0; i < _machines.length; i++) {
      final m = _machines[i];

      if (m.statut == MachineStatus.occupe &&
          m.endTime != null &&
          m.endTime!.toDate().isBefore(now)) {
        // 🔔 Notification
        notificationProvider.addQuickNotification(
          title: '⏱️ Машина завершена',
          message: '${m.nom} завершил свой цикл',
          preferencesProvider: preferencesProvider,
        );
        _machines[i] = m.copyWith(statut: MachineStatus.termine);
      }
    }
    notifyListeners();
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
          startTime: data['startTime'],
          endTime: data['endTime'],
        );
      }).toList();
    } catch (e) {
      if (kDebugMode) print("Ошибка при загрузке машин: $e");
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

      final endTime = Timestamp.fromDate(
        DateTime.now().add(Duration(minutes: totalMinutes)),
      );

      final startTime = Timestamp.now();

      _machines[machineIndex] = _machines[machineIndex].copyWith(
        statut: MachineStatus.occupe,
        utilisateurActuel: currentUser.displayName,
        startTime: startTime,
        endTime: endTime,
      );

      notifyListeners();

      await dormRef.collection('machines').doc(machineId).update({
        'statut': 'occupe',
        'utilisateurActuel': currentUser.displayName,
        'startTime': FieldValue.serverTimestamp(),
        'endTime': endTime,
        'lastUpdated': FieldValue.serverTimestamp(),
      });

      notifyListeners();
    } catch (e) {
      if (kDebugMode) print("Ошибка при запуске машины: $e");
      rethrow;
    }
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
        startTime: null,
        endTime: null,
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
}
