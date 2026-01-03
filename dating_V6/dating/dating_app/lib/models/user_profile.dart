import 'package:cloud_firestore/cloud_firestore.dart';
import 'date_models.dart';
import 'gender.dart';
import 'date_mood.dart';
import 'date_category.dart';
import 'relationship_stage.dart';

class UserProfile {
  final String uid;
  final String name;
  final String email;
  final String? profileImageUrl; // Main profile image
  final List<String> additionalImages; // Additional images
  final int? age;
  final Gender gender;
  final GeoPoint? location;
  final UserPreferences preferences;
  final DateTime? createdAt;
  final bool isVerified;
  final List<String> interests;
  final String? city;
  final String? bio;
  final String? jobTitle;
  final String? company;
  final String? education;

  UserProfile({
    required this.uid,
    required this.name,
    required this.email,
    this.profileImageUrl,
    this.additionalImages = const [],
    this.age,
    required this.gender,
    this.location,
    required this.preferences,
    this.createdAt,
    this.isVerified = false,
    this.interests = const [],
    this.city,
    this.bio,
    this.jobTitle,
    this.company,
    this.education,
  });

  factory UserProfile.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>?;

    if (data == null) {
      throw Exception('User document data is null');
    }

    final prefsData = data['preferences'] as Map<String, dynamic>? ?? {};

    return UserProfile(
      uid: doc.id,
      name: data['name'] as String? ?? 'User',
      email: data['email'] as String? ?? 'No email',
      gender: Gender.values.firstWhere(
        (g) => g.toString() == 'Gender.${data['gender'] ?? 'male'}',
      ),
      profileImageUrl: data['profileImageUrl'] as String?,
      preferences: UserPreferences(
        // Handle missing preferences data
        preferredMoods:
            (prefsData['preferredMoods'] as List<dynamic>?)
                ?.map(
                  (m) => DateMood.values.firstWhere(
                    (mood) => mood.toString() == 'DateMood.$m',
                    orElse: () => DateMood.chill,
                  ),
                )
                .toList() ??
            [],
        preferredCategories:
            (prefsData['preferredCategories'] as List<dynamic>?)
                ?.map(
                  (c) => DateCategory.values.firstWhere(
                    (cat) => cat.toString() == 'DateCategory.$c',
                    orElse: () => DateCategory.restaurant,
                  ),
                )
                .toList() ??
            [],
        relationshipStage: RelationshipStage.values.firstWhere(
          (s) =>
              s.toString() ==
              'RelationshipStage.${prefsData['relationshipStage'] ?? 'firstDate'}',
          orElse: () => RelationshipStage.firstDate,
        ),
        dietaryRestrictions: prefsData['dietaryRestrictions'] as bool? ?? false,
        activityLevel: prefsData['activityLevel'] as int? ?? 5,
      ),
      location: data['location'] as GeoPoint?,
      city: data['city'] as String?,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      bio: data['bio'] as String?,
      jobTitle: data['jobTitle'] as String?,
      company: data['company'] as String?,
      education: data['education'] as String?,
    );
  }

  static List<DateMood> _parseMoods(List? moodStrings) {
    if (moodStrings == null) return [];
    return moodStrings
        .map(
          (m) => DateMood.values.firstWhere(
            (e) => e.toString() == m,
            orElse: () => DateMood.chill,
          ),
        )
        .toList();
  }

  static List<DateCategory> _parseCategories(List? categoryStrings) {
    if (categoryStrings == null) return [];
    return categoryStrings
        .map(
          (c) => DateCategory.values.firstWhere(
            (e) => e.toString() == c,
            orElse: () => DateCategory.restaurant,
          ),
        )
        .toList();
  }

  static RelationshipStage _parseRelationshipStage(String? value) {
    if (value == null) return RelationshipStage.firstDate;
    return RelationshipStage.values.firstWhere(
      (s) => s.toString() == value,
      orElse: () => RelationshipStage.firstDate,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'email': email,
      'profileImageUrl': profileImageUrl,
      'additionalImages': additionalImages,
      'age': age,
      'gender': gender.toString().split('.').last,
      'location': location,
      'preferences': preferences.toMap(),
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : null,
      'isVerified': isVerified,
      'interests': interests,
      'city': city,
      'bio': bio,
      'jobTitle': jobTitle,
      'company': company,
      'education': education,
    };
  }

  String? get imageUrl => profileImageUrl;

  factory UserProfile.fromMap(Map<String, dynamic> map, String uid) {
    try {
      // Handle additional images properly
      List<String> additionalImages = [];
      if (map['additionalImages'] != null) {
        additionalImages = List<String>.from(map['additionalImages']);
      }

      // Convert Timestamp to DateTime
      DateTime? createdAt;
      if (map['createdAt'] != null) {
        if (map['createdAt'] is Timestamp) {
          createdAt = (map['createdAt'] as Timestamp).toDate();
        } else if (map['createdAt'] is DateTime) {
          createdAt = map['createdAt'] as DateTime;
        }
      }

      return UserProfile(
        uid: uid,
        name: map['name'] ?? '',
        email: map['email'] ?? '',
        profileImageUrl: map['profileImageUrl'],
        additionalImages: additionalImages,
        age: map['age'],
        gender: Gender.values.firstWhere((g) => g.toString() == map['gender']),
        location: map['location'],
        preferences: _parsePreferences(map['preferences']),
        createdAt: createdAt,
        isVerified: map['isVerified'] ?? false,
        interests:
            map['interests'] != null ? List<String>.from(map['interests']) : [],
        city: map['city'],
        bio: map['bio'],
        jobTitle: map['jobTitle'],
        company: map['company'],
        education: map['education'],
      );
    } catch (e) {
      print('Error parsing UserProfile: $e');
      rethrow;
    }
  }

  static UserPreferences _parsePreferences(Map<String, dynamic>? prefsMap) {
    if (prefsMap == null) {
      return UserPreferences(
        preferredMoods: [],
        preferredCategories: [],
        relationshipStage: RelationshipStage.firstDate,
      );
    }

    // Parse preferred moods
    List<DateMood> moods = [];
    if (prefsMap['preferredMoods'] != null) {
      try {
        final moodsList = List<String>.from(prefsMap['preferredMoods']);
        for (var mood in moodsList) {
          try {
            moods.add(_parseDateMood(mood));
          } catch (e) {
            print('Error parsing mood $mood: $e');
          }
        }
      } catch (e) {
        print('Error parsing moods: $e');
      }
    }

    // Parse preferred categories
    List<DateCategory> categories = [];
    if (prefsMap['preferredCategories'] != null) {
      try {
        final categoriesList = List<String>.from(
          prefsMap['preferredCategories'],
        );
        for (var category in categoriesList) {
          try {
            categories.add(_parseDateCategory(category));
          } catch (e) {
            print('Error parsing category $category: $e');
          }
        }
      } catch (e) {
        print('Error parsing categories: $e');
      }
    }

    return UserPreferences(
      preferredMoods: moods,
      preferredCategories: categories,
      relationshipStage: _parseRelationshipStage(prefsMap['relationshipStage']),
      dietaryRestrictions: prefsMap['dietaryRestrictions'] ?? false,
      activityLevel: prefsMap['activityLevel'] ?? 5,
    );
  }

  static DateMood _parseDateMood(String? mood) {
    if (mood == null) return DateMood.chill;

    try {
      return DateMood.values.firstWhere(
        (e) => e.toString().split('.').last.toLowerCase() == mood.toLowerCase(),
        orElse: () => DateMood.chill,
      );
    } catch (e) {
      print('Error parsing mood: $e');
      return DateMood.chill;
    }
  }

  static DateCategory _parseDateCategory(String? category) {
    if (category == null) return DateCategory.restaurant;

    try {
      return DateCategory.values.firstWhere(
        (e) =>
            e.toString().split('.').last.toLowerCase() ==
            category.toLowerCase(),
        orElse: () => DateCategory.restaurant,
      );
    } catch (e) {
      print('Error parsing category: $e');
      return DateCategory.restaurant;
    }
  }

  static Gender _parseGender(String? genderStr) {
    if (genderStr == null) throw Exception('Gender is required');
    return Gender.values.firstWhere((g) => g.toString() == genderStr);
  }
}
