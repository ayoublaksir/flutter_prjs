import 'package:hive/hive.dart';
import 'user_profile.dart';
import 'routine.dart';
import 'product.dart';
import 'achievement.dart';
import 'settings.dart';
import 'package:flutter/foundation.dart';

part 'beauty_data.g.dart';

/// Main container for all user beauty data
@HiveType(typeId: 0)
class BeautyData extends HiveObject {
  @HiveField(0)
  String userId;

  @HiveField(1)
  UserProfile userProfile;

  @HiveField(2)
  List<Routine> routines;

  @HiveField(3)
  List<Product> favoriteProducts;

  @HiveField(4)
  List<Achievement> achievements;

  @HiveField(5)
  int streakDays; // Persistent streak counter

  @HiveField(6)
  DateTime lastRoutineDate; // Last completion date

  @HiveField(7)
  Map<String, int> completionStats; // Monthly/weekly stats

  @HiveField(8)
  Settings settings;

  BeautyData({
    required this.userId,
    required this.userProfile,
    List<Routine>? routines,
    List<Product>? favoriteProducts,
    List<Achievement>? achievements,
    this.streakDays = 0,
    required this.lastRoutineDate,
    Map<String, int>? completionStats,
    Settings? settings,
  })  : routines = routines ?? [],
        favoriteProducts = favoriteProducts ?? [],
        achievements = achievements ?? [],
        completionStats = completionStats ?? {},
        settings = settings ?? Settings.defaultSettings();

  /// Create a new beauty data container
  factory BeautyData.create({required UserProfile userProfile}) {
    return BeautyData(
      userId: userProfile.id,
      userProfile: userProfile,
      routines: [],
      favoriteProducts: [],
      achievements: PredefinedAchievements.all,
      streakDays: 0,
      lastRoutineDate: DateTime.now().subtract(const Duration(days: 1)),
      completionStats: {},
      settings: Settings.defaultSettings(),
    );
  }

  /// Get active routines
  List<Routine> get activeRoutines {
    return routines.where((routine) => routine.isActive).toList();
  }

  /// Get morning routines
  List<Routine> get morningRoutines {
    return routines.where((routine) => routine.timeOfDay == 'morning').toList();
  }

  /// Get evening routines
  List<Routine> get eveningRoutines {
    return routines.where((routine) => routine.timeOfDay == 'evening').toList();
  }

  /// Get unlocked achievements
  List<Achievement> get unlockedAchievements {
    return achievements.where((achievement) => achievement.isUnlocked).toList();
  }

  /// Get locked achievements
  List<Achievement> get lockedAchievements {
    return achievements
        .where((achievement) => !achievement.isUnlocked)
        .toList();
  }

  /// Get achievement progress
  double get achievementProgress {
    if (achievements.isEmpty) return 0.0;
    return unlockedAchievements.length / achievements.length;
  }

  /// Get total routine completions
  int get totalCompletions {
    return routines.fold(0, (total, routine) => total + routine.completedCount);
  }

  /// Get favorite products by category
  Map<String, List<Product>> get productsByCategory {
    final Map<String, List<Product>> categoryMap = {};
    for (final product in favoriteProducts) {
      categoryMap.putIfAbsent(product.category, () => []).add(product);
    }
    return categoryMap;
  }

  /// Check and update achievements
  void checkAchievements() {
    try {
      // Ensure we're in a box before proceeding
      if (!isInBox) return;

      // Check consistency achievements
      final consistencyAchievements =
          achievements.where((a) => a.category == 'consistency');
      for (final achievement in consistencyAchievements) {
        switch (achievement.id) {
          case 'first_routine':
            if (totalCompletions >= 1) {
              achievement.updateProgress(1);
            }
            break;
          case 'week_streak':
            achievement.updateProgress(streakDays);
            break;
          case 'month_master':
            achievement.updateProgress(streakDays);
            break;
          case 'routine_royalty':
            achievement.updateProgress(totalCompletions);
            break;
        }
      }

      // Check collection achievements
      final collectionAchievements =
          achievements.where((a) => a.category == 'collection');
      for (final achievement in collectionAchievements) {
        switch (achievement.id) {
          case 'product_explorer':
          case 'beauty_collector':
            achievement.updateProgress(favoriteProducts.length);
            break;
          case 'brand_ambassador':
            final reviewedProducts =
                favoriteProducts.where((p) => p.hasReview).length;
            achievement.updateProgress(reviewedProducts);
            break;
        }
      }

      save();
    } catch (e) {
      debugPrint('Error checking achievements: $e');
    }
  }

  /// Update streak
  void updateStreak() {
    try {
      if (!isInBox) return;

      final now = DateTime.now();
      final daysSinceLastRoutine = now.difference(lastRoutineDate).inDays;

      if (daysSinceLastRoutine == 0) {
        // Already completed today
        return;
      } else if (daysSinceLastRoutine == 1) {
        // Consecutive day
        streakDays++;
      } else {
        // Streak broken
        streakDays = 1;
      }

      lastRoutineDate = now;
      save();
    } catch (e) {
      debugPrint('Error updating streak: $e');
    }
  }

  /// Add routine
  void addRoutine(Routine routine) {
    routines.add(routine);

    // Check routine creator achievement
    final routineCreator = achievements.firstWhere(
      (a) => a.id == 'routine_creator',
      orElse: () => achievements.first,
    );
    if (routineCreator.id == 'routine_creator') {
      routineCreator.updateProgress(1);
    }

    save();
  }

  /// Add product
  void addProduct(Product product) {
    favoriteProducts.add(product);
    checkAchievements();
    save();
  }

  /// Remove product
  void removeProduct(String productId) {
    favoriteProducts.removeWhere((p) => p.id == productId);
    checkAchievements();
    save();
  }

  /// Complete routine
  void completeRoutine(String routineId) {
    final routine = routines.firstWhere((r) => r.id == routineId);
    routine.completeRoutine();
    updateStreak();
    checkAchievements();
    save();
  }

  /// Copy with method for updating beauty data
  BeautyData copyWith({
    String? userId,
    UserProfile? userProfile,
    List<Routine>? routines,
    List<Product>? favoriteProducts,
    List<Achievement>? achievements,
    int? streakDays,
    DateTime? lastRoutineDate,
    Map<String, int>? completionStats,
    Settings? settings,
  }) {
    return BeautyData(
      userId: userId ?? this.userId,
      userProfile: userProfile ?? this.userProfile,
      routines: routines ?? this.routines,
      favoriteProducts: favoriteProducts ?? this.favoriteProducts,
      achievements: achievements ?? this.achievements,
      streakDays: streakDays ?? this.streakDays,
      lastRoutineDate: lastRoutineDate ?? this.lastRoutineDate,
      completionStats: completionStats ?? this.completionStats,
      settings: settings ?? this.settings,
    );
  }
}
