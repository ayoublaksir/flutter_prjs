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

The core service implements a singleton pattern and handles all notification functionality:

**Key Methods:**
- `init()` - Initialize the service, timezone, and plugin
- `requestPermission()` - Handle platform-specific permission requests
- `scheduleRoutineReminder()` - Schedule daily notifications
- `toggleRoutineReminder()` - Enable/disable notifications
- `updateNotificationTime()` - Change notification time
- `getSettings()` - Retrieve current settings

**Permission Handling:**
- **Android**: Requests `POST_NOTIFICATIONS` and `SCHEDULE_EXACT_ALARM` permissions
- **iOS**: Requests alert, badge, and sound permissions through the plugin

**Scheduling Logic:**
- Uses `Future.delayed()` with calculated time differences
- Automatically reschedules for the next day after triggering
- Handles timezone detection and conversion

## 🎨 User Interface Implementation

### Profile Screen Notification Settings (`lib/screens/profile/profile_screen.dart`):

The notification settings are accessible through the Profile Screen with the following UI components:

**1. Notification Settings Dialog:**
```dart
showDialog(
  context: context,
  builder: (context) => AlertDialog(
    title: Text('Notification Settings', style: AppTypography.headingSmall),
    content: StatefulBuilder(
      builder: (context, setState) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Enable/Disable Switch
          SwitchListTile(
            title: Text('Beauty Routine Reminders', style: AppTypography.labelLarge),
            subtitle: Text('Daily notifications for routines', style: AppTypography.bodySmall),
            value: _notificationsEnabled,
            onChanged: (value) async {
              // Toggle notification logic
            },
          ),
          // Time Picker (shown only when enabled)
          if (_notificationsEnabled) ...[
            Divider(),
            ListTile(
              leading: Icon(Icons.access_time, color: AppColors.primaryPink),
              title: Text('Reminder Time', style: AppTypography.labelLarge),
              subtitle: FutureBuilder<NotificationSettings>(
                future: _notificationService.getSettings(),
                builder: (context, snapshot) {
                  // Display current time
                },
              ),
              onTap: () async {
                // Show time picker
                final TimeOfDay? picked = await showTimePicker(
                  context: context,
                  initialTime: TimeOfDay(hour: settings.hour, minute: settings.minute),
                );
                // Update notification time if picked
              },
            ),
          ],
        ],
      ),
    ),
  ),
);
```

**2. Toggle Notification Method:**
```dart
Future<void> _toggleNotifications(bool value) async {
  try {
    // Request permission first if enabling
    if (value) {
      final hasPermission = await _notificationService.requestPermission();
      if (!hasPermission) {
        throw Exception('Notification permission denied');
      }
    }

    // Toggle notification
    await _notificationService.toggleRoutineReminder(value);

    setState(() {
      _notificationsEnabled = value;
      // Update user data if available
    });

    // Show success message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(value ? 'Routine reminders enabled' : 'Routine reminders disabled'),
        backgroundColor: value ? AppColors.successGreen : AppColors.textSecondary,
      ),
    );
  } catch (e) {
    // Handle errors and revert state
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

## 🎯 Service Integration

### App Initialization (`lib/main.dart`):
```dart
void main() async {
  try {
    // Create service instances
    final notificationService = NotificationService.instance;  // Singleton instance
    
    // Initialize NotificationService
    try {
      debugPrint('⚙️ App: Initializing NotificationService');
      await notificationService.init();  // Full initialization
      debugPrint('✅ App: NotificationService initialized');
    } catch (e) {
      debugPrint('❌ App: NotificationService initialization failed: $e');
      // Retry once with delay
      await Future.delayed(const Duration(milliseconds: 500));
      await notificationService.init();
      debugPrint('✅ App: NotificationService initialized on retry');
    }

    runApp(
      MultiProvider(
        providers: [
          Provider<NotificationService>.value(value: notificationService),  // Provide to widget tree
          // ... other providers ...
        ],
        child: const BeautyGlowApp(),
      ),
    );
  } catch (e, stackTrace) {
    debugPrint('❌ App: Error during initialization: $e');
    // ... error handling ...
  }
}
```

## ⚡ Key Features

### ✅ **Implemented Features:**
- **Local Notifications**: Uses flutter_local_notifications plugin v19.2.1
- **Daily Scheduling**: Automatic daily reminders at user-selected time
- **Permission Handling**: Runtime permission requests for both platforms
- **Timezone Support**: Automatic timezone detection and handling
- **Persistent Settings**: Hive database for notification preferences
- **UI Integration**: Complete settings interface with switch and time picker
- **Error Handling**: Comprehensive error handling and retry logic
- **Platform Support**: iOS and Android specific configurations
- **Singleton Service**: Single instance notification service
- **Automatic Rescheduling**: Self-renewing daily notifications

### 🎨 **UI Components:**
- **Settings Dialog**: Modal dialog with notification preferences
- **Toggle Switch**: Enable/disable notifications with immediate feedback
- **Time Picker**: Native time picker for selecting reminder time
- **Real-time Display**: Shows current notification time setting
- **Error Feedback**: SnackBar messages for success/error states

### 🔧 **Technical Details:**
- **Notification ID**: Uses ID 0 for daily reminders, 999 for test notifications
- **Channel ID**: 'beauty_reminder' for Android notification channel
- **Storage**: Hive box named 'notification_settings' with typeId 7
- **Default Time**: 8:00 PM (20:00) as default reminder time
- **Scheduling**: Uses Future.delayed() for timed execution

### ❌ **Limitations:**
- **Local Only**: These are local notifications, not push notifications
- **App Dependency**: Notifications only work when app has been opened recently
- **Simple Scheduling**: Basic daily scheduling (no complex patterns)
- **Single Reminder**: Only one daily reminder type implemented

## 🔧 Usage Examples

### Enable Notifications:
```dart
final notificationService = NotificationService.instance;
await notificationService.toggleRoutineReminder(true);
```

### Change Notification Time:
```dart
await notificationService.updateNotificationTime(9, 30); // 9:30 AM
```

### Check Current Settings:
```dart
final settings = await notificationService.getSettings();
print('Enabled: ${settings.enabled}');
print('Time: ${settings.hour}:${settings.minute}');
```

### Request Permissions:
```dart
final hasPermission = await notificationService.requestPermission();
if (hasPermission) {
  // Enable notifications
} else {
  // Show permission denied message
}
```

## 🐛 Debugging & Troubleshooting

### Common Issues:

1. **Notifications Not Showing:**
   - Check permissions in device settings
   - Verify timezone configuration
   - Check if exact alarm permission is granted (Android 12+)

2. **Time Scheduling Issues:**
   - Ensure timezone is properly detected
   - Check device time settings
   - Verify delay calculation logic

3. **Hive Storage Issues:**
   - Check if box is properly opened
   - Verify adapter registration
   - Handle box corruption gracefully

### Debug Logs:
The service includes extensive logging with `[NotificationService]` prefix for easy debugging.

## 📱 Platform-Specific Notes

### Android:
- Requires POST_NOTIFICATIONS permission (API 33+)
- Requires SCHEDULE_EXACT_ALARM permission (API 31+)
- Uses notification channels for better organization
- Supports rich notification features (LED, vibration, actions)

### iOS:
- Permissions requested through plugin
- Uses badge numbers and sound alerts
- Category identifiers for notification grouping
- Alert, badge, and sound permissions handled separately

---

**📝 Note**: This system implements **local notifications**, not push notifications. For true push notifications, you would need to integrate Firebase Cloud Messaging (FCM) or Apple Push Notification Service (APNs). 