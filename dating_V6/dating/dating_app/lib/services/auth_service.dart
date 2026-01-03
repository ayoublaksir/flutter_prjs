import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../models/gender.dart';
import '../models/date_mood.dart';
import '../models/date_category.dart';
import '../models/relationship_stage.dart';
import '../models/date_models.dart' show UserPreferences;
import '../models/user_profile.dart';
import 'dart:io';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:dating_app/services/purchase_service.dart';
import 'package:flutter/foundation.dart';

class AuthService with ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  bool isPremium = false;

  Future<UserCredential> register({
    required String email,
    required String password,
    required String name,
    required Gender gender,
    required List<DateMood> preferredMoods,
    required List<DateCategory> preferredCategories,
    required File? profileImage,
  }) async {
    try {
      print('Starting registration process...');

      // Check Firestore connection first
      try {
        await FirebaseFirestore.instance.enableNetwork();
        print('✅ Firestore network enabled');
      } catch (e) {
        print('❌ Firestore network error: $e');
        throw Exception(
          'Unable to connect to Firestore. Please check your internet connection.',
        );
      }

      // Step 1: Create auth user
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      print('✅ Auth user created with ID: ${userCredential.user?.uid}');

      final userData = {
        'name': name,
        'email': email,
        'gender': gender.name,
        'profileImageUrl': null,
        'preferences': {
          'preferredMoods': preferredMoods.map((m) => m.name).toList(),
          'preferredCategories':
              preferredCategories.map((c) => c.name).toList(),
          'relationshipStage': RelationshipStage.firstDate.name,
          'budget': 100.0,
          'dietaryRestrictions': false,
          'activityLevel': 5,
        },
        'createdAt': FieldValue.serverTimestamp(),
      };

      // Step 2: Verify Firestore connection
      try {
        print('Checking Firestore connection...');
        final testDoc = await _firestore.collection('test').doc('test').get();
        print('✅ Firestore connection successful');
      } catch (e) {
        print('❌ Firestore connection error: $e');
      }

      // Step 3: Create user document
      print('Creating user document...');
      int attempts = 0;
      while (attempts < 3) {
        try {
          await _firestore
              .collection('users')
              .doc(userCredential.user!.uid)
              .set(userData);
          print('✅ User document created successfully');
          break;
        } catch (e) {
          attempts++;
          print('❌ Attempt $attempts failed: $e');
          if (attempts == 3) throw e;
          await Future.delayed(Duration(seconds: 1));
        }
      }

      // Step 4: Handle profile image
      if (profileImage != null) {
        print('Uploading profile image...');
        try {
          final ref = _storage.ref().child(
            'profile_images/${userCredential.user!.uid}/main',
          );
          final uploadTask = await ref.putFile(profileImage);
          final imageUrl = await uploadTask.ref.getDownloadURL();

          await _firestore
              .collection('users')
              .doc(userCredential.user!.uid)
              .update({'profileImageUrl': imageUrl});

          print('✅ Profile image uploaded and user updated');
        } catch (e) {
          print('❌ Image upload failed: $e');
        }
      }

      print('✅ Registration completed successfully');
      return userCredential;
    } catch (e) {
      print('❌ Registration failed: $e');
      rethrow;
    }
  }

  Future<UserCredential> login(String email, String password) async {
    try {
      return await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } catch (e) {
      throw Exception('Login failed: $e');
    }
  }

  Future<void> logout() async {
    await _auth.signOut();
  }

  Future<UserProfile> getCurrentUserProfile() async {
    try {
      final user = _auth.currentUser;
      print('🔍 Checking current user...');
      if (user == null) {
        print('❌ No user logged in');
        throw Exception('No user logged in');
      }
      print('✅ Current user found: ${user.uid}');

      print('🔍 Fetching user document from Firestore...');
      var doc = await _firestore.collection('users').doc(user.uid).get();
      if (!doc.exists) {
        print('❌ User document not found in Firestore');
        // Try to create a default profile
        print('🔄 Attempting to create default profile...');
        await _createDefaultUserProfile(user);
        // Fetch the document again
        doc = await _firestore.collection('users').doc(user.uid).get();
        if (!doc.exists) {
          print('❌ Failed to create default profile');
          throw Exception(
            'User profile not found and could not create default',
          );
        }
        print('✅ Default profile created successfully');
      }
      print('✅ User document found');

      final data = doc.data()!;
      print('📄 Document data: $data');

      // Handle potential missing preferences
      final prefsData = data['preferences'] as Map<String, dynamic>? ?? {};
      print('🔧 Preferences data: $prefsData');

      // Handle potential null timestamp
      final timestamp = data['createdAt'] as Timestamp?;
      final createdAt = timestamp?.toDate() ?? DateTime.now();

      // Get current location if city is not set
      String? city = data['city'] as String?;
      if (city == null || city == 'Unknown') {
        try {
          print('🌍 Getting current location...');
          final position = await Geolocator.getCurrentPosition();
          final placemarks = await placemarkFromCoordinates(
            position.latitude,
            position.longitude,
          );

          city = placemarks.first.locality;
          print('📍 Found city: $city');

          // Update the user's location in Firestore
          await updateUserLocation(
            latitude: position.latitude,
            longitude: position.longitude,
            city: city ?? 'Unknown',
          );
          print('✅ Location updated in Firestore');
        } catch (e) {
          print('❌ Error getting location: $e');
        }
      }

      final profile = UserProfile(
        uid: user.uid,
        name: data['name'] as String? ?? 'User',
        email: data['email'] as String? ?? user.email ?? 'No email',
        gender: _parseGender(data['gender'] as String? ?? 'male'),
        profileImageUrl: data['profileImageUrl'] as String?,
        preferences: _parseUserPreferences(prefsData),
        location: data['location'] as GeoPoint?,
        city: city,
        createdAt: createdAt,
      );
      print('✅ User profile created successfully');
      return profile;
    } catch (e) {
      print('❌ Failed to get user profile: $e');
      print('Stack trace: ${StackTrace.current}');
      throw Exception('Failed to get user profile: $e');
    }
  }

  Future<void> _createDefaultUserProfile(User user) async {
    final defaultData = {
      'name': user.displayName ?? 'User',
      'email': user.email,
      'gender': 'male', // Default gender
      'profileImageUrl': user.photoURL,
      'preferences': {
        'preferredMoods': [],
        'preferredCategories': [],
        'relationshipStage': 'firstDate',
        'budget': 100.0,
        'dietaryRestrictions': false,
        'activityLevel': 5,
      },
      'location': null,
      'city': 'Unknown',
      'createdAt': FieldValue.serverTimestamp(),
    };

    await _firestore.collection('users').doc(user.uid).set(defaultData);
  }

  Future<void> debugPrintUserData() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        print('No user is signed in');
        return;
      }

      print('Current User ID: ${user.uid}');

      final doc = await _firestore.collection('users').doc(user.uid).get();
      if (!doc.exists) {
        print('No user profile found in Firestore');
        return;
      }

      print('User Data in Firestore:');
      print(doc.data());
    } catch (e) {
      print('Error fetching user data: $e');
    }
  }

  Future<UserCredential> signInWithEmailAndPassword(
    String email,
    String password,
  ) async {
    try {
      final UserCredential userCredential = await _auth
          .signInWithEmailAndPassword(email: email, password: password);
      return userCredential;
    } catch (e) {
      print('Error signing in: $e');
      throw e;
    }
  }

  // Helper methods for parsing enums
  Gender _parseGender(String value) {
    return Gender.values.firstWhere((g) => g.name == value);
  }

  DateMood _parseDateMood(String value) {
    return DateMood.values.firstWhere(
      (m) => m.name == value,
      orElse: () => DateMood.chill,
    );
  }

  DateCategory _parseDateCategory(String value) {
    return DateCategory.values.firstWhere(
      (c) => c.name == value,
      orElse: () => DateCategory.restaurant,
    );
  }

  RelationshipStage _parseRelationshipStage(String value) {
    return RelationshipStage.values.firstWhere(
      (s) => s.name == value,
      orElse: () => RelationshipStage.firstDate,
    );
  }

  UserPreferences _parseUserPreferences(Map<String, dynamic> prefsData) {
    return UserPreferences(
      preferredMoods: _parseMoods(prefsData['preferredMoods'] as List?),
      preferredCategories: _parseCategories(
        prefsData['preferredCategories'] as List?,
      ),
      relationshipStage: _parseRelationshipStage(
        prefsData['relationshipStage'] as String? ?? 'firstDate',
      ),
      dietaryRestrictions: prefsData['dietaryRestrictions'] as bool? ?? false,
      activityLevel: prefsData['activityLevel'] as int? ?? 5,
    );
  }

  Future<void> updateUserLocation({
    required double latitude,
    required double longitude,
    required String city,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('No user logged in');

    await _firestore.collection('users').doc(user.uid).update({
      'location': GeoPoint(latitude, longitude),
      'city': city,
    });
  }

  String? getCurrentUserId() {
    return _auth.currentUser?.uid;
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  List<DateMood> _parseMoods(List? moodStrings) {
    if (moodStrings == null) return [];
    return moodStrings.map((m) => _parseDateMood(m.toString())).toList();
  }

  List<DateCategory> _parseCategories(List? categoryStrings) {
    if (categoryStrings == null) return [];
    return categoryStrings
        .map((c) => _parseDateCategory(c.toString()))
        .toList();
  }

  Future<UserProfile> getUserProfile(String userId) async {
    final doc = await _firestore.collection('users').doc(userId).get();
    if (!doc.exists) {
      throw Exception('User profile not found');
    }
    return UserProfile.fromFirestore(doc);
  }

  Future<void> registerWithEmailAndPassword(
    String email,
    String password,
    String name,
    DateTime birthDate,
    String gender,
    String bio,
    List<String> interests,
    List<String> preferredDateMoods,
    List<String> preferredDateCategories,
    List<File> images,
  ) async {
    try {
      // Create user account
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Upload profile images
      List<String> imageUrls = [];
      for (var image in images) {
        final ref = _storage.ref().child(
          'user_images/${userCredential.user!.uid}/${DateTime.now().millisecondsSinceEpoch}',
        );
        await ref.putFile(image);
        final url = await ref.getDownloadURL();
        imageUrls.add(url);
      }

      // Create user profile with the proper structure
      await _firestore.collection('users').doc(userCredential.user!.uid).set({
        'name': name,
        'email': email,
        'birthDate': birthDate,
        'gender': gender,
        'bio': bio,
        'interests': interests,
        'profileImageUrl':
            imageUrls.isNotEmpty
                ? imageUrls[0]
                : null, // Set main profile image
        'additionalImages': imageUrls.length > 1 ? imageUrls.sublist(1) : [],
        'preferences': {
          'preferredMoods': preferredDateMoods,
          'preferredCategories': preferredDateCategories,
          'relationshipStage': 'firstDate', // Default value
          'budget': 100.0, // Default value
          'dietaryRestrictions': false, // Default value
          'activityLevel': 5, // Default value
        },
        'location': null, // Will be updated later
        'city': 'Unknown', // Will be updated later
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error during registration: $e');
      rethrow;
    }
  }

  // Add this method to help debug user profile issues
  Future<void> debugUserProfile() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        print('No user is currently logged in');
        return;
      }

      print('Current user ID: ${user.uid}');
      print('Current user email: ${user.email}');

      final doc = await _firestore.collection('users').doc(user.uid).get();
      if (!doc.exists) {
        print('No user document found in Firestore for this user');
        return;
      }

      print('User document exists in Firestore');
      print('Document data:');
      final data = doc.data();
      print(data);

      // Check specific fields
      print('Has preferences field: ${data?.containsKey('preferences')}');
      if (data?.containsKey('preferences') == true) {
        print('Preferences data: ${data!['preferences']}');
      }

      print('Has profileImageUrl: ${data?.containsKey('profileImageUrl')}');
      print('Has location: ${data?.containsKey('location')}');
    } catch (e) {
      print('Error debugging user profile: $e');
    }
  }

  Future<UserCredential> signUpWithEmailAndPassword({
    required String email,
    required String password,
    required Map<String, dynamic> userData,
  }) async {
    try {
      // Create user with email and password
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Add user data to Firestore
      if (userCredential.user != null) {
        await _firestore.collection('users').doc(userCredential.user!.uid).set({
          'email': email,
          ...userData,
        });
      }

      return userCredential;
    } catch (e) {
      print('Error signing up: $e');
      throw e;
    }
  }

  // Add method to check premium status
  Future<bool> checkPremiumStatus(String userId) async {
    try {
      // Check with your backend if the user has an active premium subscription
      final userDoc =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(userId)
              .get();
      isPremium = userDoc.data()?['isPremium'] ?? false;
      return isPremium;
    } catch (e) {
      print('Error checking premium status: $e');
      return false;
    }
  }

  // Add method to update premium status
  Future<void> updatePremiumStatus(String userId, bool status) async {
    try {
      await FirebaseFirestore.instance.collection('users').doc(userId).update({
        'isPremium': status,
      });
      isPremium = status;
    } catch (e) {
      print('Error updating premium status: $e');
    }
  }

  // Add this getter
  bool get isLoggedIn => _auth.currentUser != null;
}
