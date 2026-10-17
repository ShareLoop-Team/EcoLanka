// User profile reads/writes in Firestore (users/{uid}).
// Schema: docs/SCHEMA.md · Rules: backend/firestore.rules

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/user.dart';

class DatabaseService {
  DatabaseService._();

  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  static DocumentReference<Map<String, dynamic>> userRef(String uid) =>
      _db.collection('users').doc(uid);

  /// The signed-in user's profile, or null if they haven't completed setup.
  static Future<AppUser?> getCurrentUserProfile() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return null;
    final snap = await userRef(uid).get();
    if (!snap.exists) return null;
    return AppUser.fromMap(snap.id, snap.data()!);
  }

  /// Creates the profile after first sign-in (profile setup screen).
  static Future<void> createUserProfile({
    required String displayName,
    required String district,
    required String role, // donor | requester | both
    required String language, // en | si | ta
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw StateError('Not signed in.');

    final profile = AppUser(
      uid: user.uid,
      displayName: displayName,
      phone: user.phoneNumber,
      email: user.email,
      role: role,
      language: language,
      district: district,
    );

    await userRef(user.uid).set({
      ...profile.toMap(),
      'createdAt': FieldValue.serverTimestamp(),
      'lastActiveAt': FieldValue.serverTimestamp(),
    });
  }

  /// Updates editable profile fields (not role/points/badges — rules block those).
  static Future<void> updateProfile(Map<String, dynamic> fields) async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    await userRef(uid).update({
      ...fields,
      'lastActiveAt': FieldValue.serverTimestamp(),
    });
  }
}
