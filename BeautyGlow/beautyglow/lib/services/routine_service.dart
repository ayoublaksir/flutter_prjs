import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

import '../models/routine.dart';
import 'routine_notification_service.dart';
import 'ads_service.dart';
import 'rewarded_ad_service.dart';

/// Service for managing beauty routines with notifications and ads integration
class RoutineService extends ChangeNotifier {
  static final RoutineService _instance = RoutineService._internal();
  factory RoutineService() => _instance;
  RoutineService._internal();

  // Hive box for storing routines
  static const String _routinesBoxName = 'routines';
  Box<Routine>? _routinesBox;

  // Service dependencies
  final RoutineNotificationService _notificationService =
      RoutineNotificationService.instance;
  final AdsService _adsService = AdsService();
  final RewardedAdService _rewardedAdService = RewardedAdService();

  // Cache for routines
  List<Routine> _routines = [];
  bool _isInitialized = false;

  /// Get all routines
  List<Routine> get routines => List.unmodifiable(_routines);

  /// Get active routines only
  List<Routine> get activeRoutines =>
      _routines.where((r) => r.isActive).toList();

  /// Get morning routines
  List<Routine> get morningRoutines =>
      _routines.where((r) => r.timeOfDay == 'morning' && r.isActive).toList();

  /// Get evening routines
  List<Routine> get eveningRoutines =>
      _routines.where((r) => r.timeOfDay == 'evening' && r.isActive).toList();

  /// Get routines with pending notifications
  List<Routine> get routinesWithNotifications => _routines
      .where((r) => r.isActive && r.isReminderEnabled && r.reminderTime != null)
      .toList();

  /// Initialize the routine service
  Future<void> init() async {
    if (_isInitialized) return;

    try {
      debugPrint('🔄 RoutineService: Initializing...');

      // Initialize Hive box
      _routinesBox = await Hive.openBox<Routine>(_routinesBoxName);

      // Load routines from storage
      await _loadRoutines();

      // Initialize notification service
      await _notificationService.init();

      // Initialize ads service
      await _adsService.init();

      // Schedule notifications for existing routines
      await _scheduleAllNotifications();

      _isInitialized = true;
      debugPrint(
          '✅ RoutineService: Initialized successfully with ${_routines.length} routines');
    } catch (e) {
      debugPrint('❌ RoutineService: Error initializing: $e');
    }
  }

  /// Load routines from Hive storage
  Future<void> _loadRoutines() async {
    if (_routinesBox == null) return;

    try {
      _routines = _routinesBox!.values.toList();

      // Reset daily completion status for new day
      final today = DateTime.now();
      for (final routine in _routines) {
        // This automatically handles daily reset in the model
        routine.resetDailyStatus();
      }

      debugPrint(
          '📂 RoutineService: Loaded ${_routines.length} routines from storage');
      notifyListeners();
    } catch (e) {
      debugPrint('❌ RoutineService: Error loading routines: $e');
      _routines = [];
    }
  }

  /// Create a new routine
  Future<Routine> createRoutine({
    required String name,
    required String timeOfDay,
    List<RoutineStep>? steps,
    TimeOfDay? reminderTime,
    bool isReminderEnabled = true,
    String? description,
  }) async {
    try {
      debugPrint('🔄 RoutineService: Starting createRoutine for "$name"');

      // Check if user can create routine (rewarded ad limits)
      if (!_rewardedAdService.canCreateRoutine) {
        debugPrint(
            '❌ RoutineService: Cannot create routine - daily limit reached');
        throw Exception(
            'Daily routine limit reached. Watch a rewarded ad to unlock more.');
      }

      // Track routine creation for rewarded ad limits
      _rewardedAdService.trackRoutineCreation();
      debugPrint('✅ RoutineService: Routine creation tracked');

      final routine = Routine.create(
        name: name,
        timeOfDay: timeOfDay,
        steps: steps,
        reminderTime: reminderTime,
        isReminderEnabled: isReminderEnabled,
      );

      if (description != null) {
        routine.description = description;
      }

      debugPrint('💾 RoutineService: Saving routine to Hive...');
      // Save to Hive
      await _routinesBox?.add(routine);
      debugPrint('✅ RoutineService: Routine saved to Hive box');

      _routines.add(routine);
      debugPrint(
          '✅ RoutineService: Routine added to cache (${_routines.length} total)');

      // Schedule notification if enabled
      if (routine.isReminderEnabled && routine.reminderTime != null) {
        await _notificationService.scheduleRoutineNotification(routine);
      }

      debugPrint('✅ RoutineService: Created routine "${routine.name}"');
      notifyListeners();

      // Note: Interstitial ad is shown by UI layer after successful creation
      return routine;
    } catch (e) {
      debugPrint('❌ RoutineService: Error creating routine: $e');
      rethrow;
    }
  }

  /// Update an existing routine
  Future<void> updateRoutine(Routine routine) async {
    try {
      // Save to Hive
      await routine.save();

      // Update cache
      final index = _routines.indexWhere((r) => r.id == routine.id);
      if (index != -1) {
        _routines[index] = routine;
      }

      // Update notification
      if (routine.isReminderEnabled && routine.reminderTime != null) {
        await _notificationService.scheduleRoutineNotification(routine);
      } else {
        await _notificationService.cancelRoutineNotification(routine.id);
      }

      debugPrint('✅ RoutineService: Updated routine "${routine.name}"');
      notifyListeners();

      // Show interstitial ad for routine save
      await _adsService.showInterstitialForRoutineSave();
    } catch (e) {
      debugPrint('❌ RoutineService: Error updating routine: $e');
    }
  }

  /// Delete a routine
  Future<void> deleteRoutine(String routineId) async {
    try {
      final routine = _routines.firstWhere((r) => r.id == routineId);

      // Cancel notification
      await _notificationService.cancelRoutineNotification(routineId);

      // Remove from Hive
      await routine.delete();

      // Remove from cache
      _routines.removeWhere((r) => r.id == routineId);

      debugPrint('🗑️ RoutineService: Deleted routine "${routine.name}"');
      notifyListeners();
    } catch (e) {
      debugPrint('❌ RoutineService: Error deleting routine: $e');
    }
  }

  /// Mark routine as completed for today
  Future<void> completeRoutine(String routineId) async {
    try {
      final routine = _routines.firstWhere((r) => r.id == routineId);

      if (routine.isCompletedForToday) {
        debugPrint(
            '⚠️ RoutineService: Routine "${routine.name}" already completed today');
        return;
      }

      // Track completion for ads
      _adsService.trackRoutineCompletion();

      // Mark as completed
      routine.markCompletedForToday();

      debugPrint(
          '✅ RoutineService: Completed routine "${routine.name}" for today');
      notifyListeners();

      // Show completion reminder for later verification
      await _notificationService.scheduleCompletionReminder(routine,
          delayMinutes: 30);

      // Show interstitial ad for routine completion
      await _adsService.showInterstitialForRoutineCompletion();
    } catch (e) {
      debugPrint('❌ RoutineService: Error completing routine: $e');
    }
  }

  /// Unmark routine completion for today (for corrections)
  Future<void> uncompleteRoutine(String routineId) async {
    try {
      final routine = _routines.firstWhere((r) => r.id == routineId);
      routine.unmarkCompletedForToday();

      debugPrint(
          '↩️ RoutineService: Unmarked completion for routine "${routine.name}"');
      notifyListeners();
    } catch (e) {
      debugPrint('❌ RoutineService: Error uncompleting routine: $e');
    }
  }

  /// Set reminder time for a routine
  Future<void> setRoutineReminderTime(String routineId, TimeOfDay time) async {
    try {
      final routine = _routines.firstWhere((r) => r.id == routineId);
      routine.setReminderTime(time);

      // Reschedule notification
      await _notificationService.scheduleRoutineNotification(routine);

      debugPrint(
          '⏰ RoutineService: Set reminder time for "${routine.name}" to ${routine.formattedReminderTime}');
      notifyListeners();
    } catch (e) {
      debugPrint('❌ RoutineService: Error setting reminder time: $e');
    }
  }

  /// Enable/disable routine reminder
  Future<void> setRoutineReminderEnabled(String routineId, bool enabled) async {
    try {
      final routine = _routines.firstWhere((r) => r.id == routineId);
      routine.setReminderEnabled(enabled);

      if (enabled && routine.reminderTime != null) {
        await _notificationService.scheduleRoutineNotification(routine);
      } else {
        await _notificationService.cancelRoutineNotification(routine.id);
      }

      debugPrint(
          '🔔 RoutineService: ${enabled ? 'Enabled' : 'Disabled'} reminder for "${routine.name}"');
      notifyListeners();
    } catch (e) {
      debugPrint('❌ RoutineService: Error setting reminder enabled: $e');
    }
  }

  /// Toggle routine active status
  Future<void> toggleRoutineActive(String routineId) async {
    try {
      final routine = _routines.firstWhere((r) => r.id == routineId);
      routine.isActive = !routine.isActive;
      await routine.save();

      if (routine.isActive &&
          routine.isReminderEnabled &&
          routine.reminderTime != null) {
        await _notificationService.scheduleRoutineNotification(routine);
      } else {
        await _notificationService.cancelRoutineNotification(routine.id);
      }

      debugPrint(
          '🔄 RoutineService: Toggled routine "${routine.name}" to ${routine.isActive ? 'active' : 'inactive'}');
      notifyListeners();
    } catch (e) {
      debugPrint('❌ RoutineService: Error toggling routine active: $e');
    }
  }

  /// Get routine by ID
  Routine? getRoutineById(String routineId) {
    try {
      return _routines.firstWhere((r) => r.id == routineId);
    } catch (e) {
      return null;
    }
  }

  /// Get routines completed today
  List<Routine> get routinesCompletedToday {
    return _routines.where((r) => r.isCompletedForToday).toList();
  }

  /// Get routines pending for today
  List<Routine> get routinesPendingToday {
    return _routines
        .where((r) => r.isActive && !r.isCompletedForToday)
        .toList();
  }

  /// Get completion rate for today
  double get todayCompletionRate {
    final activeRoutines = this.activeRoutines;
    if (activeRoutines.isEmpty) return 100.0;

    final completedCount =
        activeRoutines.where((r) => r.isCompletedForToday).length;
    return (completedCount / activeRoutines.length) * 100;
  }

  /// Schedule notifications for all routines
  Future<void> _scheduleAllNotifications() async {
    final routinesWithNotifications = this.routinesWithNotifications;
    await _notificationService
        .scheduleAllRoutineNotifications(routinesWithNotifications);
  }

  /// Reschedule all notifications (useful after app update or permission changes)
  Future<void> rescheduleAllNotifications() async {
    debugPrint('🔄 RoutineService: Rescheduling all notifications');
    await _notificationService.cancelAllRoutineNotifications();
    await _scheduleAllNotifications();
  }

  /// Handle notification action from system
  Future<void> handleNotificationAction(String action, String routineId) async {
    debugPrint(
        '🔔 RoutineService: Handling notification action "$action" for routine $routineId');

    switch (action) {
      case 'complete_routine':
        await completeRoutine(routineId);
        break;
      case 'snooze_routine':
        final routine = getRoutineById(routineId);
        if (routine != null) {
          await _notificationService.snoozeRoutineNotification(routine);
        }
        break;
      case 'skip_routine':
        // Mark as skipped (could be implemented as a status)
        debugPrint('⏭️ RoutineService: Skipped routine $routineId for today');
        break;
    }
  }

  /// Get statistics for analytics
  Map<String, dynamic> getStatistics() {
    final activeRoutines = this.activeRoutines;
    final completedToday = routinesCompletedToday.length;

    return {
      'total_routines': _routines.length,
      'active_routines': activeRoutines.length,
      'morning_routines': morningRoutines.length,
      'evening_routines': eveningRoutines.length,
      'completed_today': completedToday,
      'completion_rate_today': todayCompletionRate,
      'routines_with_notifications': routinesWithNotifications.length,
    };
  }

  /// Create demo routines for new users
  Future<void> createDemoRoutines() async {
    debugPrint('🎭 RoutineService: Creating demo routines');

    // Morning routine
    await createRoutine(
      name: 'Morning Skincare',
      timeOfDay: 'morning',
      reminderTime: const TimeOfDay(hour: 7, minute: 0),
      description: 'Start your day with healthy skin',
      steps: [
        RoutineStep.create(
          name: 'Gentle Cleanser',
          durationMinutes: 2,
          orderIndex: 0,
          description: 'Clean your face with a gentle cleanser',
        ),
        RoutineStep.create(
          name: 'Vitamin C Serum',
          durationMinutes: 1,
          orderIndex: 1,
          description: 'Apply vitamin C serum for protection',
        ),
        RoutineStep.create(
          name: 'Moisturizer & SPF',
          durationMinutes: 2,
          orderIndex: 2,
          description: 'Moisturize and protect with SPF',
        ),
      ],
    );

    // Evening routine
    await createRoutine(
      name: 'Evening Skincare',
      timeOfDay: 'evening',
      reminderTime: const TimeOfDay(hour: 21, minute: 0),
      description: 'Wind down with your evening routine',
      steps: [
        RoutineStep.create(
          name: 'Remove Makeup',
          durationMinutes: 3,
          orderIndex: 0,
          description: 'Gently remove all makeup',
        ),
        RoutineStep.create(
          name: 'Double Cleanse',
          durationMinutes: 3,
          orderIndex: 1,
          description: 'Deep clean with oil and water cleanser',
        ),
        RoutineStep.create(
          name: 'Night Treatment',
          durationMinutes: 2,
          orderIndex: 2,
          description: 'Apply retinol or night serum',
        ),
        RoutineStep.create(
          name: 'Night Moisturizer',
          durationMinutes: 1,
          orderIndex: 3,
          description: 'Lock in moisture overnight',
        ),
      ],
    );

    debugPrint('✅ RoutineService: Demo routines created');
  }

  /// Debug method to show routine statistics
  void debugPrintStatistics() {
    if (!kDebugMode) return;

    final stats = getStatistics();
    debugPrint('📊 RoutineService Statistics:');
    stats.forEach((key, value) {
      debugPrint('   $key: $value');
    });
  }

  /// Clear all routines (for development/testing)
  Future<void> clearAllRoutines() async {
    if (!kDebugMode) {
      debugPrint(
          '⚠️ RoutineService: clearAllRoutines only works in debug mode');
      return;
    }

    await _notificationService.cancelAllRoutineNotifications();
    await _routinesBox?.clear();
    _routines.clear();
    notifyListeners();

    debugPrint('🗑️ RoutineService: Cleared all routines');
  }
}
