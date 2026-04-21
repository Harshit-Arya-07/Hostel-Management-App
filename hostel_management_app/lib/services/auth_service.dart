import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class AuthService extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  static const String _allowedAdminEmail = 'admin@gmail.com';
  static const String _defaultAdminSignupCode = 'HOSTEL_ADMIN_2026';

  User? get currentUser => _auth.currentUser;
  bool get isLoggedIn => _auth.currentUser != null;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<UserCredential> signUp({
    required String name,
    required String email,
    required String password,
    required String role,
    String adminCode = '',
  }) async {
    final normalizedEmail = email.trim().toLowerCase();
    final resolvedRole = _resolveSignupRole(
      requestedRole: role,
      email: normalizedEmail,
      adminCode: adminCode,
    );

    final credential = await _auth.createUserWithEmailAndPassword(
      email: normalizedEmail,
      password: password,
    );

    await credential.user?.updateDisplayName(name);

    try {
      await _db.collection('users').doc(credential.user!.uid).set({
        'uid': credential.user!.uid,
        'name': name,
        'email': normalizedEmail,
        'phone': '',
        'parentPhone': '',
        'hostelName': '',
        'role': resolvedRole,
        'roomId': '',
        'createdAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (_) {}

    notifyListeners();
    return credential;
  }

  Future<UserCredential> signIn({
    required String email,
    required String password,
  }) async {
    final credential = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    notifyListeners();
    return credential;
  }

  Future<String> getUserRole() async {
    final user = currentUser;
    if (user == null) return 'student';

    try {
      final doc = await _db.collection('users').doc(user.uid).get();
      final data = doc.data();
      final storedRole = (data?['role'] as String?)?.toLowerCase();
      if (storedRole == 'admin' || storedRole == 'student') {
        return storedRole!;
      }

      await _db.collection('users').doc(user.uid).set(
        {'role': 'student'},
        SetOptions(merge: true),
      );
      return 'student';
    } catch (_) {
      return 'student';
    }
  }

  String _resolveSignupRole({
    required String requestedRole,
    required String email,
    required String adminCode,
  }) {
    final normalizedRequestedRole = requestedRole.toLowerCase();
    if (normalizedRequestedRole != 'admin') return 'student';

    final configuredAdminCode = const String.fromEnvironment(
      'ADMIN_SIGNUP_CODE',
      defaultValue: _defaultAdminSignupCode,
    );
    final hasValidAdminCode =
        adminCode.isNotEmpty && adminCode == configuredAdminCode;
    final hasAdminEmail = email == _allowedAdminEmail;

    return (hasAdminEmail || hasValidAdminCode) ? 'admin' : 'student';
  }

  Future<Map<String, dynamic>?> getUserData() async {
    final user = currentUser;
    if (user == null) return null;

    try {
      final doc = await _db.collection('users').doc(user.uid).get();
      return doc.data();
    } catch (_) {
      return {
        'uid': user.uid,
        'name': user.displayName ?? '',
        'email': user.email ?? '',
        'role': 'student',
        'roomId': '',
      };
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
    notifyListeners();
  }

  Future<void> logout() async {
    await signOut();
  }

  Future<void> resetPassword(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }
}
