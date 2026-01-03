import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;

import '../models/routine.dart';
import 'notification_service.dart';

/// Service for managing routine-specific daily notifications
class RoutineNotificationService {
  static final RoutineNotificationService _instance =
      RoutineNotificationService._internal();
  static RoutineNotificationService get instance => _instance;

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();
  final NotificationService _baseNotificationService =
      NotificationService.instance;

  // Notification ID base for routines (start from 2000 to avoid conflicts)
  static const int _routineNotificationIdBase = 2000;

  RoutineNotificationService._internal();

  /// Initialize routine notification service
  Future<void> init() async {
    // Ensure base notification service is initialized
    await _baseNotificationService.init();

    // Initialize timezone data
    tz.initializeTimeZones();

    debugPrint('✅ RoutineNotificationService: Initialized successfully');
  }

  /// Schedule daily notification for a routine
  Future<void> scheduleRoutineNotification(Routine routine) async {
    if (!routine.isReminderEnabled || routine.reminderTime == null) {
      debugPrint(
          '⚠️ RoutineNotificationService: Routine ${routine.name} has reminders disabled or no time set');
      return;
    }

    try {
      final notificationId = _getNotificationId(routine.id);

      // Cancel existing notification for this routine
      await cancelRoutineNotification(routine.id);

      final reminderTime = routine.reminderTime!;
      final now = tz.TZDateTime.now(tz.local);

      // Calculate next notification time
      var scheduledDate = tz.TZDateTime(
        tz.local,
        now.year,
        now.month,
        now.day,
        reminderTime.hour,
        reminderTime.minute,
      );

      // If the time has already passed today, schedule for tomorrow
      if (scheduledDate.isBefore(now)) {
        scheduledDate = scheduledDate.add(const Duration(days: 1));
      }

      debugPrint(
          '📅 RoutineNotificationService: Scheduling notification for ${routine.name} at ${routine.formattedReminderTime}');
      debugPrint('📅 Next notification: ${scheduledDate.toString()}');

      await _notifications.zonedSchedule(
        notificationId,
        '⏰ Time for your ${routine.timeOfDay} routine!',
        '${routine.name} - ${routine.formattedDuration}',
        scheduledDate,
        NotificationDetails(
          android: AndroidNotificationDetails(
            'routine_reminders',
            'Routine Reminders',
            channelDescription: 'Daily reminders for your beauty routines',
            importance: Importance.high,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher', // 💄 Logo BeautyGlow
            enableVibration: true,
            playSound: true,
            actions: [
              AndroidNotificationAction(
                'complete_routine',
                'Mark Complete',
                showsUserInterface: true,
              ),
              AndroidNotificationAction(
                'snooze_routine',
                'Snooze 15min',
                showsUserInterface: false,
              ),
            ],
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
            categoryIdentifier: 'routine_reminder',
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time, // Repeat daily

        payload: 'routine_${routine.id}',
      );

      debugPrint(
          '✅ RoutineNotificationService: Scheduled daily notification for ${routine.name}');
    } catch (e) {
      debugPrint(
          '❌ RoutineNotificationService: Error scheduling notification for ${routine.name}: $e');
    }
  }

  /// Schedule notifications for multiple routines
  Future<void> scheduleAllRoutineNotifications(List<Routine> routines) async {
    debugPrint(
        '📅 RoutineNotificationService: Scheduling notifications for ${routines.length} routines');

    for (final routine in routines) {
      if (routine.isActive &&
          routine.isReminderEnabled &&
          routine.reminderTime != null) {
        await scheduleRoutineNotification(routine);
      }
    }

    debugPrint(
        '✅ RoutineNotificationService: Finished scheduling all routine notifications');
  }

  /// Cancel notification for a specific routine
  Future<void> cancelRoutineNotification(String routineId) async {
    try {
      final notificationId = _getNotificationId(routineId);
      await _notifications.cancel(notificationId);
      debugPrint(
          '🗑️ RoutineNotificationService: Cancelled notification for routine $routineId');
    } catch (e) {
      debugPrint(
          '❌ RoutineNotificationService: Error cancelling notification for routine $routineId: $e');
    }
  }

  /// Cancel all routine notifications
  Future<void> cancelAllRoutineNotifications() async {
    try {
      // Get all pending notifications
      final pendingNotifications =
          await _notifications.pendingNotificationRequests();

      // Cancel only routine notifications (IDs >= 2000)
      for (final notification in pendingNotifications) {
        if (notification.id >= _routineNotificationIdBase) {
          await _notifications.cancel(notification.id);
        }
      }

      debugPrint(
          '🗑️ RoutineNotificationService: Cancelled all routine notifications');
    } catch (e) {
      debugPrint(
          '❌ RoutineNotificationService: Error cancelling all routine notifications: $e');
    }
  }

  /// Update notification for a routine (cancel old and schedule new)
  Future<void> updateRoutineNotification(Routine routine) async {
    debugPrint(
        '🔄 RoutineNotificationService: Updating notification for ${routine.name}');
    await scheduleRoutineNotification(routine);
  }

  /// Schedule immediate notification for routine completion reminder
  Future<void> scheduleCompletionReminder(Routine routine,
      {int delayMinutes = 15}) async {
    try {
      final notificationId = _getNotificationId('${routine.id}_completion');
      final now = tz.TZDateTime.now(tz.local);
      final scheduledTime = now.add(Duration(minutes: delayMinutes));

      await _notifications.zonedSchedule(
        notificationId,
        '💪 Did you complete your routine?',
        '${routine.name} - Tap to mark as complete',
        scheduledTime,
        NotificationDetails(
          android: AndroidNotificationDetails(
            'routine_completion',
            'Routine Completion',
            channelDescription: 'Reminders to mark routines as complete',
            importance: Importance.defaultImportance,
            priority: Priority.defaultPriority,
            icon: '@mipmap/ic_launcher', // 💄 Logo BeautyGlow
            actions: [
              AndroidNotificationAction(
                'complete_routine',
                'Mark Complete',
                showsUserInterface: true,
              ),
              AndroidNotificationAction(
                'skip_routine',
                'Skip Today',
                showsUserInterface: false,
              ),
            ],
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
            categoryIdentifier: 'routine_completion',
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        payload: 'routine_completion_${routine.id}',
      );

      debugPrint(
          '✅ RoutineNotificationService: Scheduled completion reminder for ${routine.name} in $delayMinutes minutes');
    } catch (e) {
      debugPrint(
          '❌ RoutineNotificationService: Error scheduling completion reminder: $e');
    }
  }

  /// Schedule a snooze notification (15 minutes later)
  Future<void> snoozeRoutineNotification(Routine routine) async {
    try {
      final notificationId = _getNotificationId('${routine.id}_snooze');
      final now = tz.TZDateTime.now(tz.local);
      final snoozeTime = now.add(const Duration(minutes: 15));

      await _notifications.zonedSchedule(
        notificationId,
        '⏰ Routine reminder (snoozed)',
        '${routine.name} - Ready to start your routine?',
        snoozeTime,
        NotificationDetails(
          android: AndroidNotificationDetails(
            'routine_snooze',
            'Routine Snooze',
            channelDescription: 'Snoozed routine reminders',
            importance: Importance.high,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher', // 💄 Logo BeautyGlow
            actions: [
              AndroidNotificationAction(
                'complete_routine',
                'Mark Complete',
                showsUserInterface: true,
              ),
              AndroidNotificationAction(
                'snooze_routine',
                'Snooze Again',
                showsUserInterface: false,
              ),
            ],
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
            categoryIdentifier: 'routine_snooze',
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        payload: 'routine_snooze_${routine.id}',
      );

      debugPrint(
          '✅ RoutineNotificationService: Scheduled snooze notification for ${routine.name}');
    } catch (e) {
      debugPrint(
          '❌ RoutineNotificationService: Error scheduling snooze notification: $e');
    }
  }

  /// Get list of all pending routine notifications
  Future<List<PendingNotificationRequest>>
      getPendingRoutineNotifications() async {
    try {
      final allPending = await _notifications.pendingNotificationRequests();
      return allPending
          .where(
              (notification) => notification.id >= _routineNotificationIdBase)
          .toList();
    } catch (e) {
      debugPrint(
          '❌ RoutineNotificationService: Error getting pending notifications: $e');
      return [];
    }
  }

  /// Handle notification action (for notification callbacks)
  Future<void> handleNotificationAction(String action, String routineId) async {
    debugPrint(
        '🔔 RoutineNotificationService: Handling action "$action" for routine $routineId');

    switch (action) {
      case 'complete_routine':
        // This should be handled by the UI/service that manages routines
        debugPrint('✅ Action: Mark routine $routineId as complete');
        break;
      case 'snooze_routine':
        // Find and snooze the routine (this would need routine data)
        debugPrint('😴 Action: Snooze routine $routineId');
        break;
      case 'skip_routine':
        debugPrint('⏭️ Action: Skip routine $routineId for today');
        break;
    }
  }

  /// Generate unique notification ID for routine
  int _getNotificationId(String identifier) {
    // Use hash code to generate consistent ID for the same identifier
    final hash = identifier.hashCode.abs();
    // Ensure it's within reasonable range and doesn't conflict with base notifications
    return _routineNotificationIdBase + (hash % 8000);
  }

  /// Get next notification time for a routine
  DateTime? getNextNotificationTime(Routine routine) {
    if (!routine.isReminderEnabled || routine.reminderTime == null) {
      return null;
    }

    final reminderTime = routine.reminderTime!;
    final now = DateTime.now();

    var nextNotification = DateTime(
      now.year,
      now.month,
      now.day,
      reminderTime.hour,
      reminderTime.minute,
    );

    // If the time has already passed today, schedule for tomorrow
    if (nextNotification.isBefore(now)) {
      nextNotification = nextNotification.add(const Duration(days: 1));
    }

    return nextNotification;
  }

  /// Check if routine has pending notification
  Future<bool> hasPermissions() async {
    // Check notification permissions via base service
    try {
      await _baseNotificationService.init();
      return true;
    } catch (e) {
      debugPrint('❌ RoutineNotificationService: Permission check failed: $e');
      return false;
    }
  }

  /// Debug method to show all pending routine notifications
  Future<void> debugPendingNotifications() async {
    if (!kDebugMode) return;

    final pending = await getPendingRoutineNotifications();
    debugPrint(
        '📋 RoutineNotificationService: ${pending.length} pending routine notifications:');

    for (final notification in pending) {
      debugPrint(
          '  - ID: ${notification.id}, Title: ${notification.title}, Body: ${notification.body}');
    }
  }
}
