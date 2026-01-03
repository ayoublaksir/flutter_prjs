// lib/services/auth_service.dart
import '../services/database_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../models/user_model.dart';

class AuthService extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final DatabaseService _db = DatabaseService();
  UserModel? _user;

  UserModel? get currentUser => _user;

  AuthService() {
    _auth.authStateChanges().listen(_onAuthStateChanged);
  }

  Future<void> _onAuthStateChanged(User? firebaseUser) async {
    if (firebaseUser != null) {
      try {
        _user = await _db.getUser(firebaseUser.uid);
      } catch (e) {
        print('Error fetching user data: $e');
        _user = null;
      }
    } else {
      _user = null;
    }
    notifyListeners();
  }

  Future<void> signInWithEmail(String email, String password) async {
    try {
      final result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      if (result.user != null) {
        _user = await _db.getUser(result.user!.uid);
        notifyListeners();
      }
    } catch (e) {
      throw _handleAuthError(e);
    }
  }

  Future<void> signUpWithEmail(
    String email,
    String password,
    String name,
  ) async {
    try {
      final result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (result.user != null) {
        final newUser = UserModel(
          id: result.user!.uid,
          email: email,
          name: name,
          createdAt: DateTime.now(),
          badges: [],
        );

        await _db.createUser(newUser);
        _user = newUser;
        notifyListeners();
      }
    } catch (e) {
      throw _handleAuthError(e);
    }
  }

  String _handleAuthError(dynamic error) {
    if (error is FirebaseAuthException) {
      switch (error.code) {
        case 'email-already-in-use':
          return 'This email is already registered';
        case 'invalid-email':
          return 'Invalid email address';
        case 'weak-password':
          return 'Password is too weak';
        case 'user-not-found':
          return 'No user found with this email';
        case 'wrong-password':
          return 'Incorrect password';
        default:
          return 'Authentication failed: ${error.message}';
      }
    }
    return 'An unexpected error occurred';
  }

  Future<void> signOut() async {
    await _auth.signOut();
    _user = null;
    notifyListeners();
  }
}
