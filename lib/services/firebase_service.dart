import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equip_sight/data/donnees.dart';
import 'package:firebase_core/firebase_core.dart';

Future<void> syncMachinesToFirebase() async {
  final firestore = FirebaseFirestore.instance;

  for (var machine in DonneesExemple.machines) {
    await firestore.collection('machines').doc(machine.id).set({
      'id': machine.id,
      'nom': machine.nom,
      'emplacement': machine.emplacement,
      'statut': machine.statut.name,
    });
  }
}

class FirebaseService {
  static bool _isInitialized = false;

  /// Assure que Firebase est bien initialisé avant tout appel en background
  /// Гарантирует, что Firebase инициализирован до любого фонового вызова
  static Future<void> ensureInitialized() async {
    if (!_isInitialized) {
      await Firebase.initializeApp();
      _isInitialized = true;
    }
  }

  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Collection reference
  // Ссылка на коллекцию
  static CollectionReference get machinesCollection =>
      _firestore.collection('machines');

  // Récupérer toutes les machines (Stream pour mise à jour en temps réel)
  // Получить все машины (Stream для обновления в реальном времени)
  static Stream<QuerySnapshot> getMachinesStream() {
    return machinesCollection.snapshots();
  }

  // Mettre à jour une machine
  // Обновить информацию о машине
  static Future<void> updateMachine(
    String machineId,
    Map<String, dynamic> data,
  ) {
    return machinesCollection.doc(machineId).update({
      ...data,
      'lastUpdate': FieldValue.serverTimestamp(),
    });
  }

  // Créer une machine (pour l'initialisation)
  // Создать машину (для инициализации)
  static Future<void> createMachine(Map<String, dynamic> data) {
    return machinesCollection.doc(data['id']).set({
      ...data,
      'lastUpdate': FieldValue.serverTimestamp(),
    });
  }

  // Récupérer une machine spécifique
  // Получить конкретную машину
  static Future<DocumentSnapshot> getMachine(String machineId) {
    return machinesCollection.doc(machineId).get();
  }

  // Initialiser les données avec vos données existantes
  // Инициализировать данные вашими существующими данными
  static Future<void> initializeTestData() async {
    final snapshot = await machinesCollection.get();

    if (snapshot.docs.isEmpty) {
      // Utiliser vos données existantes de DonneesExemple
      // Использовать ваши существующие данные из DonneesExemple
      for (final machine in DonneesExemple.machines) {
        await machinesCollection.doc(machine.id).set(machine.toMap());
      }
      //print('✅ Данные инициализированы из donnees_exemple.dart');
    }
  }

  // Ajoutez cette méthode dans firebase_service.dart
  // Добавьте этот метод в firebase_service.dart
  static Future<void> diagnoseFirebase() async {
    try {
      //print('🔍 ДИАГНОСТИКА FIREBASE...');

      final snapshot = await machinesCollection.get();
      //print('📊 Количество документов в Firestore: ${snapshot.docs.length}');

      /*for (final doc in snapshot.docs) {
       // print('📄 Документ: ${doc.id}');
       // print('   Данные: ${doc.data()}');
      }*/

      if (snapshot.docs.isEmpty) {
        //print('❌ Нет данных в Firestore');
        await initializeTestData();
      } else {
        // print('✅ Данные присутствуют в Firestore');
      }
    } catch (e) {
      //print('❌ Ошибка диагностики: $e');
    }
  }
}
