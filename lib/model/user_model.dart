import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AppUser {
  final String id;
  final String email;
  final String? displayName;
  final String? photoURL;
  final bool? emailVerified;

  final String? pays;
  final String? ville;
  final String? universite;
  final String? dortoir;

  final int? heatLeft;

  /// 🔐 Sécurité & navigation
  final String role;
  final String? universityId;
  final String? dormId;

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
    required this.role,
    this.universityId,
    this.dormId,
  });

  // =========================
  // Factory depuis Firebase Auth
  // =========================
  factory AppUser.fromFirebaseUser(
      User user, {
        String role = 'user',
        String? pays,
        String? ville,
        String? universite,
        String? dortoir,
        int? heatLeft,
        String? universityId,
        String? dormId,
      }) {
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
      role: role,
      universityId: universityId,
      dormId: dormId,
    );
  }

  // =========================
  // Factory depuis Firestore
  // =========================
  factory AppUser.fromMap(
      Map<String, dynamic> map,
      String uid,
      String? emailAuth,
      ) {
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
      heatLeft: map['heatLeft'] != null
          ? (map['heatLeft'] as num).toInt()
          : null,
      role: map['role'] ?? 'user', // 🔥 fallback critique
      universityId: map['universityId'],
      dormId: map['dormId'],
    );
  }

  // =========================
  // Firestore → Map
  // =========================
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
      'role': role,
      'universityId': universityId,
      'dormId': dormId,
      'lastUpdated': FieldValue.serverTimestamp(),
    };
  }

  // =========================
  // CopyWith sécurisé
  // =========================
  AppUser copyWith({
    String? displayName,
    String? photoURL,
    String? pays,
    String? ville,
    String? universite,
    String? dortoir,
    int? heatLeft,
    String? role,
    String? universityId,
    String? dormId,
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
      role: role ?? this.role,
      universityId: universityId ?? this.universityId,
      dormId: dormId ?? this.dormId,
    );
  }

  // =========================
  // Helpers
  // =========================
  String get displayNameOrEmail => displayName ?? email;

  bool get hasPhoto => photoURL != null && photoURL!.isNotEmpty;

  bool get hasDormInfo =>
      pays != null && ville != null && universite != null && dortoir != null;

  String? get dormPath {
    if (!hasDormInfo) return null;
    return "countries/$pays/cities/$ville/Universities/$universite/dorms/$dortoir/machines";
  }

  static AppUser fromFirestoreDoc(
      DocumentSnapshot doc,
      String? emailAuth,
      ) {
    return AppUser.fromMap(
      doc.data() as Map<String, dynamic>,
      doc.id,
      emailAuth,
    );
  }
}
