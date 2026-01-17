import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Classe représentant un utilisateur de l'application avec son dortoir et infos IoT
class AppUser {
  final String id;
  final String email;
  final String? displayName;
  final String? photoURL;
  final bool? emailVerified;

  // Infos de localisation hiérarchique Firestore
  final String? pays;
  final String? ville;
  final String? universite;
  final String? dortoir;

  // Exemple d’info supplémentaire (chauffage restant)
  final int? heatLeft;

  AppUser({
    required this.id,
    required this.email,
    this.displayName,
    this.photoURL,
    this.emailVerified,
    this.pays,
    this.ville,
    this.universite,
    this.dortoir,
    this.heatLeft,
  });

  /// Factory depuis Firebase Auth User
  factory AppUser.fromFirebaseUser(User user,
      {String? pays, String? ville, String? universite, String? dortoir, int? heatLeft}) {
    return AppUser(
      id: user.uid,
      email: user.email ?? '',
      displayName: user.displayName,
      photoURL: user.photoURL,
      emailVerified: user.emailVerified,
      pays: pays,
      ville: ville,
      universite: universite,
      dortoir: dortoir,
      heatLeft: heatLeft,
    );
  }

  /// Factory depuis Firestore document (nouvelle version complète)
  factory AppUser.fromMap(Map<String, dynamic> map, String uid, String? emailAuth) {
    return AppUser(
      id: uid,
      email: emailAuth ?? map['email'] ?? '',
      displayName: map['displayName'],
      photoURL: map['photoURL'],
      emailVerified: map['emailVerified'],
      pays: map['pays'],
      ville: map['ville'],
      universite: map['universite'],
      dortoir: map['dortoir'],
      heatLeft: map['heatLeft'] != null ? (map['heatLeft'] as num).toInt() : null,
    );
  }

  /// Convertir en Map pour stockage dans Firestore
  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'displayName': displayName,
      'photoURL': photoURL,
      'emailVerified': emailVerified,
      'pays': pays,
      'ville': ville,
      'universite': universite,
      'dortoir': dortoir,
      'heatLeft': heatLeft,
      'lastUpdated': FieldValue.serverTimestamp(),
    };
  }

  /// Copie d’un utilisateur avec mise à jour de champs
  AppUser copyWith({
    String? displayName,
    String? photoURL,
    String? pays,
    String? ville,
    String? universite,
    String? dortoir,
    int? heatLeft,
  }) {
    return AppUser(
      id: id,
      email: email,
      displayName: displayName ?? this.displayName,
      photoURL: photoURL ?? this.photoURL,
      emailVerified: emailVerified,
      pays: pays ?? this.pays,
      ville: ville ?? this.ville,
      universite: universite ?? this.universite,
      dortoir: dortoir ?? this.dortoir,
      heatLeft: heatLeft ?? this.heatLeft,
    );
  }

  /// Getter : afficher le nom si disponible sinon l’email
  String get displayNameOrEmail => displayName ?? email;

  /// Vérifie si l'utilisateur a une photo
  bool get hasPhoto => photoURL != null && photoURL!.isNotEmpty;

  /// Vérifie si toutes les infos du dortoir sont renseignées
  bool get hasDormInfo =>
      pays != null && ville != null && universite != null && dortoir != null;
  String? get dormPath {
    if (!hasDormInfo) return null;
    return "countries/$pays/cities/$ville/universities/$universite/dorms/$dortoir/machines";
  }
  /// Convertir un Firestore document en AppUser directement
  static AppUser fromFirestoreDoc(DocumentSnapshot doc, String? emailAuth) {
    return AppUser.fromMap(doc.data() as Map<String, dynamic>, doc.id, emailAuth);
  }
}



/*import 'package:firebase_auth/firebase_auth.dart';

// FR : Classe représentant un utilisateur de l'application
// RU : Класс, представляющий пользователя приложения
class AppUser {
  final String id;
  final String email;
  final String? displayName;
  final String? photoURL;
  final bool? emailVerified;

  AppUser({
    required this.id,
    required this.email,
    this.displayName,
    this.photoURL,
    this.emailVerified,
  });

  // 🏭 Factory depuis Firebase User
  // 🏭 Фабрика из Firebase User
  factory AppUser.fromFirebaseUser(User user) {
    return AppUser(
      id: user.uid,
      email: user.email ?? 'Электронная почта не определена', // FR : Email non défini // RU : Email non défini traduit en russe
      displayName: user.displayName,
      photoURL: user.photoURL,
      emailVerified: user.emailVerified,
    );
  }

  // 📝 Copie avec modifications
  // 📝 Копия с изменениями
  AppUser copyWith({String? displayName, String? photoURL}) {
    return AppUser(
      id: id,
      email: email,
      displayName: displayName ?? this.displayName,
      photoURL: photoURL ?? this.photoURL,
      emailVerified: emailVerified,
    );
  }

  // 🎯 Getter pour le nom d'affichage
  // 🎯 Геттер для отображаемого имени
  String get displayNameOrEmail => displayName ?? email;

  // 🎯 Getter pour vérifier si l'utilisateur a une photo (CORRIGÉ)
  // 🎯 Геттер для проверки, есть ли у пользователя фото (ИСПРАВЛЕНО)
  bool get hasPhoto => photoURL != null && photoURL!.isNotEmpty;
}
*/