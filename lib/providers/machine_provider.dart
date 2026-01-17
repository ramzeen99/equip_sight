import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:laundry_lens/model/model.dart';
import 'package:laundry_lens/providers/notification_provider.dart';
import 'package:laundry_lens/providers/preferences_provider.dart';

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

/*import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:laundry_lens/constants.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:laundry_lens/model/model.dart';
import 'package:laundry_lens/services/firebase_service.dart';
import 'package:laundry_lens/model/notification_model.dart';
import 'package:laundry_lens/providers/notification_provider.dart';
import 'package:laundry_lens/services/reminder_service.dart';
import 'package:laundry_lens/providers/preferences_provider.dart';
import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';

import '../services/background_notification_service.dart';

void scheduleMachineEndTimer(int machineDurationInSeconds) {
  AndroidAlarmManager.oneShot(
    Duration(seconds: machineDurationInSeconds),
    12345,
    timerFinishedCallback,
    wakeup: true,
    exact: true,
  );
}

class MachineTimer {
  final String machineId;
  final int totalMinutes;
  final DateTime startTime;
  bool isActive;
  final String? startedByUser;

  MachineTimer({
    required this.machineId,
    required this.totalMinutes,
    required this.startTime,
    required this.isActive,
    this.startedByUser,
  });

  int get remainingMinutes {
    if (!isActive) return 0;
    final now = DateTime.now();
    final elapsed = now.difference(startTime).inMinutes;
    final remaining = totalMinutes - elapsed;
    return remaining > 0 ? remaining : 0;
  }

  bool get isFinished => remainingMinutes <= 0;

  Map<String, dynamic> toMap() {
    return {
      'machineId': machineId,
      'totalMinutes': totalMinutes,
      'startTime': startTime.millisecondsSinceEpoch,
      'isActive': isActive,
      'startedByUser': startedByUser,
    };
  }

  static MachineTimer fromMap(Map<String, dynamic> map) {
    return MachineTimer(
      machineId: map['machineId'],
      totalMinutes: map['totalMinutes'],
      startTime: DateTime.fromMillisecondsSinceEpoch(map['startTime']),
      isActive: map['isActive'],
      startedByUser: map['startedByUser'],
    );
  }
}

class MachineProvider with ChangeNotifier {
  List<Machine> _machines = [];
  List<MachineTimer> _activeTimers = [];
  bool _isLoading = true;
  String? _error;
  Timer? _timerChecker;
  StreamSubscription<QuerySnapshot>? _machinesSubscription;

  List<Machine> get machines => _machines;
  bool get isLoading => _isLoading;
  String? get error => _error;
  List<MachineTimer> get activeTimers => _activeTimers;

  MachineProvider() {
    _initialize();
  }

  Future<void> _initialize() async {
    await _loadTimersFromStorage();
    await loadMachines();
    _startTimerChecker();
  }

  Future<void> _saveTimersToStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final timersJson = _activeTimers.map((timer) => timer.toMap()).toList();
      await prefs.setString('active_machine_timers', json.encode(timersJson));
    } catch (_) {}
  }

  Future<void> _loadTimersFromStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final timersJson = prefs.getString('active_machine_timers');
      if (timersJson != null) {
        final List<dynamic> timersList = json.decode(timersJson);
        _activeTimers = timersList.map((timerMap) {
          return MachineTimer.fromMap(timerMap);
        }).toList();
        _activeTimers.removeWhere((timer) => timer.isFinished);
      }
    } catch (_) {}
  }

  Future<void> loadMachines() async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      await FirebaseService.initializeTestData();

      _machinesSubscription = FirebaseService.getMachinesStream().listen(
            (QuerySnapshot snapshot) {
          _machines = snapshot.docs.map((doc) {
            return Machine.fromFirebase(doc.data() as Map<String, dynamic>);
          }).toList();

          _machines.sort((a, b) => a.id.compareTo(b.id));

          // Synchroniser les timers locaux avec Firebase
          //_syncTimersWithMachines();

          _isLoading = false;
          notifyListeners();
        },
        onError: (error) {
          _error = 'Ошибка загрузки: $error / Loading error: $error';
          _isLoading = false;
          notifyListeners();
        },
      );
    } catch (e) {
      _error = 'Ошибка: $e / Error: $e';
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> demarrerMachine({
    required String machineId,
    required String utilisateur,
    required NotificationProvider notificationProvider,
    required PreferencesProvider preferencesProvider,
  }) async {
    try {
      final oldMachine = _machines.firstWhere((m) => m.id == machineId);

      final newTimer = MachineTimer(
        machineId: machineId,
        totalMinutes: totalTimeMinutes,
        startTime: DateTime.now(),
        isActive: true,
        startedByUser: utilisateur,
      );

      _activeTimers.removeWhere((timer) => timer.machineId == machineId);
      _activeTimers.add(newTimer);
      await _saveTimersToStorage();

      final prefs = await SharedPreferences.getInstance();
      const String alarmsKey = 'scheduled_machine_alarms';
      List<dynamic> scheduled = [];
      final raw = prefs.getString(alarmsKey);
      if (raw != null && raw.isNotEmpty) {
        try {
          scheduled = json.decode(raw) as List<dynamic>;
        } catch (_) {
          scheduled = [];
        }
      }

      final scheduledAt = DateTime.now()
          .add(Duration(minutes: newTimer.totalMinutes))
          .millisecondsSinceEpoch;

      scheduled.add({
        'machineId': machineId,
        'machineName': oldMachine.nom,
        'location': oldMachine.emplacement,
        'scheduledAt': scheduledAt,
      });
      await prefs.setString(alarmsKey, json.encode(scheduled));

      await AndroidAlarmManager.oneShot(
        Duration(minutes: newTimer.totalMinutes),
        machineId.hashCode,
        timerFinishedCallback,
        exact: true,
        wakeup: true,
      );

      final updatedMachine = Machine(
        id: oldMachine.id,
        nom: oldMachine.nom,
        emplacement: oldMachine.emplacement,
        statut: MachineStatus.occupe,
        tempsRestant: newTimer.remainingMinutes,
        utilisateurActuel: utilisateur,
      );

      _updateMachineLocally(updatedMachine);

      ReminderService.scheduleReminder(
        machine: updatedMachine,
        notificationProvider: notificationProvider,
        preferencesProvider: preferencesProvider,
      );

      _checkForNotifications(oldMachine, updatedMachine, notificationProvider);

      await FirebaseService.updateMachine(machineId, updatedMachine.toMap());

      notifyListeners();
    } catch (e) {
      _error = 'Ошибка запуска: $e / Startup error: $e';
      notifyListeners();
      rethrow;
    }
  }

  Future<void> libererMachine({
    required String machineId,
    required NotificationProvider notificationProvider,
  }) async {
    try {
      final oldMachine = _machines.firstWhere((m) => m.id == machineId);

      _activeTimers.removeWhere((timer) => timer.machineId == machineId);
      await _saveTimersToStorage();

      final updatedMachine = Machine(
        id: oldMachine.id,
        nom: oldMachine.nom,
        emplacement: oldMachine.emplacement,
        statut: MachineStatus.libre,
        tempsRestant: null,
        utilisateurActuel: null,
      );

      _updateMachineLocally(updatedMachine);
      _checkForNotifications(oldMachine, updatedMachine, notificationProvider);
      ReminderService.cancelReminder(machineId);

      await FirebaseService.updateMachine(machineId, updatedMachine.toMap());

      notifyListeners();
    } catch (e) {
      _error = 'Ошибка освобождения: $e / Release error: $e';
      notifyListeners();
      rethrow;
    }
  }

  void _startTimerChecker() {
    _timerChecker = Timer.periodic(Duration(seconds: 10), (timer) {
      //bool shouldNotify = false;
      bool shouldSave = false;

      for (int i = 0; i < _activeTimers.length; i++) {

        final machineTimer = _activeTimers[i];
        if (machineTimer.isFinished && machineTimer.isActive) {
          NotificationProvider.instance.addQuickNotification(
            title: "Машина завершила работу / Machine finished",
            message: "Ваше белье готово 🎉 / Your laundry is ready 🎉",
            type: NotificationType.machineFinished,
            context: null,
            preferencesProvider: null,
            showAsPush: true,
          );

          _activeTimers[i] = MachineTimer(
            machineId: machineTimer.machineId,
            totalMinutes: machineTimer.totalMinutes,
            startTime: machineTimer.startTime,
            isActive: false,
            startedByUser: machineTimer.startedByUser,
          );

          _sendTimerFinishedNotification(machineTimer.machineId);
          //shouldNotify = true;
          shouldSave = true;
        }
      }

      //if (shouldNotify) _syncTimersWithMachines();
      if (shouldSave) _saveTimersToStorage();
    });
  }

  void _sendTimerFinishedNotification(String machineId) {
    final machineIndex = _machines.indexWhere((m) => m.id == machineId);
    if (machineIndex != -1) {
      final machine = _machines[machineIndex];
      final updatedMachine = Machine(
        id: machine.id,
        nom: machine.nom,
        emplacement: machine.emplacement,
        statut: MachineStatus.termine,
        tempsRestant: 0,
        utilisateurActuel: machine.utilisateurActuel,
      );
      _updateMachineLocally(updatedMachine);
      FirebaseService.updateMachine(machineId, updatedMachine.toMap());
    }
  }

  void _updateMachineLocally(Machine updatedMachine) {
    final index = _machines.indexWhere((m) => m.id == updatedMachine.id);
    if (index != -1) _machines[index] = updatedMachine;
  }

  void _checkForNotifications(
      Machine oldMachine,
      Machine newMachine,
      NotificationProvider notificationProvider,
      ) {
    if (oldMachine.statut != MachineStatus.termine &&
        newMachine.statut == MachineStatus.termine) {
      _sendMachineFinishedNotification(newMachine, notificationProvider);
    }
    if (oldMachine.statut != MachineStatus.libre &&
        newMachine.statut == MachineStatus.libre) {
      _sendMachineAvailableNotification(newMachine, notificationProvider);
    }
    if (oldMachine.statut != MachineStatus.occupe &&
        newMachine.statut == MachineStatus.occupe) {
      _sendMachineStartedNotification(newMachine, notificationProvider);
    }
  }

  void _sendMachineFinishedNotification(
      Machine machine, NotificationProvider notificationProvider) {
    final notification = AppNotification(
      id: '${machine.id}_finished_${DateTime.now().millisecondsSinceEpoch}',
      title: '🎉 Машина готова! / Machine ready!',
      message:
      'Ваша ${machine.nom} (${machine.emplacement}) завершила работу / Your ${machine.nom} is finished',
      timestamp: DateTime.now(),
      type: NotificationType.machineFinished,
      machineId: machine.id,
      userId: machine.utilisateurActuel,
    );
    notificationProvider.addNotification(notification, context: null);
  }

  void _sendMachineAvailableNotification(
      Machine machine, NotificationProvider notificationProvider) {
    final notification = AppNotification(
      id: '${machine.id}_available_${DateTime.now().millisecondsSinceEpoch}',
      title: '✅ Машина доступна / Machine available',
      message:
      '${machine.nom} (${machine.emplacement}) теперь свободна / is now free',
      timestamp: DateTime.now(),
      type: NotificationType.machineAvailable,
      machineId: machine.id,
    );
    notificationProvider.addNotification(notification, context: null);
  }

  void _sendMachineStartedNotification(
      Machine machine, NotificationProvider notificationProvider) {
    final notification = AppNotification(
      id: '${machine.id}_started_${DateTime.now().millisecondsSinceEpoch}',
      title: '🏁 Машина запущена / Machine started',
      message:
      '${machine.nom} (${machine.emplacement}) была запущена / has been started',
      timestamp: DateTime.now(),
      type: NotificationType.system,
      machineId: machine.id,
      userId: machine.utilisateurActuel,
    );
    notificationProvider.addNotification(notification, context: null);
  }

  int? getRemainingTime(String machineId) {
    try {
      final timer =
      _activeTimers.firstWhere((t) => t.machineId == machineId && t.isActive);
      return timer.remainingMinutes;
    } catch (_) {
      return null;
    }
  }

  bool hasActiveTimer(String machineId) {
    return _activeTimers
        .any((t) => t.machineId == machineId && t.isActive && !t.isFinished);
  }

  Machine? getMachineById(String machineId) {
    try {
      return _machines.firstWhere((m) => m.id == machineId);
    } catch (_) {
      return null;
    }
  }

  @override
  void dispose() {
    _machinesSubscription?.cancel();
    _timerChecker?.cancel();
    ReminderService.cancelAllReminders();
    super.dispose();
  }
}
*/
