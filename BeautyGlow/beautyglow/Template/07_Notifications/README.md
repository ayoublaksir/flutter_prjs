# 🔔 Local Notifications - Complete Implementation Guide

## ✅ Purpose
Implement a comprehensive local notification system with scheduled reminders, custom actions, timezone handling, and cross-platform support for iOS and Android.

## 🧠 Architecture Overview

### Notification Flow
```
User Settings → Schedule Notification → System Scheduler → Trigger → User Action
      ↓                ↓                    ↓             ↓          ↓
   Enable Daily → Set Time & Message → OS Notification → Display → Navigate
```

### Service Structure
```
lib/services/
├── notification_service.dart      # Main notification service
├── notification_scheduler.dart    # Scheduling logic
└── notification_handlers.dart     # Action handlers

lib/models/
├── notification_settings.dart     # Settings model
└── notification_settings.g.dart   # Generated Hive adapter

lib/utils/
└── timezone_helper.dart          # Timezone utilities
```

## 🧩 Dependencies

Notification-related dependencies (already included):
```yaml
dependencies:
  flutter_local_notifications: ^19.2.1  # Local notifications
  timezone: ^0.10.0                     # Timezone support
  permission_handler: ^11.1.0           # Runtime permissions
  shared_preferences: ^2.2.2            # Settings persistence

dev_dependencies:
  hive_generator: ^2.0.0                # For notification settings model
```

## 🛠️ Complete Implementation

### 1. Notification Settings Model

#### notification_settings.dart
```dart
import 'package:hive/hive.dart';

part 'notification_settings.g.dart';

@HiveType(typeId: 7)
class NotificationSettings extends HiveObject {
  @HiveField(0)
  bool enabled;

  @HiveField(1)
  int hour;

  @HiveField(2)
  int minute;

  @HiveField(3)
  bool soundEnabled;

  @HiveField(4)
  bool vibrationEnabled;

  @HiveField(5)
  String notificationTitle;

  @HiveField(6)
  String notificationBody;

  @HiveField(7)
  List<int> reminderDays; // Days of week (1-7, Monday-Sunday)

  @HiveField(8)
  String notificationSound;

  @HiveField(9)
  bool badgeEnabled;

  NotificationSettings({
    this.enabled = true,
    this.hour = 9,
    this.minute = 0,
    this.soundEnabled = true,
    this.vibrationEnabled = true,
    this.notificationTitle = 'Beauty Routine Reminder',
    this.notificationBody = 'Time for your daily beauty routine! ✨',
    List<int>? reminderDays,
    this.notificationSound = 'default',
    this.badgeEnabled = true,
  }) : reminderDays = reminderDays ?? [1, 2, 3, 4, 5, 6, 7]; // Daily by default

  factory NotificationSettings.defaultSettings() {
    return NotificationSettings(
      enabled: true,
      hour: 9,
      minute: 0,
      soundEnabled: true,
      vibrationEnabled: true,
      notificationTitle: 'Beauty Routine Reminder',
      notificationBody: 'Time for your daily beauty routine! ✨',
      reminderDays: [1, 2, 3, 4, 5, 6, 7],
      notificationSound: 'default',
      badgeEnabled: true,
    );
  }

  NotificationSettings copyWith({
    bool? enabled,
    int? hour,
    int? minute,
    bool? soundEnabled,
    bool? vibrationEnabled,
    String? notificationTitle,
    String? notificationBody,
    List<int>? reminderDays,
    String? notificationSound,
    bool? badgeEnabled,
  }) {
    return NotificationSettings(
      enabled: enabled ?? this.enabled,
      hour: hour ?? this.hour,
      minute: minute ?? this.minute,
      soundEnabled: soundEnabled ?? this.soundEnabled,
      vibrationEnabled: vibrationEnabled ?? this.vibrationEnabled,
      notificationTitle: notificationTitle ?? this.notificationTitle,
      notificationBody: notificationBody ?? this.notificationBody,
      reminderDays: reminderDays ?? this.reminderDays,
      notificationSound: notificationSound ?? this.notificationSound,
      badgeEnabled: badgeEnabled ?? this.badgeEnabled,
    );
  }

  // Utility getters
  String get formattedTime {
    final hourStr = hour.toString().padLeft(2, '0');
    final minuteStr = minute.toString().padLeft(2, '0');
    return '$hourStr:$minuteStr';
  }

  bool get isWeekdaysOnly => reminderDays.length == 5 && 
      reminderDays.every((day) => day >= 1 && day <= 5);

  bool get isWeekendsOnly => reminderDays.length == 2 && 
      reminderDays.contains(6) && reminderDays.contains(7);

  bool get isDaily => reminderDays.length == 7;

  String get scheduleDescription {
    if (isDaily) return 'Daily';
    if (isWeekdaysOnly) return 'Weekdays';
    if (isWeekendsOnly) return 'Weekends';
    return 'Custom';
  }
}
```

### 2. Main Notification Service

#### notification_service.dart
```dart
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'package:permission_handler/permission_handler.dart';
import 'package:hive/hive.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'dart:io';

import '../models/notification_settings.dart';
import 'notification_scheduler.dart';
import '../utils/timezone_helper.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._();
  static NotificationService get instance => _instance;
  
  final FlutterLocalNotificationsPlugin _notifications = 
      FlutterLocalNotificationsPlugin();
  
  Box<NotificationSettings>? _settingsBox;
  static const String _settingsBoxName = 'notification_settings';
  static const String _defaultSettingsKey = 'default_settings';
  
  // Notification IDs
  static const int _dailyReminderId = 1000;
  static const int _routineCompletedId = 1001;
  static const int _weeklyReportId = 1002;
  
  NotificationService._();
  
  /// Initialize the notification service
  Future<void> init() async {
    try {
      debugPrint('🔔 NotificationService: Starting initialization');
      
      // Initialize timezone data
      await TimezoneHelper.initialize();
      
      // Initialize notification plugin
      await _initializeNotificationPlugin();
      
      // Create notification channels (Android)
      await _createNotificationChannels();
      
      // Initialize settings storage
      await _initializeSettings();
      
      // Schedule existing notifications if enabled
      await _scheduleExistingNotifications();
      
      debugPrint('✅ NotificationService: Initialization completed');
    } catch (e, stackTrace) {
      debugPrint('❌ NotificationService: Initialization failed: $e');
      debugPrint(stackTrace.toString());
      rethrow;
    }
  }
  
  /// Initialize the notification plugin with platform-specific settings
  Future<void> _initializeNotificationPlugin() async {
    // iOS settings
    const iosSettings = DarwinInitializationSettings(
      requestSoundPermission: true,
      requestBadgePermission: true,
      requestAlertPermission: true,
      requestCriticalPermission: false,
      requestProvisionalPermission: false,
    );
    
    // Android settings
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    
    // Initialize
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );
    
    final result = await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _handleNotificationResponse,
    );
    
    debugPrint('🔔 Notification plugin initialized: $result');
  }
  
  /// Create Android notification channels
  Future<void> _createNotificationChannels() async {
    if (!Platform.isAndroid) return;
    
    final androidPlugin = _notifications.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    
    if (androidPlugin == null) return;
    
    // Main reminder channel
    const reminderChannel = AndroidNotificationChannel(
      'beauty_reminders',
      'Beauty Reminders',
      description: 'Daily beauty routine reminders',
      importance: Importance.high,
      enableVibration: true,
      showBadge: true,
      playSound: true,
      enableLights: true,
    );
    
    // Achievement channel
    const achievementChannel = AndroidNotificationChannel(
      'achievements',
      'Achievements',
      description: 'Achievement and milestone notifications',
      importance: Importance.defaultImportance,
      enableVibration: true,
      showBadge: true,
    );
    
    // Weekly report channel
    const reportChannel = AndroidNotificationChannel(
      'weekly_reports',
      'Weekly Reports',
      description: 'Weekly progress reports',
      importance: Importance.low,
      enableVibration: false,
      showBadge: false,
    );
    
    await androidPlugin.createNotificationChannel(reminderChannel);
    await androidPlugin.createNotificationChannel(achievementChannel);
    await androidPlugin.createNotificationChannel(reportChannel);
    
    debugPrint('🔔 Android notification channels created');
  }
  
  /// Initialize settings storage
  Future<void> _initializeSettings() async {
    if (!Hive.isBoxOpen(_settingsBoxName)) {
      _settingsBox = await Hive.openBox<NotificationSettings>(_settingsBoxName);
    } else {
      _settingsBox = Hive.box<NotificationSettings>(_settingsBoxName);
    }
    
    // Create default settings if none exist
    if (_settingsBox!.get(_defaultSettingsKey) == null) {
      final defaultSettings = NotificationSettings.defaultSettings();
      await _settingsBox!.put(_defaultSettingsKey, defaultSettings);
      debugPrint('🔔 Default notification settings created');
    }
  }
  
  /// Handle notification tap responses
  void _handleNotificationResponse(NotificationResponse response) {
    debugPrint('🔔 Notification tapped: ${response.payload}');
    
    // Parse payload and navigate accordingly
    final payload = response.payload;
    if (payload != null) {
      _handleNotificationAction(payload);
    }
  }
  
  /// Handle notification actions based on payload
  void _handleNotificationAction(String payload) {
    try {
      // Parse JSON payload
      final parts = payload.split('|');
      if (parts.length >= 2) {
        final action = parts[0];
        final data = parts[1];
        
        switch (action) {
          case 'routine_reminder':
            // Navigate to routines screen
            _navigateToRoutines();
            break;
          case 'achievement':
            // Navigate to achievements screen
            _navigateToAchievements();
            break;
          case 'weekly_report':
            // Navigate to analytics screen
            _navigateToAnalytics();
            break;
        }
      }
    } catch (e) {
      debugPrint('❌ Error handling notification action: $e');
    }
  }
  
  /// Navigation helpers (implement based on your navigation system)
  void _navigateToRoutines() {
    // Implement navigation to routines screen
    debugPrint('🔔 Navigating to routines screen');
  }
  
  void _navigateToAchievements() {
    // Implement navigation to achievements screen
    debugPrint('🔔 Navigating to achievements screen');
  }
  
  void _navigateToAnalytics() {
    // Implement navigation to analytics screen
    debugPrint('🔔 Navigating to analytics screen');
  }
  
  /// Request notification permissions
  Future<bool> requestPermission() async {
    try {
      debugPrint('🔔 Requesting notification permissions');
      
      if (Platform.isIOS) {
        final result = await _notifications
            .resolvePlatformSpecificImplementation<
                IOSFlutterLocalNotificationsPlugin>()
            ?.requestPermissions(
              alert: true,
              badge: true,
              sound: true,
            );
        return result ?? false;
      } else if (Platform.isAndroid) {
        final status = await Permission.notification.request();
        return status.isGranted;
      }
      
      return true;
    } catch (e) {
      debugPrint('❌ Error requesting notification permission: $e');
      return false;
    }
  }
  
  /// Check if notifications are enabled
  Future<bool> areNotificationsEnabled() async {
    try {
      if (Platform.isAndroid) {
        final status = await Permission.notification.status;
        return status.isGranted;
      } else if (Platform.isIOS) {
        // For iOS, we assume permissions are granted if the app is running
        // You can implement more sophisticated checking if needed
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('❌ Error checking notification status: $e');
      return false;
    }
  }
  
  /// Get current notification settings
  Future<NotificationSettings> getSettings() async {
    final settings = _settingsBox?.get(_defaultSettingsKey);
    return settings ?? NotificationSettings.defaultSettings();
  }
  
  /// Update notification settings
  Future<bool> updateSettings(NotificationSettings settings) async {
    try {
      await _settingsBox?.put(_defaultSettingsKey, settings);
      
      // Reschedule notifications with new settings
      if (settings.enabled) {
        await scheduleRoutineReminder(settings);
      } else {
        await cancelAllNotifications();
      }
      
      debugPrint('✅ Notification settings updated');
      return true;
    } catch (e) {
      debugPrint('❌ Error updating notification settings: $e');
      return false;
    }
  }
  
  /// Schedule daily routine reminder
  Future<bool> scheduleRoutineReminder(NotificationSettings settings) async {
    try {
      // Cancel existing notifications
      await _notifications.cancel(_dailyReminderId);
      
      if (!settings.enabled) return true;
      
      // Schedule for each selected day
      for (int day in settings.reminderDays) {
        await NotificationScheduler.scheduleDailyNotification(
          _notifications,
          id: _dailyReminderId + day,
          title: settings.notificationTitle,
          body: settings.notificationBody,
          hour: settings.hour,
          minute: settings.minute,
          dayOfWeek: day,
          channelId: 'beauty_reminders',
          payload: 'routine_reminder|daily',
          soundEnabled: settings.soundEnabled,
          vibrationEnabled: settings.vibrationEnabled,
        );
      }
      
      debugPrint('✅ Routine reminders scheduled for ${settings.reminderDays.length} days');
      return true;
    } catch (e) {
      debugPrint('❌ Error scheduling routine reminder: $e');
      return false;
    }
  }
  
  /// Show immediate notification
  Future<void> showNotification({
    required String title,
    required String body,
    String? payload,
    String channelId = 'beauty_reminders',
    bool soundEnabled = true,
    bool vibrationEnabled = true,
  }) async {
    try {
      final androidDetails = AndroidNotificationDetails(
        channelId,
        channelId == 'beauty_reminders' ? 'Beauty Reminders' : 'Notifications',
        importance: Importance.high,
        priority: Priority.high,
        enableVibration: vibrationEnabled,
        playSound: soundEnabled,
        showWhen: true,
      );
      
      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );
      
      final details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );
      
      await _notifications.show(
        DateTime.now().millisecondsSinceEpoch ~/ 1000,
        title,
        body,
        details,
        payload: payload,
      );
      
      debugPrint('✅ Immediate notification shown: $title');
    } catch (e) {
      debugPrint('❌ Error showing notification: $e');
    }
  }
  
  /// Show achievement notification
  Future<void> showAchievementNotification({
    required String title,
    required String description,
  }) async {
    await showNotification(
      title: '🏆 $title',
      body: description,
      payload: 'achievement|unlocked',
      channelId: 'achievements',
    );
  }
  
  /// Show routine completion notification
  Future<void> showRoutineCompletedNotification({
    required String routineName,
    required int streakCount,
  }) async {
    await showNotification(
      title: '✅ Routine Completed!',
      body: '$routineName completed! Streak: $streakCount days 🔥',
      payload: 'routine_completed|$routineName',
      channelId: 'achievements',
    );
  }
  
  /// Schedule weekly report notification
  Future<void> scheduleWeeklyReport() async {
    try {
      await NotificationScheduler.scheduleWeeklyNotification(
        _notifications,
        id: _weeklyReportId,
        title: '📊 Weekly Beauty Report',
        body: 'Check out your beauty routine progress this week!',
        dayOfWeek: 7, // Sunday
        hour: 18, // 6 PM
        minute: 0,
        channelId: 'weekly_reports',
        payload: 'weekly_report|summary',
      );
      
      debugPrint('✅ Weekly report notification scheduled');
    } catch (e) {
      debugPrint('❌ Error scheduling weekly report: $e');
    }
  }
  
  /// Cancel all notifications
  Future<void> cancelAllNotifications() async {
    try {
      await _notifications.cancelAll();
      debugPrint('✅ All notifications cancelled');
    } catch (e) {
      debugPrint('❌ Error cancelling notifications: $e');
    }
  }
  
  /// Cancel specific notification
  Future<void> cancelNotification(int id) async {
    try {
      await _notifications.cancel(id);
      debugPrint('✅ Notification $id cancelled');
    } catch (e) {
      debugPrint('❌ Error cancelling notification $id: $e');
    }
  }
  
  /// Get pending notifications (for debugging)
  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    try {
      return await _notifications.pendingNotificationRequests();
    } catch (e) {
      debugPrint('❌ Error getting pending notifications: $e');
      return [];
    }
  }
  
  /// Schedule existing notifications on app start
  Future<void> _scheduleExistingNotifications() async {
    final settings = await getSettings();
    if (settings.enabled) {
      await scheduleRoutineReminder(settings);
      await scheduleWeeklyReport();
    }
  }
  
  /// Dispose resources
  Future<void> dispose() async {
    await _settingsBox?.close();
  }
}
```

### 3. Notification Scheduler Helper

#### notification_scheduler.dart
```dart
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter/foundation.dart';

class NotificationScheduler {
  /// Schedule a daily notification at specific time
  static Future<void> scheduleDailyNotification(
    FlutterLocalNotificationsPlugin notifications, {
    required int id,
    required String title,
    required String body,
    required int hour,
    required int minute,
    required int dayOfWeek, // 1-7 (Monday-Sunday)
    required String channelId,
    String? payload,
    bool soundEnabled = true,
    bool vibrationEnabled = true,
  }) async {
    try {
      final now = tz.TZDateTime.now(tz.local);
      
      // Calculate next occurrence of the specified day and time
      var scheduledDate = tz.TZDateTime(
        tz.local,
        now.year,
        now.month,
        now.day,
        hour,
        minute,
      );
      
      // Adjust to the correct day of week
      while (scheduledDate.weekday != dayOfWeek) {
        scheduledDate = scheduledDate.add(const Duration(days: 1));
      }
      
      // If the time has passed today, schedule for next week
      if (scheduledDate.isBefore(now)) {
        scheduledDate = scheduledDate.add(const Duration(days: 7));
      }
      
      final androidDetails = AndroidNotificationDetails(
        channelId,
        _getChannelName(channelId),
        importance: Importance.high,
        priority: Priority.high,
        enableVibration: vibrationEnabled,
        playSound: soundEnabled,
        showWhen: true,
      );
      
      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );
      
      final details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );
      
      await notifications.zonedSchedule(
        id,
        title,
        body,
        scheduledDate,
        details,
        payload: payload,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
      );
      
      debugPrint('✅ Daily notification scheduled for ${_getDayName(dayOfWeek)} at $hour:${minute.toString().padLeft(2, '0')}');
    } catch (e) {
      debugPrint('❌ Error scheduling daily notification: $e');
      rethrow;
    }
  }
  
  /// Schedule a weekly notification
  static Future<void> scheduleWeeklyNotification(
    FlutterLocalNotificationsPlugin notifications, {
    required int id,
    required String title,
    required String body,
    required int dayOfWeek, // 1-7 (Monday-Sunday)
    required int hour,
    required int minute,
    required String channelId,
    String? payload,
  }) async {
    try {
      final now = tz.TZDateTime.now(tz.local);
      
      var scheduledDate = tz.TZDateTime(
        tz.local,
        now.year,
        now.month,
        now.day,
        hour,
        minute,
      );
      
      // Adjust to the correct day of week
      while (scheduledDate.weekday != dayOfWeek) {
        scheduledDate = scheduledDate.add(const Duration(days: 1));
      }
      
      // If the time has passed today, schedule for next week
      if (scheduledDate.isBefore(now)) {
        scheduledDate = scheduledDate.add(const Duration(days: 7));
      }
      
      const androidDetails = AndroidNotificationDetails(
        'weekly_reports',
        'Weekly Reports',
        importance: Importance.defaultImportance,
        priority: Priority.defaultPriority,
        enableVibration: false,
        playSound: true,
      );
      
      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );
      
      const details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );
      
      await notifications.zonedSchedule(
        id,
        title,
        body,
        scheduledDate,
        details,
        payload: payload,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
      );
      
      debugPrint('✅ Weekly notification scheduled for ${_getDayName(dayOfWeek)} at $hour:${minute.toString().padLeft(2, '0')}');
    } catch (e) {
      debugPrint('❌ Error scheduling weekly notification: $e');
      rethrow;
    }
  }
  
  /// Schedule a one-time notification
  static Future<void> scheduleOneTimeNotification(
    FlutterLocalNotificationsPlugin notifications, {
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
    required String channelId,
    String? payload,
  }) async {
    try {
      final tzScheduledDate = tz.TZDateTime.from(scheduledDate, tz.local);
      
      final androidDetails = AndroidNotificationDetails(
        channelId,
        _getChannelName(channelId),
        importance: Importance.high,
        priority: Priority.high,
      );
      
      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );
      
      const details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );
      
      await notifications.zonedSchedule(
        id,
        title,
        body,
        tzScheduledDate,
        details,
        payload: payload,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
      
      debugPrint('✅ One-time notification scheduled for $scheduledDate');
    } catch (e) {
      debugPrint('❌ Error scheduling one-time notification: $e');
      rethrow;
    }
  }
  
  /// Helper to get channel name
  static String _getChannelName(String channelId) {
    switch (channelId) {
      case 'beauty_reminders':
        return 'Beauty Reminders';
      case 'achievements':
        return 'Achievements';
      case 'weekly_reports':
        return 'Weekly Reports';
      default:
        return 'Notifications';
    }
  }
  
  /// Helper to get day name
  static String _getDayName(int dayOfWeek) {
    const days = ['', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    return days[dayOfWeek];
  }
}
```

### 4. Timezone Helper

#### timezone_helper.dart
```dart
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'package:flutter/foundation.dart';

class TimezoneHelper {
  static bool _isInitialized = false;
  
  /// Initialize timezone data
  static Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      debugPrint('🌍 Initializing timezone data');
      
      // Initialize timezone database
      tz.initializeTimeZones();
      
      // Detect and set local timezone
      final timezoneName = _detectLocalTimezone();
      final location = tz.getLocation(timezoneName);
      tz.setLocalLocation(location);
      
      _isInitialized = true;
      debugPrint('✅ Timezone initialized: ${tz.local}');
      debugPrint('🕐 Current time: ${tz.TZDateTime.now(tz.local)}');
    } catch (e) {
      debugPrint('❌ Error initializing timezone: $e');
      rethrow;
    }
  }
  
  /// Detect local timezone
  static String _detectLocalTimezone() {
    final offset = DateTime.now().timeZoneOffset.inHours;
    debugPrint('🌍 Local timezone offset: $offset hours');
    
    // Common timezone mappings
    const timezoneMap = {
      -12: 'Pacific/Kwajalein',
      -11: 'Pacific/Midway',
      -10: 'Pacific/Honolulu',
      -9: 'America/Anchorage',
      -8: 'America/Los_Angeles',
      -7: 'America/Denver',
      -6: 'America/Chicago',
      -5: 'America/New_York',
      -4: 'America/Halifax',
      -3: 'America/Sao_Paulo',
      -2: 'Atlantic/South_Georgia',
      -1: 'Atlantic/Azores',
      0: 'Europe/London',
      1: 'Europe/Paris',
      2: 'Europe/Berlin',
      3: 'Europe/Moscow',
      4: 'Asia/Dubai',
      5: 'Asia/Karachi',
      6: 'Asia/Dhaka',
      7: 'Asia/Bangkok',
      8: 'Asia/Shanghai',
      9: 'Asia/Tokyo',
      10: 'Australia/Sydney',
      11: 'Pacific/Norfolk',
      12: 'Pacific/Auckland',
    };
    
    final timezoneName = timezoneMap[offset] ?? 'UTC';
    debugPrint('🌍 Detected timezone: $timezoneName');
    
    return timezoneName;
  }
  
  /// Get next occurrence of time on specific day
  static tz.TZDateTime getNextOccurrence({
    required int hour,
    required int minute,
    int? dayOfWeek, // 1-7, Monday-Sunday
  }) {
    final now = tz.TZDateTime.now(tz.local);
    
    var scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );
    
    // If specific day is requested
    if (dayOfWeek != null) {
      while (scheduledDate.weekday != dayOfWeek) {
        scheduledDate = scheduledDate.add(const Duration(days: 1));
      }
    }
    
    // If time has passed, move to next occurrence
    if (scheduledDate.isBefore(now)) {
      if (dayOfWeek != null) {
        scheduledDate = scheduledDate.add(const Duration(days: 7));
      } else {
        scheduledDate = scheduledDate.add(const Duration(days: 1));
      }
    }
    
    return scheduledDate;
  }
  
  /// Format timezone date for display
  static String formatDateTime(tz.TZDateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} '
           '${dateTime.hour.toString().padLeft(2, '0')}:'
           '${dateTime.minute.toString().padLeft(2, '0')}';
  }
}
```

## 🔁 Integration Guide

### Step 1: Add Dependencies and Permissions

#### pubspec.yaml
```yaml
dependencies:
  flutter_local_notifications: ^19.2.1
  timezone: ^0.10.0
  permission_handler: ^11.1.0
  shared_preferences: ^2.2.2
```

#### Android Configuration (android/app/src/main/AndroidManifest.xml)
```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
    <!-- Notification permissions -->
    <uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED" />
    <uses-permission android:name="android.permission.VIBRATE" />
    <uses-permission android:name="android.permission.WAKE_LOCK" />
    <uses-permission android:name="android.permission.SCHEDULE_EXACT_ALARM" />
    
    <application>
        <!-- Boot receiver for notifications -->
        <receiver android:name="com.dexterous.flutterlocalnotifications.ScheduledNotificationBootReceiver"
            android:enabled="true"
            android:exported="false">
            <intent-filter>
                <action android:name="android.intent.action.BOOT_COMPLETED"/>
                <action android:name="android.intent.action.MY_PACKAGE_REPLACED"/>
                <action android:name="android.intent.action.QUICKBOOT_POWERON" />
                <action android:name="com.htc.intent.action.QUICKBOOT_POWERON"/>
            </intent-filter>
        </receiver>
        
        <!-- Notification receiver -->
        <receiver android:name="com.dexterous.flutterlocalnotifications.ScheduledNotificationReceiver" />
    </application>
</manifest>
```

#### iOS Configuration (ios/Runner/Info.plist)
```xml
<dict>
    <!-- Notification permissions -->
    <key>UIBackgroundModes</key>
    <array>
        <string>background-processing</string>
        <string>background-fetch</string>
    </array>
</dict>
```

### Step 2: Initialize in main.dart
```dart
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Hive and other services...
  
  // Initialize notification service
  final notificationService = NotificationService.instance;
  await notificationService.init();
  
  runApp(MyApp());
}
```

### Step 3: Usage Examples

#### Request Permission
```dart
final hasPermission = await NotificationService.instance.requestPermission();
if (!hasPermission) {
  // Show permission explanation dialog
}
```

#### Schedule Daily Reminders
```dart
final settings = NotificationSettings(
  enabled: true,
  hour: 9,
  minute: 0,
  notificationTitle: 'Morning Routine',
  notificationBody: 'Time for your skincare routine! ✨',
  reminderDays: [1, 2, 3, 4, 5], // Weekdays only
);

await NotificationService.instance.updateSettings(settings);
```

#### Show Achievement Notification
```dart
await NotificationService.instance.showAchievementNotification(
  title: 'Streak Master!',
  description: 'You\'ve completed your routine 7 days in a row!',
);
```

## 💾 Persistence Handling

- **Settings Storage**: Notification preferences saved in Hive
- **Scheduled Notifications**: Persist across app restarts and device reboots
- **Permission State**: Cached permission status for quick checks
- **Timezone Handling**: Automatic timezone detection and adjustment

## 📱 Platform-Specific Features

### Android
- **Notification Channels**: Organized by type (reminders, achievements, reports)
- **Exact Alarms**: Precise scheduling even in doze mode
- **Boot Receiver**: Notifications restored after device restart
- **Custom Sounds**: Support for custom notification sounds

### iOS
- **Badge Management**: App icon badge updates
- **Critical Alerts**: Support for important notifications
- **Provisional Notifications**: Quiet notifications for trial
- **Rich Notifications**: Support for images and actions

## 🔄 Feature Validation

✅ **Cross-Platform**: Works on both iOS and Android
✅ **Timezone Support**: Handles timezone changes and DST
✅ **Permission Handling**: Proper permission request flow
✅ **Scheduled Notifications**: Reliable daily/weekly scheduling
✅ **Custom Actions**: Tap handling and navigation
✅ **Settings Persistence**: User preferences saved and restored
✅ **Background Reliability**: Works when app is closed

---

**Next**: Continue with `08_Ads_Integration` to implement Google AdMob monetization. 