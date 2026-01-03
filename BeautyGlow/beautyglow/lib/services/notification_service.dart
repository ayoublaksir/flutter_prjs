import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'dart:io';

import '../data/storage_service.dart';
import '../models/notification_settings.dart';

/// 📝 TO CHANGE NOTIFICATION TIME:
/// Update `dailyReminderHour` and `dailyReminderMinute` constants below
/// Example: For 9:30 PM, set hour = 21, minute = 30
/// Example: For 6:00 AM, set hour = 6, minute = 0

class NotificationService {
  static final NotificationService _instance = NotificationService._();
  static NotificationService get instance => _instance;

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;

  // ⏰ NOTIFICATION REMINDER TIME CONFIGURATION
  // Change these values to update the daily notification time
  // TESTING: Set to current time + 2 minutes for testing
  static int get dailyReminderHour {
    final now = DateTime.now();
    final testTime = now.add(const Duration(minutes: 2));
    return testTime.hour;
  }

  static int get dailyReminderMinute {
    final now = DateTime.now();
    final testTime = now.add(const Duration(minutes: 2));
    return testTime.minute;
  }

  /// Get formatted time string for display (12-hour format)
  static String getFormattedReminderTime() {
    final hour = dailyReminderHour;
    final minute = dailyReminderMinute;

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

  // Notification IDs
  static const int _dailyReminderId = 1000;
  static const int _beautyTipReminderId = 1001;
  static const int _routineReminderId = 1002;
  static const int _productReminderId = 1003;

  NotificationService._();

  /// Initialize the notification service
  Future<void> init() async {
    if (_isInitialized) return;

    // Initialize timezone
    tz.initializeTimeZones();

    // Request permissions
    await _requestPermissions();

    // Configure notification settings
    await _configureNotifications();

    // Schedule default notifications
    await _scheduleDefaultNotifications();

    _isInitialized = true;
  }

  /// Request notification permissions
  Future<bool> _requestPermissions() async {
    if (Platform.isAndroid) {
      final androidPermission = await Permission.notification.request();
      return androidPermission.isGranted;
    } else if (Platform.isIOS) {
      final result = await _notifications
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(alert: true, badge: true, sound: true);
      return result ?? false;
    }
    return true;
  }

  /// Configure notification settings
  Future<void> _configureNotifications() async {
    // 💄 SOLUTION BEAUTY - Utilise le logo de l'app !
    // Logo BeautyGlow comme icône de notification (toujours disponible)
    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher', // Logo de l'app BeautyGlow
    );

    const iosSettings = DarwinInitializationSettings(
      requestSoundPermission: true,
      requestBadgePermission: true,
      requestAlertPermission: true,
    );

    final initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
      macOS: iosSettings,
    );

    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onDidReceiveNotificationResponse,
    );
  }

  /// Handle notification response (when user taps notification)
  Future<void> _onDidReceiveNotificationResponse(
    NotificationResponse response,
  ) async {
    final payload = response.payload;
    final now = DateTime.now();

    print('🔔🔔🔔🔔🔔🔔🔔🔔🔔🔔🔔🔔🔔🔔🔔🔔🔔🔔🔔🔔🔔🔔🔔🔔🔔🔔');
    print('🎉 SUCCESS! NOTIFICATION FIRED!');
    print('📱 Device time when notification fired: ${now.toString()}');
    print(
      '⏰ Notification fired at: ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}',
    );
    print('🎯 Target time was: ${getFormattedReminderTime()}');
    print('🆔 Notification ID: ${response.id}');
    print('📄 Payload: $payload');

    if (payload == 'daily_reminder') {
      print('✅ DAILY REMINDER NOTIFICATION WORKING PERFECTLY!');
      print(
        '🎊 The notification system successfully fired at the configured time!',
      );
    }
    print('🔔🔔🔔🔔🔔🔔🔔🔔🔔🔔🔔🔔🔔🔔🔔🔔🔔🔔🔔🔔🔔🔔🔔🔔🔔🔔');

    if (payload != null) {
      await _handleNotificationAction(payload);
    }
  }

  /// Handle notification actions
  Future<void> _handleNotificationAction(String payload) async {
    switch (payload) {
      case 'daily_reminder':
        print('💄 Daily reminder notification tapped - user engaged with app!');
        // Navigate to main screen or specific feature
        break;
      case 'beauty_tip':
        print('💡 Beauty tip notification tapped');
        // Navigate to tips screen
        break;
      case 'routine_reminder':
        print('🧴 Routine reminder notification tapped');
        // Navigate to routines screen
        break;
      case 'product_reminder':
        print('📦 Product reminder notification tapped');
        // Navigate to products screen
        break;
    }
  }

  /// Schedule daily notification (CORE FUNCTION)
  Future<void> _scheduleDailyNotification({
    required int id,
    required String title,
    required String body,
    required int hour,
    required int minute,
    required String payload,
  }) async {
    final deviceTime = DateTime.now();
    final now = tz.TZDateTime.now(tz.local);

    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    print('🕐 CURRENT DEVICE TIME: ${deviceTime.toString()}');
    print('🌍 TIMEZONE: ${tz.local.name}');
    print('⏰ TIMEZONE TIME: ${now.toString()}');
    print(
      '🎯 TARGET: ${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')} (${getFormattedReminderTime()})',
    );

    // Use device time for scheduling to avoid timezone issues
    var scheduledDate = tz.TZDateTime(
      tz.local,
      deviceTime.year,
      deviceTime.month,
      deviceTime.day,
      hour,
      minute,
    );

    // If the time has already passed today, schedule for tomorrow
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
      print('⏭️ Time passed today, scheduling for tomorrow');
    }

    final minutesUntil = scheduledDate.difference(now).inMinutes;
    final hoursUntil = minutesUntil / 60;

    print('📅 SCHEDULED DATE: ${scheduledDate.toString()}');
    print(
      '⏳ TIME UNTIL NOTIFICATION: ${hoursUntil.toStringAsFixed(1)} hours ($minutesUntil minutes)',
    );

    // Show if it's today or tomorrow
    if (scheduledDate.day == now.day) {
      print(
        '📌 NOTIFICATION WILL FIRE: TODAY at ${getFormattedReminderTime()}',
      );
    } else {
      print(
        '📌 NOTIFICATION WILL FIRE: TOMORROW at ${getFormattedReminderTime()}',
      );
    }
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

    // Schedule with inexact timing (Play Store compliant - no special permissions needed)
    try {
      await _notifications.zonedSchedule(
        id,
        title,
        body,
        scheduledDate,
        _notificationDetails(),
        payload: payload,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time,
      );
      print(
        '✅ Scheduled with APPROXIMATE timing - Play Store compliant, may have up to 15 minutes variance',
      );
    } catch (e) {
      print('❌ Failed to schedule notification: $e');
      rethrow;
    }
  }

  /// Get notification details
  NotificationDetails _notificationDetails() {
    const androidDetails = AndroidNotificationDetails(
      'beautyglow_channel',
      'BeautyGlow Notifications',
      channelDescription: 'Beauty routine reminders and tips notifications',
      importance: Importance.high,
      priority: Priority.high,
      // 💎 Icône BeautyGlow - logo de l'app dans les notifications
      // GARANTIE: ic_launcher existe TOUJOURS en production
      icon: '@mipmap/ic_launcher',
      enableVibration: true,
      enableLights: true,
      color: Color(0xFFFF69B4), // App primary color
      ledColor: Color(0xFFFF69B4),
      ledOnMs: 1000,
      ledOffMs: 500,
      playSound: true,
      styleInformation: BigTextStyleInformation(''),
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      sound: 'default',
      badgeNumber: 1,
    );

    return const NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
      macOS: iosDetails,
    );
  }

  /// Schedule a default daily reminder (MAIN FUNCTION)
  Future<void> scheduleDefaultDailyReminder({
    String title = 'BeautyGlow Daily Reminder 💄',
    String body =
        'Time to enhance your beauty routine! Discover new tips and maintain your glow',
    int? hour,
    int? minute,
  }) async {
    // PRODUCTION: Set to 7:00 PM (7 PM) - good time for US women when they're free
    final productionHour = 19; // 7 PM
    final productionMinute = 0; // 0 minutes

    // Use a specific ID for the default daily reminder
    const defaultDailyId = 2000;

    // Cancel existing default reminder
    await _notifications.cancel(defaultDailyId);

    // Log when scheduling the notification
    print('📅 SCHEDULING DAILY REMINDER at ${DateTime.now().toString()}');
    print(
      '   Target time: ${productionHour.toString().padLeft(2, '0')}:${productionMinute.toString().padLeft(2, '0')} (${productionHour}:${productionMinute.toString().padLeft(2, '0')})',
    );
    print('   Title: $title');
    print('⏰ PRODUCTION: Will show notification at 7:00 PM daily');

    // Schedule for 7:00 PM daily
    final now = tz.TZDateTime.now(tz.local);
    var scheduledDate = tz.TZDateTime(
      tz.local,
      DateTime.now().year,
      DateTime.now().month,
      DateTime.now().day,
      productionHour,
      productionMinute,
    );

    // If the time has already passed today, schedule for tomorrow
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
      print('⏭️ 7 PM has passed today, scheduling for tomorrow');
    }

    print('📅 SCHEDULED DATE: ${scheduledDate.toString()}');
    print('⏳ TIME UNTIL NOTIFICATION: Daily at 7:00 PM');
    print('📌 NOTIFICATION WILL FIRE: DAILY at 7:00 PM');
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

    // Schedule with inexact timing (Play Store compliant)
    try {
      await _notifications.zonedSchedule(
        defaultDailyId,
        title,
        body,
        scheduledDate,
        _notificationDetails(),
        payload: 'daily_reminder',
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      );
      print('✅ Scheduled with APPROXIMATE timing - Play Store compliant');
    } catch (e) {
      print('❌ Failed to schedule notification: $e');
      rethrow;
    }

    print(
      '✅ Daily reminder scheduled successfully for ${productionHour.toString().padLeft(2, '0')}:${productionMinute.toString().padLeft(2, '0')}',
    );

    // Verify the notification was scheduled
    await _showPendingNotifications();
  }

  /// Force schedule the default daily notification (called from main.dart)
  Future<void> setupDailyNotificationAlways() async {
    // Initialize timezone if not already done
    tz.initializeTimeZones();

    // Schedule the default notification regardless of user settings
    await scheduleDefaultDailyReminder(
      title: 'BeautyGlow Daily Reminder 💄',
      body: 'Discover new beauty tips and maintain your daily routine!',
    );
  }

  /// Show pending notifications (for debugging)
  Future<void> _showPendingNotifications() async {
    try {
      final pendingNotifications =
          await _notifications.pendingNotificationRequests();
      print('📋 PENDING NOTIFICATIONS: ${pendingNotifications.length}');
      for (final notification in pendingNotifications) {
        print('   ID: ${notification.id}, Title: ${notification.title}');
      }
    } catch (e) {
      print('❌ Error getting pending notifications: $e');
    }
  }

  /// Cancel all notifications
  Future<void> cancelAllNotifications() async {
    await _notifications.cancelAll();
    print('🗑️ All notifications cancelled');
  }

  /// Schedule default notifications
  Future<void> _scheduleDefaultNotifications() async {
    // Schedule the main daily reminder
    await scheduleDefaultDailyReminder();
  }

  /// Show test notification immediately
  Future<void> showTestNotification() async {
    await _notifications.show(
      9999,
      'BeautyGlow Test Notification 💄',
      'This is a test notification to verify the system is working!',
      _notificationDetails(),
      payload: 'test_notification',
    );
    print('🧪 Test notification sent');
  }

  /// Request notification permission (for UI screens)
  Future<bool> requestPermission() async {
    return await _requestPermissions();
  }

  /// Toggle routine reminder notifications
  Future<void> toggleRoutineReminder(bool enabled) async {
    if (enabled) {
      // Schedule routine reminder
      await _scheduleDailyNotification(
        id: _routineReminderId,
        title: 'BeautyGlow Routine Reminder 🧴',
        body: 'Time to follow your beauty routine!',
        hour: dailyReminderHour,
        minute: dailyReminderMinute,
        payload: 'routine_reminder',
      );
      print('✅ Routine reminder enabled');
    } else {
      // Cancel routine reminder
      await _notifications.cancel(_routineReminderId);
      print('❌ Routine reminder disabled');
    }
  }

  /// Get notification settings (for profile screen)
  Future<NotificationSettings> getSettings() async {
    // Return default settings for now
    return NotificationSettings(
      enabled: true,
      hour: dailyReminderHour,
      minute: dailyReminderMinute,
    );
  }

  /// Update notification time
  Future<void> updateNotificationTime(int hour, int minute) async {
    // Cancel existing notifications
    await _notifications.cancel(_dailyReminderId);
    await _notifications.cancel(_routineReminderId);
    await _notifications.cancel(_beautyTipReminderId);

    // Schedule new notifications with updated time
    await _scheduleDailyNotification(
      id: _dailyReminderId,
      title: 'BeautyGlow Daily Reminder 💄',
      body:
          'Time to enhance your beauty routine! Discover new tips and maintain your glow',
      hour: hour,
      minute: minute,
      payload: 'daily_reminder',
    );

    // Also update routine reminder
    await _scheduleDailyNotification(
      id: _routineReminderId,
      title: 'BeautyGlow Routine Reminder 🧴',
      body: 'Time to follow your beauty routine!',
      hour: hour,
      minute: minute,
      payload: 'routine_reminder',
    );

    print(
      '✅ Notification time updated to ${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}',
    );
  }
}
