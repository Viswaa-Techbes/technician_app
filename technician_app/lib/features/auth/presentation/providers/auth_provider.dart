import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/security/rbac_constants.dart';
import '../../domain/entities/user_session.dart';

class AuthNotifier extends StateNotifier<UserSession?> {
  AuthNotifier() : super(null);

  final _auth = FirebaseAuth.instance;
  final _db = FirebaseFirestore.instance;

  // Set this to true to reconnect to real Firebase later
  static const bool _bypassAuth = true;

  Future<UserSession> login({
    required String email,
    required String password,
  }) async {
    if (_bypassAuth) {
      final role = email.contains('admin') || email.contains('manager') 
          ? Role.manager 
          : Role.technician;
      
      final session = UserSession(
        id: 'mock_user_id',
        name: 'Guest User',
        email: email,
        role: role,
        token: 'mock_token',
      );
      state = session;
      return session;
    }

    final cred = await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    
    final doc = await _db.collection('users').doc(cred.user!.uid).get();
    if (!doc.exists) {
      throw Exception('User data not found in registration records.');
    }
    
    final session = UserSession(
      id: cred.user!.uid,
      name: doc.data()?['name'] ?? 'Unknown',
      email: cred.user!.email ?? '',
      role: Role.values.firstWhere(
        (e) => e.name == (doc.data()?['role'] ?? 'technician'),
        orElse: () => Role.technician,
      ),
      token: '',
    );
    state = session;
    return session;
  }

  Future<UserSession> register({
    required String name,
    required String email,
    required String password,
    required Role role,
  }) async {
    if (_bypassAuth) {
      final session = UserSession(
        id: 'mock_user_${DateTime.now().millisecondsSinceEpoch}',
        name: name,
        email: email,
        role: role,
        token: 'mock_token',
      );
      state = session;
      return session;
    }

    final cred = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );

    await _db.collection('users').doc(cred.user!.uid).set({
      'name': name.trim(),
      'email': email.trim(),
      'role': role.name,
      'createdAt': FieldValue.serverTimestamp(),
    });

    final session = UserSession(
      id: cred.user!.uid,
      name: name.trim(),
      email: email.trim(),
      role: role,
      token: '',
    );
    state = session;
    return session;
  }

  Future<void> logout() async {
    if (!_bypassAuth) {
      if (state?.role == Role.technician) {
        await _db.collection('technicians').doc(_auth.currentUser?.uid).update({
          'isOnline': false,
          'lastActiveAt': FieldValue.serverTimestamp(),
        });
      }
      await _auth.signOut();
    }
    state = null;
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, UserSession?>((ref) {
  return AuthNotifier();
});
