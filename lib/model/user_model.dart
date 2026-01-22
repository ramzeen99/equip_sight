import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AppUser {
  final String id;
  final String email;
  final String? displayName;
  final String? photoURL;
  final bool? emailVerified;

  /// 🔥 Nouvelle structure
  final String role;
  final String? countryId;
  final String? cityId;
  final String? universityId;
  final String? dormId;

  final int? heatLeft;

  AppUser({
    required this.id,
    required this.email,
    required this.role,
    this.displayName,
    this.photoURL,
    this.emailVerified,
    this.countryId,
    this.cityId,
    this.universityId,
    this.dormId,
    this.heatLeft,
  });

  // =========================
  // Firebase Auth → AppUser
  // =========================
  factory AppUser.fromFirebaseUser(User user, {String role = 'user'}) {
    return AppUser(
      id: user.uid,
      email: user.email ?? '',
      displayName: user.displayName,
      photoURL: user.photoURL,
      emailVerified: user.emailVerified,
      role: role,
    );
  }

  // =========================
  // Firestore → AppUser
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
      role: map['role'] ?? 'user',
      countryId: map['countryId'],
      cityId: map['cityId'],
      universityId: map['universityId'],
      dormId: map['dormId'],
      heatLeft: map['heatLeft'] != null
          ? (map['heatLeft'] as num).toInt()
          : null,
    );
  }

  // =========================
  // AppUser → Firestore
  // =========================
  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'displayName': displayName,
      'photoURL': photoURL,
      'emailVerified': emailVerified,
      'role': role,
      'countryId': countryId,
      'cityId': cityId,
      'universityId': universityId,
      'dormId': dormId,
      'heatLeft': heatLeft,
      'lastUpdated': FieldValue.serverTimestamp(),
    };
  }

  // =========================
  // CopyWith
  // =========================
  AppUser copyWith({
    String? displayName,
    String? photoURL,
    String? role,
    String? countryId,
    String? cityId,
    String? universityId,
    String? dormId,
    int? heatLeft,
  }) {
    return AppUser(
      id: id,
      email: email,
      displayName: displayName ?? this.displayName,
      photoURL: photoURL ?? this.photoURL,
      emailVerified: emailVerified,
      role: role ?? this.role,
      countryId: countryId ?? this.countryId,
      cityId: cityId ?? this.cityId,
      universityId: universityId ?? this.universityId,
      dormId: dormId ?? this.dormId,
      heatLeft: heatLeft ?? this.heatLeft,
    );
  }

  // =========================
  // Helpers
  // =========================
  String get displayNameOrEmail => displayName ?? email;

  bool get hasPhoto => photoURL != null && photoURL!.isNotEmpty;

  bool get hasDormInfo =>
      countryId != null &&
      cityId != null &&
      universityId != null &&
      dormId != null;

  String? get dormPath {
    if (!hasDormInfo) return null;
    return "countries/$countryId"
        "/cities/$cityId"
        "/universities/$universityId"
        "/dorms/$dormId"
        "/machines";
  }

  static AppUser fromFirestoreDoc(DocumentSnapshot doc, String? emailAuth) {
    return AppUser.fromMap(
      doc.data() as Map<String, dynamic>,
      doc.id,
      emailAuth,
    );
  }
}
