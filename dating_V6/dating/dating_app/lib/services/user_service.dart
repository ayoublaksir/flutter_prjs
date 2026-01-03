import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../models/user_profile.dart';
import '../models/date_models.dart' show UserPreferences;
import '../models/date_mood.dart';
import '../models/date_category.dart';
import '../models/relationship_stage.dart';
import '../models/gender.dart';
import '../models/cuisine_type.dart';
import 'dart:math' show sin, cos, sqrt, atan2, pi;
import 'dart:math';

class UserService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<void> saveUserPreferences(UserPreferences preferences) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) throw Exception('User not authenticated');

    await _firestore.collection('users').doc(userId).set({
      'preferences': {
        'preferredMoods':
            preferences.preferredMoods.map((m) => m.name).toList(),
        'preferredCategories':
            preferences.preferredCategories.map((c) => c.name).toList(),
        'relationshipStage': preferences.relationshipStage.name,
        'dietaryRestrictions': preferences.dietaryRestrictions,
        'activityLevel': preferences.activityLevel,
        'updatedAt': FieldValue.serverTimestamp(),
      },
    }, SetOptions(merge: true));
  }

  Future<UserPreferences> getUserPreferences() async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) throw Exception('User not authenticated');

    final doc = await _firestore.collection('users').doc(userId).get();
    final data = doc.data()?['preferences'] as Map<String, dynamic>?;

    if (data == null) {
      return UserPreferences(
        preferredMoods: [],
        preferredCategories: [],
        relationshipStage: RelationshipStage.firstDate,
      );
    }

    return UserPreferences(
      preferredMoods:
          (data['preferredMoods'] as List)
              .map((m) => _stringToEnum(m, DateMood.values))
              .whereType<DateMood>()
              .toList(),
      preferredCategories:
          (data['preferredCategories'] as List)
              .map((c) => _stringToEnum(c, DateCategory.values))
              .whereType<DateCategory>()
              .toList(),
      relationshipStage:
          _stringToEnum(data['relationshipStage'], RelationshipStage.values) ??
          RelationshipStage.firstDate,

      dietaryRestrictions: data['dietaryRestrictions'] ?? false,
      activityLevel: data['activityLevel'] ?? 5,
    );
  }

  T? _stringToEnum<T>(String? value, List<T> enumValues) {
    if (value == null) return null;
    return enumValues.firstWhere(
      (e) => e.toString() == value,
      orElse: () => enumValues.first,
    );
  }

  double _calculateDistance(lat1, lon1, lat2, lon2) {
    // Basic Haversine formula
    const R = 6371; // Earth's radius in km
    final dLat = _toRad(lat2 - lat1);
    final dLon = _toRad(lon2 - lon1);
    final a =
        sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRad(lat1)) * cos(_toRad(lat2)) * sin(dLon / 2) * sin(dLon / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return R * c;
  }

  double _toRad(double deg) => deg * pi / 180;

  Future<void> updateUserLocation(LatLng location) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) throw Exception('User not authenticated');

    await _firestore.collection('users').doc(userId).update({
      'location': GeoPoint(location.latitude, location.longitude),
      'lastUpdated': FieldValue.serverTimestamp(),
    });
  }

  List<DateMood> _parsePreferredMoods(Map<String, dynamic> data) {
    return (data['preferredMoods'] as List?)
            ?.map((m) => _stringToEnum(m, DateMood.values))
            .whereType<DateMood>()
            .toList() ??
        [];
  }

  List<DateCategory> _parsePreferredCategories(Map<String, dynamic> data) {
    return (data['preferredCategories'] as List?)
            ?.map((c) => _stringToEnum(c, DateCategory.values))
            .whereType<DateCategory>()
            .toList() ??
        [];
  }

  RelationshipStage _parseRelationshipStage(Map<String, dynamic> data) {
    return _stringToEnum(data['relationshipStage'], RelationshipStage.values) ??
        RelationshipStage.firstDate;
  }

  List<CuisineType> _parseCuisinePreferences(Map<String, dynamic> data) {
    return (data['cuisinePreferences'] as List?)
            ?.map((c) => _stringToEnum(c, CuisineType.values))
            .whereType<CuisineType>()
            .toList() ??
        [];
  }

  Future<void> saveUserProfile(UserProfile profile) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) throw Exception('User not authenticated');

    await _firestore.collection('users').doc(userId).set({
      'name': profile.name,
      'gender': profile.gender.toString(),
      'preferences': {
        'preferredMoods':
            profile.preferences.preferredMoods
                .map((m) => m.toString())
                .toList(),
        'preferredCategories':
            profile.preferences.preferredCategories
                .map((c) => c.toString())
                .toList(),
        'relationshipStage': profile.preferences.relationshipStage.toString(),
        'dietaryRestrictions': profile.preferences.dietaryRestrictions,
        'activityLevel': profile.preferences.activityLevel,
        'updatedAt': FieldValue.serverTimestamp(),
      },
    }, SetOptions(merge: true));
  }

  Stream<List<UserProfile>> getNearbyUsers(
    String userId,
    GeoPoint location,
    double radiusInKm,
  ) {
    // Convert radius to degrees (rough approximation)
    final radiusInDegrees = radiusInKm / 111.0;

    return _firestore
        .collection('users')
        .where('uid', isNotEqualTo: userId)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs
                  .map((doc) => UserProfile.fromFirestore(doc))
                  .where(
                    (user) => _isWithinRadius(
                      user.location,
                      location,
                      radiusInDegrees,
                    ),
                  )
                  .toList(),
        );
  }

  bool _isWithinRadius(GeoPoint? userLocation, GeoPoint center, double radius) {
    if (userLocation == null) return false;

    final latDiff = (userLocation.latitude - center.latitude).abs();
    final longDiff = (userLocation.longitude - center.longitude).abs();
    return latDiff <= radius && longDiff <= radius;
  }

  UserPreferences _parseUserPreferences(Map<String, dynamic> data) {
    return UserPreferences(
      preferredMoods: _parsePreferredMoods(data),
      preferredCategories: _parsePreferredCategories(data),
      relationshipStage: _parseRelationshipStage(data),
      dietaryRestrictions: data['dietaryRestrictions'] ?? false,
      activityLevel: data['activityLevel'] ?? 5,
    );
  }

  Future<void> updateUserPreferences({
    required List<DateMood> preferredMoods,
    required List<DateCategory> preferredCategories,
  }) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) throw Exception('Not authenticated');

    await _firestore.collection('users').doc(userId).update({
      'preferences': {
        'preferredMoods': preferredMoods.map((m) => m.name).toList(),
        'preferredCategories': preferredCategories.map((c) => c.name).toList(),
        'updatedAt': FieldValue.serverTimestamp(),
      },
    });
  }

  Future<UserProfile?> getUserProfile(String userId) async {
    try {
      final doc =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(userId)
              .get();

      if (!doc.exists) {
        print('User document does not exist for ID: $userId');
        return null;
      }

      final data = doc.data()!;
      print('Raw user data: $data'); // Debug log

      // Make sure we're getting the images array
      List<String> additionalImages = [];
      if (data['additionalImages'] != null) {
        additionalImages = List<String>.from(data['additionalImages']);
      }

      print('Additional images from DB: $additionalImages');

      return UserProfile.fromMap(data, userId);
    } catch (e) {
      print('Error getting user profile: $e');
      return null;
    }
  }

  Future<String?> getRandomUserId(String currentUserId) async {
    try {
      // Get a random user that isn't the current user
      final usersSnapshot =
          await _firestore
              .collection('users')
              .where(FieldPath.documentId, isNotEqualTo: currentUserId)
              .limit(10)
              .get();

      if (usersSnapshot.docs.isEmpty) {
        return null;
      }

      // Pick a random user from the results
      final random = Random();
      final randomIndex = random.nextInt(usersSnapshot.docs.length);
      return usersSnapshot.docs[randomIndex].id;
    } catch (e) {
      print('Error getting random user: $e');
      return null;
    }
  }

  Future<UserProfile?> getCurrentUserProfile() async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return null;

    return getUserProfile(userId);
  }

  Future<void> updateUserProfile(UserProfile profile) async {
    try {
      // Convert UserProfile to Map
      final data = {
        'name': profile.name,
        'age': profile.age,
        'gender': profile.gender.toString().split('.').last,
        'bio': profile.bio,
        'city': profile.city,
        'jobTitle': profile.jobTitle,
        'company': profile.company,
        'education': profile.education,
        'profileImageUrl': profile.profileImageUrl,
        'additionalImages': profile.additionalImages,
        'interests': profile.interests,
        'location': profile.location,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      // Remove null values
      data.removeWhere((key, value) => value == null);

      // Update Firestore document
      await _firestore.collection('users').doc(profile.uid).update(data);

      print('✅ User profile updated successfully');
    } catch (e) {
      print('❌ Error updating user profile: $e');
      throw e;
    }
  }
}
