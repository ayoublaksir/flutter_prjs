// services/auth_services.dart
// Authentication service for handling user authentication

import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import '../services/api_services.dart';
import '../models/user_models.dart';
import '../services/firebase_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';

class AuthService {
  final AuthAPI _authAPI = AuthAPI();
  final UserAPI _userAPI = UserAPI();
  final firebase_auth.FirebaseAuth _auth = FirebaseService.auth;

  // Get current user
  firebase_auth.User? get currentUser => _auth.currentUser;

  // Check if user is logged in
  bool get isLoggedIn => currentUser != null;

  // Sign in with email and password
  Future<firebase_auth.User?> signInWithEmailAndPassword(
    String email,
    String password,
  ) async {
    return await _authAPI.signInWithEmailAndPassword(email, password);
  }

  // Sign up with email and password
  Future<firebase_auth.User?> signUpWithEmailAndPassword(
    String email,
    String password,
  ) async {
    return await _authAPI.signUpWithEmailAndPassword(email, password);
  }

  // Sign out
  Future<void> signOut() async {
    await _authAPI.signOut();
  }

  // Reset password
  Future<void> resetPassword(String email) async {
    await _authAPI.resetPassword(email);
  }

  // Get user profile (either seeker or provider)
  Future<dynamic> getUserProfile(String userId, String userType) async {
    if (userType == 'provider') {
      return await _userAPI.getProviderProfile(userId);
    } else {
      return await _userAPI.getSeekerProfile(userId);
    }
  }

  // Add this method to get the user's role
  Future<String> getUserRole() async {
    if (!isLoggedIn) return '';

    final userId = currentUser!.uid;

    // Check if user is a provider
    final providerProfile = await _userAPI.getProviderProfile(userId);
    if (providerProfile != null) {
      return 'provider';
    }

    // Check if user is a seeker
    final seekerProfile = await _userAPI.getSeekerProfile(userId);
    if (seekerProfile != null) {
      return 'seeker';
    }

    return ''; // No role found
  }

  // Initialize Firebase
  Future<void> initialize() async {
    debugPrint(
      'AuthService.initialize() called - Firebase should already be initialized',
    );
  }

  // Add this method to the AuthService class
  Future<void> changeUserRole(String role) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('userRole', role);
  }

  // Delete account
  Future<void> deleteAccount(String password) async {
    try {
      if (currentUser == null) {
        throw Exception('User not logged in');
      }

      // Re-authenticate user before deletion
      final credential = firebase_auth.EmailAuthProvider.credential(
        email: currentUser!.email!,
        password: password,
      );
      await currentUser!.reauthenticateWithCredential(credential);

      // Delete user data from Firestore
      final userId = currentUser!.uid;
      final role = await getUserRole();

      if (role == 'provider') {
        await _userAPI.firestore.collection('providers').doc(userId).delete();
      } else if (role == 'seeker') {
        await _userAPI.firestore.collection('seekers').doc(userId).delete();
      }

      // Delete Auth account
      await currentUser!.delete();
    } catch (e) {
      debugPrint('Error deleting account: $e');
      rethrow;
    }
  }

  // Change password
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      if (currentUser == null || currentUser!.email == null) {
        throw Exception('User not logged in or no email');
      }

      // Re-authenticate user
      final credential = firebase_auth.EmailAuthProvider.credential(
        email: currentUser!.email!,
        password: currentPassword,
      );
      await currentUser!.reauthenticateWithCredential(credential);

      // Change password
      await currentUser!.updatePassword(newPassword);
    } catch (e) {
      debugPrint('Error changing password: $e');
      rethrow;
    }
  }
}
