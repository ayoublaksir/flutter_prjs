import 'package:hive/hive.dart';
import 'package:flutter/foundation.dart';

part 'achievement.g.dart';

/// Achievement/badge model
@HiveType(typeId: 5)
class Achievement extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String title;

  @HiveField(2)
  String description;

  @HiveField(3)
  String icon; // Icon path or identifier

  @HiveField(4)
  bool isUnlocked; // Achievement status

  @HiveField(5)
  DateTime? unlockedDate; // When earned

  @HiveField(6)
  String category; // 'consistency', 'collection', 'engagement'

  @HiveField(7)
  int progress; // Progress toward goal

  @HiveField(8)
  int target; // Goal target

  Achievement({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    this.isUnlocked = false,
    this.unlockedDate,
    required this.category,
    this.progress = 0,
    required this.target,
  });

  /// Create a new achievement
  factory Achievement.create({
    required String id,
    required String title,
    required String description,
    required String icon,
    required String category,
    required int target,
  }) {
    return Achievement(
      id: id,
      title: title,
      description: description,
      icon: icon,
      isUnlocked: false,
      unlockedDate: null,
      category: category,
      progress: 0,
      target: target,
    );
  }

  /// Copy with method
  Achievement copyWith({
    String? title,
    String? description,
    String? icon,
    bool? isUnlocked,
    DateTime? unlockedDate,
    String? category,
    int? progress,
    int? target,
  }) {
    return Achievement(
      id: id,
      title: title ?? this.title,
      description: description ?? this.description,
      icon: icon ?? this.icon,
      isUnlocked: isUnlocked ?? this.isUnlocked,
      unlockedDate: unlockedDate ?? this.unlockedDate,
      category: category ?? this.category,
      progress: progress ?? this.progress,
      target: target ?? this.target,
    );
  }

  /// Get progress percentage
  double get progressPercentage {
    if (target <= 0) return 0.0;
    return (progress / target).clamp(0.0, 1.0);
  }

  /// Get formatted progress
  String get formattedProgress {
    return '$progress / $target';
  }

  /// Check if achievement can be unlocked
  bool get canUnlock => progress >= target && !isUnlocked;

  /// Unlock achievement
  void unlock() {
    try {
      if (canUnlock) {
        isUnlocked = true;
        unlockedDate = DateTime.now();
        if (isInBox) {
          save();
        }
      }
    } catch (e) {
      debugPrint('Error unlocking achievement: $e');
    }
  }

  /// Update progress
  void updateProgress(int newProgress) {
    try {
      progress = newProgress.clamp(0, target);
      if (canUnlock) {
        unlock();
      } else if (isInBox) {
        save();
      }
    } catch (e) {
      debugPrint('Error updating achievement progress: $e');
    }
  }

  /// Get category display name
  String get categoryDisplayName {
    switch (category.toLowerCase()) {
      case 'consistency':
        return 'Consistency';
      case 'collection':
        return 'Collection';
      case 'engagement':
        return 'Engagement';
      default:
        return category;
    }
  }

  /// Get achievement tier based on target
  String get tier {
    if (category == 'consistency') {
      if (target <= 7) return 'Bronze';
      if (target <= 30) return 'Silver';
      if (target <= 100) return 'Gold';
      return 'Platinum';
    } else if (category == 'collection') {
      if (target <= 5) return 'Bronze';
      if (target <= 25) return 'Silver';
      if (target <= 50) return 'Gold';
      return 'Platinum';
    } else {
      if (target <= 10) return 'Bronze';
      if (target <= 50) return 'Silver';
      if (target <= 100) return 'Gold';
      return 'Platinum';
    }
  }
}

/// Predefined achievements
class PredefinedAchievements {
  static List<Achievement> get all => [
        // Consistency Achievements
        Achievement.create(
          id: 'first_routine',
          title: 'First Steps 👶',
          description: 'Complete your first beauty routine',
          icon: 'badge_first_routine',
          category: 'consistency',
          target: 1,
        ),
        Achievement.create(
          id: 'week_streak',
          title: 'Week Warrior 🔥',
          description: 'Complete routines for 7 consecutive days',
          icon: 'badge_week_streak',
          category: 'consistency',
          target: 7,
        ),
        Achievement.create(
          id: 'month_master',
          title: 'Month Master 👑',
          description: 'Complete routines for 30 consecutive days',
          icon: 'badge_month_master',
          category: 'consistency',
          target: 30,
        ),
        Achievement.create(
          id: 'routine_royalty',
          title: 'Routine Royalty 💎',
          description: 'Complete 100 routines in total',
          icon: 'badge_routine_royalty',
          category: 'consistency',
          target: 100,
        ),

        // Collection Achievements
        Achievement.create(
          id: 'product_explorer',
          title: 'Product Explorer 🛍️',
          description: 'Add 5 products to your collection',
          icon: 'badge_product_explorer',
          category: 'collection',
          target: 5,
        ),
        Achievement.create(
          id: 'beauty_collector',
          title: 'Beauty Collector 💄',
          description: 'Add 25 products to your collection',
          icon: 'badge_product_collector',
          category: 'collection',
          target: 25,
        ),
        Achievement.create(
          id: 'brand_ambassador',
          title: 'Brand Ambassador ✨',
          description: 'Rate and review 10 products',
          icon: 'badge_brand_ambassador',
          category: 'collection',
          target: 10,
        ),

        // Engagement Achievements
        Achievement.create(
          id: 'tip_reader',
          title: 'Tip Reader 📚',
          description: 'Read 10 beauty tips',
          icon: 'badge_tip_reader',
          category: 'engagement',
          target: 10,
        ),
        Achievement.create(
          id: 'beauty_guru',
          title: 'Beauty Guru 🧠',
          description: 'Read 50 beauty tips',
          icon: 'badge_beauty_guru',
          category: 'engagement',
          target: 50,
        ),
        Achievement.create(
          id: 'routine_creator',
          title: 'Routine Creator 🎨',
          description: 'Create a custom beauty routine',
          icon: 'badge_routine_creator',
          category: 'engagement',
          target: 1,
        ),
      ];
}
