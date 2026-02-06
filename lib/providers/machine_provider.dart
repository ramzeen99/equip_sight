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

  StreamSubscription? _machinesSub;

  void listenToMachines(DocumentReference dormRef) {
    _isLoading = true;
    notifyListeners();

    _machinesSub?.cancel();

    _machinesSub = dormRef.collection('machines').snapshots().listen((
      snapshot,
    ) {
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
          reservedByName: data['reservedByName'],
          reservationEndTime: data['reservationEndTime'],
        );
      }).toList();

      _isLoading = false;
      notifyListeners();
    });
  }

  Future<void> reserverMachine({
    required String machineId,
    required UserProvider userProvider,
  }) async {
    final user = userProvider.currentUser;
    final dormRef = userProvider.dormRef;
    if (user == null || dormRef == null) return;

    final reservationEnd = Timestamp.fromDate(
      DateTime.now().add(const Duration(minutes: 5)),
    );

    await dormRef.collection('machines').doc(machineId).update({
      'statut': 'reservee',
      'reservedByUid': user.id,
      'reservedByName': user.displayName,
      'reservationStart': FieldValue.serverTimestamp(),
      'reservationEndTime': reservationEnd,
    });
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
          reservedByName: data['reservedByName'],
          reservationEndTime: data['reservationEndTime'],
        );
      }).toList();
    } catch (e) {
      if (kDebugMode) {
        print('Erreur loadMachines: $e');
      }
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

      final machine = _machines[machineIndex];

      if (machine.statut == MachineStatus.reservee &&
          machine.reservedByName != currentUser.displayName) {
        throw Exception('Вы не можете запустить эту машину');
      }

      _machines[machineIndex] = machine.copyWith(
        statut: MachineStatus.occupe,
        utilisateurActuel: currentUser.displayName,
        startTime: startTime,
        endTime: endTime,
        reservedByName: null,
        reservationEndTime: null,
      );

      notifyListeners();

      await dormRef.collection('machines').doc(machineId).update({
        'statut': 'occupe',
        'utilisateurActuel': currentUser.displayName,
        'utilisateurActuelUid': currentUser.id,
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
        reservedByName: null,
        reservationEndTime: null,
      );

      await dormRef.collection('machines').doc(machineId).update({
        'statut': 'libre',
        'utilisateurActuel': null,
        'reservedByName': null,
        'reservationEndTime': null,
        'lastUpdated': FieldValue.serverTimestamp(),
      });

      notifyListeners();
    } catch (e) {
      if (kDebugMode) print("Erreur libererMachine: $e");
      rethrow;
    }
  }
}
