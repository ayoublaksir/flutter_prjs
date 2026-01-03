import 'package:hive/hive.dart';
import 'package:flutter/material.dart';

part 'routine.g.dart';

/// Daily routine model
@HiveType(typeId: 3)
class Routine extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String name;

  @HiveField(2)
  String timeOfDay; // 'morning' or 'evening'

  @HiveField(3)
  List<RoutineStep> steps;

  @HiveField(4)
  bool isActive;

  @HiveField(5)
  DateTime createdDate;

  @HiveField(6)
  int completedCount; // Total completions

  @HiveField(7)
  List<DateTime> completionHistory; // Date stamps

  @HiveField(8)
  String? description;

  @HiveField(9)
  DateTime? lastCompletedDate;

  @HiveField(10)
  TimeOfDay? reminderTime; // Specific time for daily notifications

  @HiveField(11)
  bool isReminderEnabled; // Enable/disable reminder notifications

  @HiveField(12)
  Map<String, bool>
      dailyCompletionStatus; // Track completion per day (key: date string)

  Routine({
    required this.id,
    required this.name,
    required this.timeOfDay,
    List<RoutineStep>? steps,
    this.isActive = true,
    required this.createdDate,
    this.completedCount = 0,
    List<DateTime>? completionHistory,
    this.description,
    this.lastCompletedDate,
    this.reminderTime,
    this.isReminderEnabled = true,
    Map<String, bool>? dailyCompletionStatus,
  })  : steps = steps ?? [],
        completionHistory = completionHistory ?? [],
        dailyCompletionStatus = dailyCompletionStatus ?? {};

  /// Create a new routine
  factory Routine.create({
    required String name,
    required String timeOfDay,
    List<RoutineStep>? steps,
    bool isActive = true,
    TimeOfDay? reminderTime,
    bool isReminderEnabled = true,
  }) {
    return Routine(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      timeOfDay: timeOfDay,
      steps: steps,
      isActive: isActive,
      createdDate: DateTime.now(),
      completedCount: 0,
      completionHistory: [],
      description: null,
      lastCompletedDate: null,
      reminderTime: reminderTime,
      isReminderEnabled: isReminderEnabled,
      dailyCompletionStatus: {},
    );
  }

  /// Copy with method
  Routine copyWith({
    String? name,
    String? timeOfDay,
    List<RoutineStep>? steps,
    bool? isActive,
    int? completedCount,
    List<DateTime>? completionHistory,
    String? description,
    DateTime? lastCompletedDate,
    TimeOfDay? reminderTime,
    bool? isReminderEnabled,
    Map<String, bool>? dailyCompletionStatus,
  }) {
    return Routine(
      id: id,
      name: name ?? this.name,
      timeOfDay: timeOfDay ?? this.timeOfDay,
      steps: steps ?? this.steps,
      isActive: isActive ?? this.isActive,
      createdDate: createdDate,
      completedCount: completedCount ?? this.completedCount,
      completionHistory: completionHistory ?? this.completionHistory,
      description: description ?? this.description,
      lastCompletedDate: lastCompletedDate ?? this.lastCompletedDate,
      reminderTime: reminderTime ?? this.reminderTime,
      isReminderEnabled: isReminderEnabled ?? this.isReminderEnabled,
      dailyCompletionStatus:
          dailyCompletionStatus ?? this.dailyCompletionStatus,
    );
  }

  /// Get estimated duration in minutes
  int get estimatedDuration {
    return steps.fold(0, (total, step) => total + step.durationMinutes);
  }

  /// Get formatted duration
  String get formattedDuration {
    final duration = estimatedDuration;
    if (duration < 60) {
      return '$duration min';
    } else {
      final hours = duration ~/ 60;
      final minutes = duration % 60;
      return minutes > 0 ? '${hours}h ${minutes}m' : '${hours}h';
    }
  }

  /// Check if routine was completed today
  bool get isCompletedToday {
    if (completionHistory.isEmpty) return false;
    final lastCompletion = completionHistory.last;
    final today = DateTime.now();
    return lastCompletion.year == today.year &&
        lastCompletion.month == today.month &&
        lastCompletion.day == today.day;
  }

  /// Get last completion date
  DateTime? get lastCompletionDate {
    return completionHistory.isNotEmpty ? completionHistory.last : null;
  }

  /// Get completion rate (percentage)
  double getCompletionRate(int daysToConsider) {
    if (daysToConsider <= 0) return 0.0;

    final startDate = DateTime.now().subtract(Duration(days: daysToConsider));
    final completionsInPeriod = completionHistory.where((date) {
      return date.isAfter(startDate);
    }).length;

    return (completionsInPeriod / daysToConsider) * 100;
  }

  /// Complete routine
  void completeRoutine() {
    completedCount++;
    completionHistory.add(DateTime.now());

    // Mark as completed for today
    final today = _getTodayString();
    dailyCompletionStatus[today] = true;

    save();
  }

  /// Get today's date as string key
  String _getTodayString() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  /// Check if routine is completed for today
  bool get isCompletedForToday {
    final today = _getTodayString();
    return dailyCompletionStatus[today] ?? false;
  }

  /// Check if routine is completed for a specific date
  bool isCompletedForDate(DateTime date) {
    final dateString =
        '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    return dailyCompletionStatus[dateString] ?? false;
  }

  /// Mark routine as completed for today
  void markCompletedForToday() {
    final today = _getTodayString();
    dailyCompletionStatus[today] = true;
    completedCount++;
    completionHistory.add(DateTime.now());
    save();
  }

  /// Unmark routine completion for today (for testing/correction)
  void unmarkCompletedForToday() {
    final today = _getTodayString();
    dailyCompletionStatus[today] = false;
    save();
  }

  /// Get formatted reminder time string
  String get formattedReminderTime {
    if (reminderTime == null) return 'Not set';

    final hour = reminderTime!.hour;
    final minute = reminderTime!.minute;

    if (hour == 0) {
      return '12:${minute.toString().padLeft(2, '0')} AM';
    } else if (hour < 12) {
      return '$hour:${minute.toString().padLeft(2, '0')} AM';
    } else if (hour == 12) {
      return '12:${minute.toString().padLeft(2, '0')} PM';
    } else {
      return '${hour - 12}:${minute.toString().padLeft(2, '0')} PM';
    }
  }

  /// Set reminder time
  void setReminderTime(TimeOfDay time) {
    reminderTime = time;
    save();
  }

  /// Enable/disable reminder notifications
  void setReminderEnabled(bool enabled) {
    isReminderEnabled = enabled;
    save();
  }

  /// Reset daily completion status for new day (called by service)
  void resetDailyStatus() {
    // This is automatically handled by checking date in isCompletedForToday
    // No action needed - keeps historical data
  }
}

/// Routine step model
@HiveType(typeId: 4)
class RoutineStep {
  @HiveField(0)
  String id;

  @HiveField(1)
  String name;

  @HiveField(2)
  String? description;

  @HiveField(3)
  int durationMinutes;

  @HiveField(4)
  String? productId; // Optional linked product

  @HiveField(5)
  String? iconPath;

  @HiveField(6)
  int orderIndex;

  @HiveField(7)
  String? productName;

  RoutineStep({
    required this.id,
    required this.name,
    this.description,
    required this.durationMinutes,
    this.productId,
    this.iconPath,
    required this.orderIndex,
    this.productName,
  });

  /// Create a new routine step
  factory RoutineStep.create({
    required String name,
    String? description,
    required int durationMinutes,
    String? productId,
    String? iconPath,
    required int orderIndex,
  }) {
    return RoutineStep(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      description: description,
      durationMinutes: durationMinutes,
      productId: productId,
      iconPath: iconPath,
      orderIndex: orderIndex,
      productName: null,
    );
  }

  /// Copy with method
  RoutineStep copyWith({
    String? name,
    String? description,
    int? durationMinutes,
    String? productId,
    String? iconPath,
    int? orderIndex,
    String? productName,
  }) {
    return RoutineStep(
      id: id,
      name: name ?? this.name,
      description: description ?? this.description,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      productId: productId ?? this.productId,
      iconPath: iconPath ?? this.iconPath,
      orderIndex: orderIndex ?? this.orderIndex,
      productName: productName ?? this.productName,
    );
  }

  /// Getter for compatibility
  int get duration => durationMinutes;
}
