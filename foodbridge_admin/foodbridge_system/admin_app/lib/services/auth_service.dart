// auth_service.dart — shared across all apps

import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/models.dart';

class AuthService {
  static final AuthService _i = AuthService._();
  factory AuthService() => _i;
  AuthService._();

  final _auth = FirebaseAuth.instance;
  final _db   = FirebaseFirestore.instance;

  Stream<User?> get authStateChanges => _auth.authStateChanges();
  User? get firebaseUser => _auth.currentUser;

  // ── Fetch user from Firestore ──────────────────────────────────────
  Future<AppUser?> fetchAppUser(String uid) async {
    try {
      final doc = await _db.collection('users').doc(uid).get();
      if (!doc.exists || doc.data() == null) return null;
      return AppUser.fromMap(uid, doc.data()!);
    } catch (e) {
      debugPrint('[AuthService] fetchAppUser: $e');
      return null;
    }
  }

  // ── Sign in ────────────────────────────────────────────────────────
  Future<AppUser> signIn({
    required String email,
    required String password,
  }) async {
    final cred = await _auth.signInWithEmailAndPassword(
      email: email.trim(), password: password,
    );
    final user = await fetchAppUser(cred.user!.uid);
    if (user == null) throw Exception('Profile not found. Please register.');
    return user;
  }

  // ── Register (user / volunteer) ────────────────────────────────────
  Future<AppUser> register({
    required String email,
    required String password,
    required String name,
    required UserRole role,
  }) async {
    // Prevent registering as admin via the public app
    final safeRole = role == UserRole.admin ? UserRole.user : role;

    final cred = await _auth.createUserWithEmailAndPassword(
      email: email.trim(), password: password,
    );
    final uid = cred.user!.uid;

    final user = AppUser(
      uid: uid, email: email.trim(), name: name.trim(), role: safeRole,
    );

    await _db.collection('users').doc(uid).set({
      ...user.toMap(),
      'createdAt': FieldValue.serverTimestamp(),
    });

    return user;
  }

  // ── Register admin (called from Admin App only) ────────────────────
  Future<AppUser> registerAdmin({
    required String email,
    required String password,
    required String name,
  }) async {
    final cred = await _auth.createUserWithEmailAndPassword(
      email: email.trim(), password: password,
    );
    final uid = cred.user!.uid;

    final user = AppUser(
      uid: uid, email: email.trim(), name: name.trim(),
      role: UserRole.admin,
    );

    await _db.collection('users').doc(uid).set({
      ...user.toMap(),
      'createdAt': FieldValue.serverTimestamp(),
    });

    return user;
  }

  // ── Sign out ───────────────────────────────────────────────────────
  Future<void> signOut() => _auth.signOut();

  // ── Update role ────────────────────────────────────────────────────
  Future<void> updateUserRole(String uid, UserRole newRole) async {
    await _db.collection('users').doc(uid).update({'role': newRole.name});
  }
}
