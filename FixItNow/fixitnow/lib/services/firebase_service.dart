import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import '../firebase_options.dart';

class FirebaseService {
  static final FirebaseService _instance = FirebaseService._internal();
  static bool _initialized = false; // Make this static to ensure it's shared

  factory FirebaseService() => _instance;

  FirebaseService._internal() {
    debugPrint('FirebaseService._internal() called');
  }

  // Firebase instances - only initialize these after Firebase.initializeApp is called
  static late firebase_auth.FirebaseAuth _auth;
  static late FirebaseFirestore _firestore;
  static late FirebaseStorage _storage;
  static late FirebaseMessaging _messaging;

  // Getters
  static firebase_auth.FirebaseAuth get auth {
    _checkInitialized();
    return _auth;
  }

  static FirebaseFirestore get firestore {
    _checkInitialized();
    return _firestore;
  }

  static FirebaseStorage get storage {
    _checkInitialized();
    return _storage;
  }

  static FirebaseMessaging get messaging {
    _checkInitialized();
    return _messaging;
  }

  static void _checkInitialized() {
    if (!_initialized) {
      throw Exception(
        'Firebase must be initialized first. Call FirebaseService().initialize()',
      );
    }
  }

  Future<void> initialize() async {
    print(
      '=== FIREBASE_SERVICE: initialize() called, _initialized=$_initialized ===',
    );

    if (_initialized) {
      print('=== FIREBASE_SERVICE: Already initialized, skipping... ===');
      return;
    }

    try {
      print(
        '=== FIREBASE_SERVICE: Checking Firebase.apps.length: ${Firebase.apps.length} ===',
      );

      if (Firebase.apps.isEmpty) {
        print(
          '=== FIREBASE_SERVICE: ERROR - Firebase not initialized in main.dart ===',
        );
        throw Exception(
          'Firebase should be initialized in main.dart before calling FirebaseService.initialize()',
        );
      }

      print('=== FIREBASE_SERVICE: Getting Firebase instances ===');

      try {
        _auth = firebase_auth.FirebaseAuth.instance;
        print('=== FIREBASE_SERVICE: Got FirebaseAuth instance ===');
      } catch (e) {
        print(
          '=== FIREBASE_SERVICE: Error getting FirebaseAuth instance: $e ===',
        );
        rethrow;
      }

      try {
        _firestore = FirebaseFirestore.instance;
        print('=== FIREBASE_SERVICE: Got FirebaseFirestore instance ===');
      } catch (e) {
        print(
          '=== FIREBASE_SERVICE: Error getting FirebaseFirestore instance: $e ===',
        );
        rethrow;
      }

      try {
        _storage = FirebaseStorage.instance;
        print('=== FIREBASE_SERVICE: Got FirebaseStorage instance ===');
      } catch (e) {
        print(
          '=== FIREBASE_SERVICE: Error getting FirebaseStorage instance: $e ===',
        );
        rethrow;
      }

      try {
        _messaging = FirebaseMessaging.instance;
        print('=== FIREBASE_SERVICE: Got FirebaseMessaging instance ===');
      } catch (e) {
        print(
          '=== FIREBASE_SERVICE: Error getting FirebaseMessaging instance: $e ===',
        );
        rethrow;
      }

      _initialized = true;
      print(
        '=== FIREBASE_SERVICE: All Firebase services initialized successfully ===',
      );
    } catch (e, stackTrace) {
      print('=== FIREBASE_SERVICE: Initialization error: $e ===');
      print('=== FIREBASE_SERVICE: Stack trace: $stackTrace ===');
      rethrow;
    }
  }

  bool get isInitialized => _initialized;
}

// Custom FirebaseAuth class to avoid naming conflicts
class FirebaseAuth {
  final firebase_auth.FirebaseAuth _auth;

  FirebaseAuth(this._auth);

  firebase_auth.User? get currentUser => _auth.currentUser;

  static FirebaseAuth get auth => FirebaseAuth(FirebaseService.auth);
}
