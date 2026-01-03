import 'package:dating_app/models/relationship_stage.dart';
import 'package:dating_app/models/date_category.dart';
import 'package:dating_app/models/date_mood.dart';

class UserPreferences {
  final RelationshipStage relationshipStage;
  final double budget;
  final List<DateCategory> preferredCategories;
  final List<DateMood> preferredMoods;
  final bool? dietaryRestrictions;
  final int? activityLevel;

  UserPreferences({
    required this.relationshipStage,
    required this.budget,
    required this.preferredCategories,
    required this.preferredMoods,
    this.dietaryRestrictions,
    this.activityLevel,
  });
}
