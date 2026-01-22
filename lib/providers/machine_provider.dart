import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equip_sight/model/model.dart';
import 'package:equip_sight/providers/notification_provider.dart';
import 'package:equip_sight/providers/preferences_provider.dart';
import 'package:flutter/foundation.dart';

import 'user_provider.dart';

class MachineProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<Machine> _machines = [];
  final Map<String, MachineTimer> _activeTimers =
      {}; // clé = dormPath/machineId
  bool _isLoading = false;

  List<Machine> get machines => _machines;
  bool get isLoading => _isLoading;

  Timer? _timerChecker;

  MachineProvider() {
    _startTimerChecker();
  }

  /// Chargement des machines depuis Firestore
  Future<void> loadMachines(String dormPath) async {
    _isLoading = true;
    notifyListeners();

    try {
      final snapshot = await _firestore
          .collection('dorms')
          .doc(dormPath)
          .collection('machines')
          .get();

      _machines = snapshot.docs.map((doc) {
        final data = doc.data();
        return Machine(
          id: doc.id,
          nom: data['nom'] ?? '',
          emplacement: data['emplacement'] ?? '',
          statut: MachineStatus.values.byName(data['statut'] ?? 'libre'),
          tempsRestant: data['tempsRestant'],
          utilisateurActuel: data['utilisateurActuel'],
        );
      }).toList();
    } catch (e) {
      if (kDebugMode) print("Erreur loadMachines: $e");
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Démarrer une machine
  Future<void> demarrerMachine({
    required String machineId,
    required UserProvider userProvider,
    required NotificationProvider notificationProvider,
    required PreferencesProvider preferencesProvider,
    int totalMinutes = 40,
    String? dormPath,
  }) async {
    try {
      final currentUser = userProvider.currentUser;
      if (currentUser == null || currentUser.dormPath == null) return;
      final dormPath = currentUser.dormPath!;

      final machineIndex = _machines.indexWhere((m) => m.id == machineId);
      if (machineIndex == -1) return;

      final timerKey = "$dormPath/$machineId";

      // Créer et stocker le timer
      _activeTimers[timerKey] = MachineTimer(
        machineId: machineId,
        dormPath: dormPath,
        totalMinutes: totalMinutes,
        remainingMinutes: totalMinutes,
        isActive: true,
      );

      // Mettre à jour la machine localement
      _machines[machineIndex] = _machines[machineIndex].copyWith(
        statut: MachineStatus.occupe,
        utilisateurActuel: currentUser.id,
        tempsRestant: totalMinutes,
      );

      // Mettre à jour Firestore
      await _firestore
          .collection('dorms')
          .doc(dormPath)
          .collection('machines')
          .doc(machineId)
          .update({
            'statut': 'occupe',
            'utilisateurActuel': currentUser.id,
            'tempsRestant': totalMinutes,
            'lastUpdated': FieldValue.serverTimestamp(),
          });

      notifyListeners();
    } catch (e) {
      if (kDebugMode) print("Erreur demarrerMachine: $e");
      rethrow;
    }
  }

  /// Libérer une machine
  Future<void> libererMachine({
    required String machineId,
    required UserProvider userProvider,
    required NotificationProvider notificationProvider,
  }) async {
    try {
      final currentUser = userProvider.currentUser;
      if (currentUser == null || currentUser.dormPath == null) return;
      final dormPath = currentUser.dormPath!;
      final machineIndex = _machines.indexWhere((m) => m.id == machineId);
      if (machineIndex == -1) return;

      final timerKey = "$dormPath/$machineId";

      _activeTimers.remove(timerKey);

      _machines[machineIndex] = _machines[machineIndex].copyWith(
        statut: MachineStatus.libre,
        utilisateurActuel: null,
        tempsRestant: null,
      );

      await _firestore
          .collection('dorms')
          .doc(dormPath)
          .collection('machines')
          .doc(machineId)
          .update({
            'statut': 'libre',
            'utilisateurActuel': null,
            'tempsRestant': null,
            'lastUpdated': FieldValue.serverTimestamp(),
          });

      notifyListeners();
    } catch (e) {
      if (kDebugMode) print("Erreur libererMachine: $e");
      rethrow;
    }
  }

  /// Vérifie si une machine a un timer actif
  bool hasActiveTimer({required String machineId, required String dormPath}) {
    final key = "$dormPath/$machineId";
    final timer = _activeTimers[key];
    return timer != null && timer.isActive && !timer.isFinished;
  }

  /// Retourne le temps restant pour une machine
  int? getRemainingTime({required String machineId, required String dormPath}) {
    final key = "$dormPath/$machineId";
    final timer = _activeTimers[key];
    return timer?.remainingMinutes;
  }

  // Getter public pour obtenir la liste des timers actifs
  List<MachineTimer> get activeTimers => _activeTimers.values.toList();

  /// Timer périodique pour mettre à jour les machines et notifications
  void _startTimerChecker() {
    _timerChecker?.cancel();
    _timerChecker = Timer.periodic(const Duration(seconds: 60), (timer) async {
      for (var entry in _activeTimers.entries) {
        final t = entry.value;
        if (!t.isActive) continue;

        t.remainingMinutes -= 1;
        if (t.remainingMinutes <= 0) {
          t.remainingMinutes = 0;
          t.isActive = false;
          t.isFinished = true;

          // Envoyer notification via NotificationProvider
          await NotificationProvider.instance.addQuickNotification(
            title: "Cycle terminé",
            message: "La machine \"${t.machineId}\" a terminé son cycle 🎉",
            //type: NotificationType.machineFinished,
            preferencesProvider: null, // ajouter si tu as PreferencesProvider
          );

          // Mettre à jour Firestore
          await _firestore
              .collection('dorms')
              .doc(t.dormPath)
              .collection('machines')
              .doc(t.machineId)
              .update({
                'statut': 'libre',
                'utilisateurActuel': null,
                'tempsRestant': null,
                'lastUpdated': FieldValue.serverTimestamp(),
              });

          // Mettre à jour la machine localement
          final machineIndex = _machines.indexWhere((m) => m.id == t.machineId);
          if (machineIndex != -1) {
            _machines[machineIndex] = _machines[machineIndex].copyWith(
              statut: MachineStatus.libre,
              utilisateurActuel: null,
              tempsRestant: null,
            );
          }
        }
      }
      notifyListeners();
    });
  }

  @override
  void dispose() {
    _timerChecker?.cancel();
    super.dispose();
  }
}

/// Classe interne pour gérer le timer d'une machine
class MachineTimer {
  final String machineId;
  final String dormPath;
  int totalMinutes;
  int remainingMinutes;
  bool isActive;
  bool isFinished;

  MachineTimer({
    required this.machineId,
    required this.dormPath,
    required this.totalMinutes,
    required this.remainingMinutes,
    this.isActive = false,
    this.isFinished = false,
  });
}
