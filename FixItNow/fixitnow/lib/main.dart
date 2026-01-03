// main.dart
// Entry point of the home services application

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'app.dart';
import 'services/firebase_service.dart';

void main() async {
  print('=== MAIN: Starting application initialization ===');
  WidgetsFlutterBinding.ensureInitialized();
  print('=== MAIN: Flutter binding initialized ===');

  try {
    // Create a singleton instance of FirebaseService
    final firebaseService = FirebaseService();
    print('=== MAIN: FirebaseService instance created ===');

    // Try to get the default app - if it exists, use it
    FirebaseApp? defaultApp;
    try {
      print('=== MAIN: Trying to get existing Firebase app ===');
      defaultApp = Firebase.app();
      print('=== MAIN: Found existing Firebase app: ${defaultApp.name} ===');
    } catch (e) {
      print('=== MAIN: No existing Firebase app found, will initialize ===');
    }

    // Initialize Firebase only if we don't have a default app
    if (defaultApp == null) {
      try {
        print('=== MAIN: Initializing Firebase ===');
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );
        print('=== MAIN: Firebase initialized successfully ===');
      } catch (e) {
        // If we get a duplicate app error, try to get the existing app
        if (e.toString().contains('duplicate-app')) {
          print('=== MAIN: Caught duplicate app error, using existing app ===');
          defaultApp = Firebase.app();
        } else {
          // Rethrow if it's not a duplicate app error
          rethrow;
        }
      }
    }

    // Initialize FirebaseService
    print('=== MAIN: Calling FirebaseService.initialize() ===');
    await firebaseService.initialize();
    print('=== MAIN: FirebaseService initialized successfully ===');

    // Run the app
    print('=== MAIN: Running app ===');
    runApp(const HomeServicesApp());
  } catch (e, stackTrace) {
    print('=== MAIN: Initialization error: $e ===');
    print('=== MAIN: Stack trace: $stackTrace ===');

    // Run a minimal app that displays the error
    runApp(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Error initializing app:'),
                const SizedBox(height: 16),
                Text(e.toString()),
                const SizedBox(height: 16),
                const Text('Check logs for more details'),
              ],
            ),
          ),
        ),
      ),
    );
  }
}