import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/date_mood.dart';
import '../models/date_category.dart';
import '../models/relationship_stage.dart';
import '../models/gender.dart';

// Date Idea Model
class DateIdea {
  final String id;
  final String name;
  final String description;
  final DateCategory category;
  final DateMood mood;
  final List<RelationshipStage> suitableStages;
  final double averageCost;
  final String imageUrl;
  final List<String> conversationTopics;
  final List<String> prepTips;
  final List<String> locationDetails;

  DateIdea({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    required this.mood,
    required this.suitableStages,
    required this.averageCost,
    required this.imageUrl,
    required this.conversationTopics,
    required this.prepTips,
    this.locationDetails = const [],
  });
}

// User Preferences Model
class UserPreferences {
  final List<DateMood> preferredMoods;
  final List<DateCategory> preferredCategories;
  final RelationshipStage relationshipStage;
  final bool? dietaryRestrictions;
  final int? activityLevel;

  UserPreferences({
    required this.preferredMoods,
    required this.preferredCategories,
    required this.relationshipStage,
    this.dietaryRestrictions,
    this.activityLevel,
  });

  // Add a toMap method for serialization
  Map<String, dynamic> toMap() {
    return {
      'preferredMoods':
          preferredMoods.map((m) => m.toString().split('.').last).toList(),
      'preferredCategories':
          preferredCategories.map((c) => c.toString().split('.').last).toList(),
      'relationshipStage': relationshipStage.toString().split('.').last,
      'dietaryRestrictions': dietaryRestrictions,
      'activityLevel': activityLevel,
    };
  }

  // Add a fromMap constructor
  factory UserPreferences.fromMap(Map<String, dynamic> map) {
    return UserPreferences(
      preferredMoods:
          ((map['preferredMoods'] ?? []) as List)
              .map(
                (m) => DateMood.values.firstWhere(
                  (e) => e.toString().split('.').last == m,
                  orElse: () => DateMood.chill,
                ),
              )
              .toList(),
      preferredCategories:
          ((map['preferredCategories'] ?? []) as List)
              .map(
                (c) => DateCategory.values.firstWhere(
                  (e) => e.toString().split('.').last == c,
                  orElse: () => DateCategory.restaurant,
                ),
              )
              .toList(),
      relationshipStage: RelationshipStage.values.firstWhere(
        (s) => s.toString().split('.').last == (map['relationshipStage'] ?? ''),
        orElse: () => RelationshipStage.firstDate,
      ),
      dietaryRestrictions: map['dietaryRestrictions'],
      activityLevel: map['activityLevel'],
    );
  }
}

enum DateOfferStatus {
  active, // Initial state, visible to potential matches
  pending, // Has responders but no accepted match yet
  matched, // Successfully matched with a responder
  declined, // Response was declined
  expired, // Past the date/time or manually expired
}

enum ResponderStatus { pending, accepted, declined }
