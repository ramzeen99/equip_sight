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

  // 🔹 Champs normalisés
  String? get role => _currentUser?.role;
  String? get countryId => _currentUser?.countryId;
  String? get cityId => _currentUser?.cityId;
  String? get universityId => _currentUser?.universityId;
  String? get dormId => _currentUser?.dormId;

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  UserProvider() {
    _initializeAuthListener();
  }

  // 🔹 Écoute authentification
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

  // 🔹 Chargement Firestore
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

  // 🔹 Attente explicite (utile au démarrage)
  Future<void> waitForInitialization() async {
    if (!_isLoading) return;
    await Future.doWhile(() async {
      await Future.delayed(const Duration(milliseconds: 100));
      return _isLoading;
    });
  }

  // 🔹 Mise à jour profil
  Future<void> updateProfile({String? displayName, String? photoURL}) async {
    try {
      if (_auth.currentUser == null) return;

      if (displayName != null) {
        await _auth.currentUser!.updateDisplayName(displayName);
      }
      if (photoURL != null) {
        await _auth.currentUser!.updatePhotoURL(photoURL);
      }

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

  // 🔹 Mise à jour rattachement (DORTOIR / UNIVERSITÉ)
  Future<void> updateDormInfo({
    required String countryId,
    required String cityId,
    required String universityId,
    required String dormId,
    int? heatLeft,
  }) async {
    try {
      if (_auth.currentUser == null) return;

      _currentUser = _currentUser?.copyWith(
        countryId: countryId,
        cityId: cityId,
        universityId: universityId,
        dormId: dormId,
        heatLeft: heatLeft,
      );

      await _firestore.collection('users').doc(_currentUser!.id).update({
        'countryId': countryId,
        'cityId': cityId,
        'universityId': universityId,
        'dormId': dormId,
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

  // 🔹 Déconnexion
  Future<void> signOut() async {
    try {
      await _auth.signOut();
      _currentUser = null;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = "Erreur signOut: $e";
      notifyListeners();
      rethrow;
    }
  }

  // 🔹 Injection manuelle (tests / admin)
  void setCurrentUser(AppUser user) {
    _currentUser = user;
    notifyListeners();
  }

  // 🔹 Chemin machines dortoir (FIABLE)
  String? get dormPath {
    if (_currentUser == null ||
        countryId == null ||
        cityId == null ||
        universityId == null ||
        dormId == null) {
      return null;
    }

    return "countries/$countryId"
        "/cities/$cityId"
        "/universities/$universityId"
        "/dorms/$dormId"
        "/machines";
  }
}
