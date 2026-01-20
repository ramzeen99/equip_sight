import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equip_sight/model/user_model.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class UserProvider with ChangeNotifier {
  AppUser? _currentUser;
  bool _isLoading = true;
  String? _error;

  AppUser? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isLoggedIn => _currentUser != null;

  String? get role => _currentUser?.role;

  String? get universityId => _currentUser?.universityId;

  String? get dormId => _currentUser?.dormId;

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  UserProvider() {
    _initializeAuthListener();
  }

  /// Écoute les changements d'état d'authentification
  void _initializeAuthListener() {
    _auth.authStateChanges().listen(
      (User? user) async {
        _isLoading = true;
        notifyListeners();

        if (user != null) {
          await _loadUserFromFirestore(user);
        } else {
          _currentUser = null;
        }

        _isLoading = false;
        notifyListeners();
      },
      onError: (e) {
        _error = e.toString();
        _isLoading = false;
        notifyListeners();
      },
    );
  }

  /// Charge les données utilisateur depuis Firestore
  Future<void> _loadUserFromFirestore(User user) async {
    try {
      final userDoc = await _firestore.collection('users').doc(user.uid).get();

      if (userDoc.exists) {
        _currentUser = AppUser.fromMap(
          userDoc.data() as Map<String, dynamic>,
          user.uid,
          user.email,
        );
      } else {
        _currentUser = AppUser.fromFirebaseUser(user);
        await _firestore
            .collection('users')
            .doc(user.uid)
            .set(_currentUser!.toMap());
      }
    } catch (e) {
      _error = "Erreur chargement Firestore user: $e";
      _currentUser = AppUser.fromFirebaseUser(user);
    }
    notifyListeners();
  }

  /// Attendre la fin de l'initialisation
  Future<void> waitForInitialization() async {
    if (!_isLoading) return;
    await Future.doWhile(() async {
      await Future.delayed(const Duration(milliseconds: 100));
      return _isLoading;
    });
  }

  /// Mise à jour du profil (nom et photo)
  Future<void> updateProfile({String? displayName, String? photoURL}) async {
    try {
      if (_auth.currentUser == null) return;

      if (displayName != null) {
        await _auth.currentUser!.updateDisplayName(displayName);
      }
      if (photoURL != null) await _auth.currentUser!.updatePhotoURL(photoURL);

      await _auth.currentUser!.reload();
      final refreshedUser = _auth.currentUser;

      if (refreshedUser != null) {
        _currentUser = _currentUser?.copyWith(
          displayName: refreshedUser.displayName,
          photoURL: refreshedUser.photoURL,
        );

        await _firestore.collection('users').doc(refreshedUser.uid).update({
          if (displayName != null) 'displayName': displayName,
          if (photoURL != null) 'photoURL': photoURL,
          'lastUpdated': FieldValue.serverTimestamp(),
        });
      }

      notifyListeners();
    } catch (e) {
      _error = "Erreur update profile: $e";
      notifyListeners();
      rethrow;
    }
  }

  /// Mise à jour des infos de dortoir/localisation
  Future<void> updateDormInfo({
    required String pays,
    required String ville,
    required String universite,
    required String dortoir,
    int? heatLeft,
  }) async {
    try {
      if (_auth.currentUser == null) return;

      _currentUser = _currentUser?.copyWith(
        pays: pays,
        ville: ville,
        universite: universite,
        dortoir: dortoir,
        heatLeft: heatLeft,
      );

      await _firestore.collection('users').doc(_currentUser!.id).update({
        'pays': pays,
        'ville': ville,
        'universite': universite,
        'dortoir': dortoir,
        if (heatLeft != null) 'heatLeft': heatLeft,
        'lastUpdated': FieldValue.serverTimestamp(),
      });

      notifyListeners();
    } catch (e) {
      _error = "Erreur update dorm info: $e";
      notifyListeners();
      rethrow;
    }
  }

  /// Déconnexion
  Future<void> signOut() async {
    try {
      // 1️⃣ Déconnexion Firebase
      await _auth.signOut();

      // 2️⃣ Réinitialisation du provider
      _currentUser = null;

      // 3️⃣ Forcer un refresh pour éviter que authStateChanges reload l'ancien utilisateur
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = "Erreur signOut: $e";
      notifyListeners();
      rethrow;
    }
  }

  /// Définir l'utilisateur actuel manuellement
  void setCurrentUser(AppUser user) {
    _currentUser = user;
    notifyListeners();
  }

  /// Retourne le chemin Firestore du dortoir de l'utilisateur
  String? get dormPath {
    if (_currentUser == null || !_currentUser!.hasDormInfo) return null;
    return "countries/${_currentUser!.pays}/cities/${_currentUser!.ville}/Universities/${_currentUser!.universite}/dorms/${_currentUser!.dortoir}/machines";
  }
}
