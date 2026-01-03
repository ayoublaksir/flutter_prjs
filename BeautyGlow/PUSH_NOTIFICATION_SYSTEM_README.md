# 🔔 BeautyGlow Push Notification System - Complete Documentation

## 📋 Overview

This document provides a complete breakdown of the push notification system implemented in the BeautyGlow Flutter application. The system uses **local notifications** (not push notifications) to send daily beauty routine reminders to users.

## 🏗️ Architecture Overview

```
User Interface (Profile Screen)
        ↓
Notification Service (Singleton)
        ↓
Flutter Local Notifications Plugin
        ↓
Platform-Specific Implementation (Android/iOS)
        ↓
System Notifications
```

## 📦 Dependencies & Versions Used

### `pubspec.yaml` Dependencies:
```yaml
dependencies:
  # Notifications
  flutter_local_notifications: ^19.2.1  # Main notification plugin
  timezone: ^0.10.0                     # Timezone handling for scheduling
  permission_handler: ^11.1.0           # Runtime permissions
  shared_preferences: ^2.2.2            # Additional storage (if needed)
  
  # Storage for notification settings
  hive: ^2.2.3                         # Local database
  hive_flutter: ^1.1.0                 # Flutter-specific Hive integration

dev_dependencies:
  hive_generator: ^2.0.0               # Code generation for Hive models
  build_runner: ^2.4.8                 # Build system for code generation
```

## 🔧 Platform Configuration

### Android Configuration (`android/app/src/main/AndroidManifest.xml`):
```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
    <!-- Notification Permissions -->
    <uses-permission android:name="android.permission.SCHEDULE_EXACT_ALARM" />
    <uses-permission android:name="android.permission.USE_EXACT_ALARM" />
    <uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>
    
    <!-- Other permissions... -->
    <uses-permission android:name="com.android.vending.BILLING"/>
    <uses-permission android:name="android.permission.INTERNET" />
    <uses-permission android:name="android.permission.ACCESS_NETWORK_STATE" />
    
    <application
        android:label="BeautyGlow"
        android:name="${applicationName}"
        android:icon="@mipmap/ic_launcher">
        
        <!-- Main Activity Configuration -->
        <activity
            android:name=".MainActivity"
            android:exported="true"
            android:launchMode="singleTop"
            android:taskAffinity=""
            android:theme="@style/LaunchTheme"
            android:configChanges="orientation|keyboardHidden|keyboard|screenSize|smallestScreenSize|locale|layoutDirection|fontScale|screenLayout|density|uiMode"
            android:hardwareAccelerated="true"
            android:windowSoftInputMode="adjustResize">
            
            <meta-data
              android:name="io.flutter.embedding.android.NormalTheme"
              android:resource="@style/NormalTheme" />
              
            <intent-filter>
                <action android:name="android.intent.action.MAIN"/>
                <category android:name="android.intent.category.LAUNCHER"/>
            </intent-filter>
        </activity>
        
        <!-- Flutter Configuration -->
        <meta-data
            android:name="flutterEmbedding"
            android:value="2" />
            
        <!-- AdMob Configuration -->
        <meta-data
            android:name="com.google.android.gms.ads.APPLICATION_ID"
            android:value="ca-app-pub-9204828301343579~9177265799"/>
    </application>
</manifest>
```

### iOS Configuration:
- No additional configuration required in Info.plist
- Permissions are requested at runtime through the plugin

## 📊 Data Model

### Notification Settings Model (`lib/models/notification_settings.dart`):
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

  NotificationSettings({
    this.enabled = true,
    this.hour = 20,      // Default: 8:00 PM
    this.minute = 0,
  });
}
```

**Generated Hive Adapter (`lib/models/notification_settings.g.dart`):**
```dart
// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'notification_settings.dart';

class NotificationSettingsAdapter extends TypeAdapter<NotificationSettings> {
  @override
  final int typeId = 7;

  @override
  NotificationSettings read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return NotificationSettings(
      enabled: fields[0] as bool,
      hour: fields[1] as int,
      minute: fields[2] as int,
    );
  }

  @override
  void write(BinaryWriter writer, NotificationSettings obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.enabled)
      ..writeByte(1)
      ..write(obj.hour)
      ..writeByte(2)
      ..write(obj.minute);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NotificationSettingsAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
```

## 🛠️ Core Service Implementation

### Main Notification Service (`lib/services/notification_service.dart`):

```dart
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'package:hive_flutter/hive_flutter.dart';
import '../models/notification_settings.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:typed_data';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class NotificationService {
  // Singleton Pattern
  static final NotificationService _instance = NotificationService._();
  static NotificationService get instance => _instance;

  // Core Components
  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();
  Box<NotificationSettings>? _settingsBox;
  static const String _boxName = 'notification_settings';

  NotificationService._();

  // Timezone Detection Method
  String _detectLocalTimezone() {
    final commonTimezones = [
      'Europe/London', 'Europe/Paris', 'Europe/Berlin',
      'America/New_York', 'America/Los_Angeles', 'America/Chicago',
      'Asia/Dubai', 'Asia/Tokyo', 'Asia/Shanghai',
      'Australia/Sydney', 'Africa/Cairo',
    ];

    final offset = DateTime.now().timeZoneOffset.inHours;
    print('[NotificationService] Local timezone offset: $offset hours');

    // Try to find a matching timezone
    for (var timezone in commonTimezones) {
      try {
        final location = tz.getLocation(timezone);
        final tzNow = tz.TZDateTime.now(location);
        if (tzNow.timeZoneOffset.inHours == offset) {
          print('[NotificationService] Found matching timezone: $timezone');
          return timezone;
        }
      } catch (e) {
        continue;
      }
    }

    // Fallback timezone based on offset
    if (offset >= 0) {
      return 'Etc/GMT-$offset';
    } else {
      return 'Etc/GMT+${-offset}';
    }
  }

  // Service Initialization
  Future<void> init() async {
    try {
      print('[NotificationService] -------- Starting Initialization --------');

      // 1. Initialize Timezone
      tz.initializeTimeZones();
      String timezoneName = _detectLocalTimezone();
      print('[NotificationService] Detected timezone name: $timezoneName');
      
      final location = tz.getLocation(timezoneName);
      tz.setLocalLocation(location);
      print('[NotificationService] Timezone set to: ${tz.local}');

      final now = tz.TZDateTime.now(tz.local);
      print('[NotificationService] Current time in local timezone: $now');

      // 2. Initialize Notification Plugin
      final iosSettings = DarwinInitializationSettings(
        requestSoundPermission: true,
        requestBadgePermission: true,
        requestAlertPermission: true,
      );

      const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');

      final initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      print('[NotificationService] Initializing notification plugin');
      var initResult = await _notifications.initialize(
        initSettings,
        onDidReceiveNotificationResponse: (details) async {
          print('[NotificationService] Notification tapped: ${details.payload}');
        },
      );
      print('[NotificationService] Notification plugin initialized: $initResult');

      // 3. Create Android Notification Channel
      final androidChannel = AndroidNotificationChannel(
        'beauty_reminder',
        'Beauty Reminders',
        description: 'Daily beauty routine reminders',
        importance: Importance.max,
        enableVibration: true,
        showBadge: true,
        playSound: true,
        enableLights: true,
      );

      final androidPlugin = _notifications.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();

      if (androidPlugin != null) {
        print('[NotificationService] Creating Android notification channel');
        await androidPlugin.createNotificationChannel(androidChannel);

        final channels = await androidPlugin.getNotificationChannels();
        print('[NotificationService] Available notification channels: ${channels?.length}');
        for (var channel in channels ?? []) {
          print('[NotificationService] Channel: ${channel.id}, Importance: ${channel.importance}');
        }
      }

      // 4. Initialize Hive Storage
      if (!Hive.isBoxOpen(_boxName)) {
        print('[NotificationService] Opening Hive box: $_boxName');
        _settingsBox = await Hive.openBox<NotificationSettings>(_boxName);
      }

      // 5. Schedule Existing Notifications
      final currentSettings = await getSettings();
      print('[NotificationService] Current settings loaded: enabled=${currentSettings.enabled}, time=${currentSettings.hour}:${currentSettings.minute}');

      if (currentSettings.enabled) {
        print('[NotificationService] Scheduling initial reminder');
        await scheduleRoutineReminder(
          hour: currentSettings.hour,
          minute: currentSettings.minute,
        );
      }

      print('[NotificationService] -------- Initialization Complete --------');
    } catch (e, stackTrace) {
      print('[NotificationService] Error during initialization: $e');
      print('[NotificationService] Stack trace: $stackTrace');
      rethrow;
    }
  }

  // Permission Request Method
  Future<bool> requestPermission() async {
    try {
      print('\n[NotificationService] -------- Requesting Permissions --------');

      if (Platform.isIOS) {
        // iOS Permission Request
        final result = await _notifications
            .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()
            ?.requestPermissions(
              alert: true,
              badge: true,
              sound: true,
            );
        print('[NotificationService] iOS permission result: $result');
        return result ?? false;
      } else if (Platform.isAndroid) {
        // Android Permission Request (API 33+)
        print('[NotificationService] Requesting Android notification permission');

        final currentStatus = await Permission.notification.status;
        print('[NotificationService] Current notification permission status: $currentStatus');

        if (currentStatus.isGranted) {
          print('[NotificationService] Notification permission already granted');
          return true;
        }

        final status = await Permission.notification.request();
        print('[NotificationService] Notification permission request result: $status');

        if (!status.isGranted) {
          print('[NotificationService] Notification permission denied');
          return false;
        }

        // Request Exact Alarm Permission (Android 12+)
        try {
          final exactAlarmStatus = await Permission.scheduleExactAlarm.status;
          print('[NotificationService] Current exact alarm permission status: $exactAlarmStatus');

          if (!exactAlarmStatus.isGranted) {
            print('[NotificationService] Requesting exact alarm permission');
            final exactAlarmResult = await Permission.scheduleExactAlarm.request();
            print('[NotificationService] Exact alarm permission result: $exactAlarmResult');

            if (!exactAlarmResult.isGranted) {
              print('[NotificationService] WARNING: Exact alarm permission denied - notifications may not work reliably');
            }
          }
        } catch (e) {
          print('[NotificationService] Error requesting exact alarm permission (might be older Android): $e');
        }

        return status.isGranted;
      }

      return true;
    } catch (e) {
      print('[NotificationService] Error requesting permissions: $e');
      return false;
    }
  }

  // Notification Scheduling Method
  Future<void> scheduleRoutineReminder({
    required int hour,
    required int minute,
  }) async {
    try {
      print('\n[NotificationService] -------- Scheduling Reminder --------');

      // Log device time information
      final deviceTime = DateTime.now();
      final deviceOffset = deviceTime.timeZoneOffset;
      final deviceTimezoneName = DateTime.now().timeZoneName;

      print('[NotificationService] Device Time Info:');
      print('  • Local time: ${deviceTime.toString()}');
      print('  • UTC time: ${deviceTime.toUtc().toString()}');
      print('  • Timezone offset: ${deviceOffset.inHours}h ${deviceOffset.inMinutes % 60}m');
      print('  • Timezone name: $deviceTimezoneName');

      // Calculate delay until target time
      final now = DateTime.now();
      final scheduledTime = DateTime(now.year, now.month, now.day, hour, minute);

      var finalScheduledTime = scheduledTime;
      if (scheduledTime.isBefore(now)) {
        finalScheduledTime = scheduledTime.add(const Duration(days: 1));
      }

      final delayDuration = finalScheduledTime.difference(now);

      print('\n[NotificationService] Schedule Details:');
      print('  • Target time: ${finalScheduledTime.toString()}');
      print('  • Delay duration: ${delayDuration.inHours}h ${delayDuration.inMinutes % 60}m');

      // Schedule the delayed notification
      Future.delayed(delayDuration, () async {
        print('[NotificationService] Triggering scheduled notification');
        await _notifications.show(
          0, // Using ID 0 for scheduled notification
          'Beauty Routine Reminder ✨',
          'Time for your daily beauty routine! Take care of your skin.',
          NotificationDetails(
            android: AndroidNotificationDetails(
              'beauty_reminder',
              'Beauty Reminders',
              channelDescription: 'Daily beauty routine reminders',
              importance: Importance.max,
              priority: Priority.high,
              enableVibration: true,
              playSound: false,
              icon: '@mipmap/ic_launcher',
              largeIcon: const DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
              enableLights: true,
              color: const Color.fromARGB(255, 233, 30, 99),
              ledColor: const Color.fromARGB(255, 233, 30, 99),
              ledOnMs: 1000,
              ledOffMs: 500,
              category: AndroidNotificationCategory.reminder,
              visibility: NotificationVisibility.public,
              fullScreenIntent: true,
              actions: [
                const AndroidNotificationAction(
                  'open_app',
                  'Open App',
                  showsUserInterface: true,
                ),
              ],
            ),
            iOS: const DarwinNotificationDetails(
              presentAlert: true,
              presentBadge: true,
              presentSound: false,
              badgeNumber: 1,
              categoryIdentifier: 'beauty_reminder',
            ),
          ),
        );

        // Schedule next day's notification recursively
        scheduleRoutineReminder(hour: hour, minute: minute);
      });

      print('[NotificationService] Reminder scheduled successfully');
    } catch (e, stackTrace) {
      print('[NotificationService] ERROR scheduling reminder: $e');
      print('[NotificationService] Stack trace: $stackTrace');
      rethrow;
    }
  }

  // Cancel Notifications
  Future<void> cancelRoutineReminder() async {
    await _notifications.cancel(0);
  }

  // Test Notification
  Future<void> showTestNotification() async {
    try {
      print('[NotificationService] Showing test notification');
      await _notifications.show(
        999, // Use ID 999 for test notification
        'BeautyGlow Notifications Enabled! ✨',
        'Your daily beauty reminders are now active. Take care of your skin!',
        NotificationDetails(
          android: AndroidNotificationDetails(
            'beauty_reminder',
            'Beauty Reminders',
            channelDescription: 'Daily beauty routine reminders',
            importance: Importance.max,
            priority: Priority.high,
            enableVibration: true,
            playSound: true,
            icon: '@mipmap/ic_launcher',
            largeIcon: const DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
            color: const Color.fromARGB(255, 233, 30, 99),
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
            badgeNumber: 1,
          ),
        ),
      );
      print('[NotificationService] Test notification sent successfully');
    } catch (e) {
      print('[NotificationService] Error showing test notification: $e');
    }
  }

  // Toggle Notification State
  Future<void> toggleRoutineReminder(bool enabled) async {
    try {
      print('[NotificationService] Toggling reminder to: $enabled');

      // Ensure Hive box is open
      if (!Hive.isBoxOpen(_boxName)) {
        print('[NotificationService] Opening Hive box');
        _settingsBox = await Hive.openBox<NotificationSettings>(_boxName);
      }

      // Get current or create default settings
      NotificationSettings? currentSettings = _settingsBox?.get('settings');
      print('[NotificationService] Current settings from box: ${currentSettings?.enabled}, ${currentSettings?.hour}:${currentSettings?.minute}');

      if (currentSettings == null) {
        print('[NotificationService] No settings found, creating defaults');
        currentSettings = NotificationSettings(
          enabled: enabled,
          hour: 20,
          minute: 0,
        );
      } else {
        currentSettings = NotificationSettings(
          enabled: enabled,
          hour: currentSettings.hour,
          minute: currentSettings.minute,
        );
      }

      // Cancel existing notifications
      print('[NotificationService] Cancelling any existing notifications');
      await cancelRoutineReminder();

      // Save settings
      print('[NotificationService] Saving settings to box');
      await _settingsBox?.put('settings', currentSettings);
      print('[NotificationService] Settings saved successfully');

      if (enabled) {
        // Request permission before scheduling
        print('[NotificationService] Requesting notification permission');
        final hasPermission = await requestPermission();
        if (!hasPermission) {
          print('[NotificationService] Permission denied');
          throw Exception('Notification permission denied');
        }
        print('[NotificationService] Permission granted');

        // Schedule the notification
        print('[NotificationService] Scheduling reminder for ${currentSettings.hour}:${currentSettings.minute}');
        await scheduleRoutineReminder(
          hour: currentSettings.hour,
          minute: currentSettings.minute,
        );
        print('[NotificationService] Reminder scheduled successfully');
      } else {
        print('[NotificationService] Notifications disabled, no scheduling needed');
      }

      // Verify final state
      final verifySettings = await getSettings();
      print('[NotificationService] Final settings state: enabled=${verifySettings.enabled}, time=${verifySettings.hour}:${verifySettings.minute}');
    } catch (e) {
      print('[NotificationService] Error toggling notification: $e');
      rethrow;
    }
  }

  // Update Notification Time
  Future<void> updateNotificationTime(int hour, int minute) async {
    try {
      print('[NotificationService] Updating notification time to $hour:$minute');

      if (!Hive.isBoxOpen(_boxName)) {
        print('[NotificationService] Opening Hive box');
        _settingsBox = await Hive.openBox<NotificationSettings>(_boxName);
      }

      final currentSettings = _settingsBox?.get('settings');
      print('[NotificationService] Current settings: ${currentSettings?.enabled}, ${currentSettings?.hour}:${currentSettings?.minute}');

      final newSettings = NotificationSettings(
        enabled: currentSettings?.enabled ?? true,
        hour: hour,
        minute: minute,
      );

      print('[NotificationService] Saving new settings');
      await _settingsBox?.put('settings', newSettings);
      print('[NotificationService] Settings saved successfully');

      // Reschedule if enabled
      if (newSettings.enabled) {
        print('[NotificationService] Scheduling reminder with new time');
        await scheduleRoutineReminder(hour: hour, minute: minute);
        print('[NotificationService] Reminder rescheduled successfully');
      }
    } catch (e) {
      print('[NotificationService] Error updating notification time: $e');
      rethrow;
    }
  }

  // Get Current Settings
  Future<NotificationSettings> getSettings() async {
    try {
      print('[NotificationService] Getting current settings');

      if (!Hive.isBoxOpen(_boxName)) {
        print('[NotificationService] Opening Hive box');
        _settingsBox = await Hive.openBox<NotificationSettings>(_boxName);
      }

      final settings = _settingsBox?.get('settings') ?? NotificationSettings();
      print('[NotificationService] Retrieved settings: enabled=${settings.enabled}, time=${settings.hour}:${settings.minute}');

      return settings;
    } catch (e) {
      print('[NotificationService] Error getting settings: $e');
      rethrow;
    }
  }
}
```

## 🎯 Service Integration

### App Initialization (`lib/main.dart`):
```dart
void main() async {
  // ... other initialization code ...
  
  try {
    // Create service instances
    debugPrint('⚙️ App: Creating service instances');
    final subscriptionService = SubscriptionService();
    final storageService = StorageService();
    final notificationService = NotificationService.instance;  // Singleton instance
    final adService = AdService();
    debugPrint('✓ App: Service instances created');

    // Initialize services sequentially
    debugPrint('⚙️ App: Initializing services sequentially');

    // Initialize NotificationService
    try {
      debugPrint('⚙️ App: Initializing NotificationService');
      await notificationService.init();  // Full initialization
      debugPrint('✅ App: NotificationService initialized');
    } catch (e) {
      debugPrint('❌ App: NotificationService initialization failed: $e');
      // Retry once with delay
      debugPrint('🔄 App: Retrying NotificationService initialization');
      await Future.delayed(const Duration(milliseconds: 500));
      await notificationService.init();
      debugPrint('✅ App: NotificationService initialized on retry');
    }

    // ... other service initializations ...

    runApp(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => ThemeProvider()),
          Provider<SubscriptionService>.value(value: subscriptionService),
          Provider<StorageService>.value(value: storageService),
          Provider<NotificationService>.value(value: notificationService),  // Provide to widget tree
          Provider<AdService>.value(value: adService),
        ],
        child: const BeautyGlowApp(),
      ),
    );
    debugPrint('✅ App: Application started successfully');
  } catch (e, stackTrace) {
    debugPrint('❌ App: Error during initialization:');
    debugPrint(e.toString());
    debugPrint(stackTrace.toString());
    // ... error handling ...
  }
}
```

## 🔄 Complete Notification Flow

### 1. **App Launch Flow:**
```
App Startup → main() → Service Initialization → NotificationService.init() → 
Permission Check → Settings Load → Schedule Active Notifications
```

### 2. **Permission Request Flow:**
```
User Enables Notifications → requestPermission() → 
Platform-Specific Permission Request → 
Android: POST_NOTIFICATIONS + SCHEDULE_EXACT_ALARM → 
iOS: Alert + Badge + Sound → Return Permission Status
```

### 3. **Notification Scheduling Flow:**
```
User Sets Time → updateNotificationTime() → Save Settings to Hive → 
Cancel Existing Notifications → scheduleRoutineReminder() → 
Calculate Next Trigger Time → Future.delayed() → Show Notification → 
Recursive Reschedule for Tomorrow
```

### 4. **UI Interaction Flow:**
```
Profile Screen → Notification Settings Dialog → 
Switch Toggle → Permission Request (if needed) → 
Service Method Call → State Update → Success/Error Feedback → 
Time Picker (optional) → Time Update → Reschedule Notification
```

## ⚡ Key Features

### ✅ **Implemented Features:**
- **Local Notifications**: Uses flutter_local_notifications plugin
- **Daily Scheduling**: Automatic daily reminders at user-selected time
- **Permission Handling**: Runtime permission requests for both platforms
- **Timezone Support**: Automatic timezone detection and handling
- **Persistent Settings**: Hive database for notification preferences
- **UI Integration**: Complete settings interface with switch and time picker
- **Error Handling**: Comprehensive error handling and retry logic
- **Platform Support**: iOS and Android specific configurations
- **Singleton Service**: Single instance notification service
- **Automatic Rescheduling**: Self-renewing daily notifications

### ❌ **Limitations:**
- **Local Only**: These are local notifications, not push notifications
- **App Dependency**: Notifications only work when app has been opened recently
- **Simple Scheduling**: Basic daily scheduling (no complex patterns)
- **Single Reminder**: Only one daily reminder type implemented

---

**📝 Note**: This system implements **local notifications**, not push notifications. For true push notifications, you would need to integrate Firebase Cloud Messaging (FCM) or Apple Push Notification Service (APNs). 