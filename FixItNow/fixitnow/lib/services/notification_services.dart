// services/notification_services.dart
// Notification handling for push notifications

import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/app_models.dart';
import '../models/notification_models.dart';
import '../services/firebase_service.dart';

class PushNotificationService {
  final FirebaseMessaging _fcm = FirebaseService.messaging;
  final FirebaseFirestore _firestore = FirebaseService.firestore;
  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  // Initialize notification channels and request permissions
  Future<void> initialize() async {
    // Request permission (iOS)
    NotificationSettings settings = await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print('User granted permission');

      // Initialize local notifications
      const AndroidInitializationSettings initializationSettingsAndroid =
          AndroidInitializationSettings('@mipmap/ic_launcher');

      const DarwinInitializationSettings initializationSettingsIOS =
          DarwinInitializationSettings(
            requestAlertPermission: false,
            requestBadgePermission: false,
            requestSoundPermission: false,
          );

      const InitializationSettings initializationSettings =
          InitializationSettings(
            android: initializationSettingsAndroid,
            iOS: initializationSettingsIOS,
          );

      await _flutterLocalNotificationsPlugin.initialize(
        initializationSettings,
        onDidReceiveNotificationResponse: (NotificationResponse response) {
          // Handle notification tap
          _handleNotificationTap(json.decode(response.payload ?? '{}'));
        },
      );

      // Create Android notification channel
      if (Platform.isAndroid) {
        const AndroidNotificationChannel channel = AndroidNotificationChannel(
          'high_importance_channel',
          'High Importance Notifications',
          description: 'This channel is used for important notifications.',
          importance: Importance.high,
        );

        await _flutterLocalNotificationsPlugin
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >()
            ?.createNotificationChannel(channel);
      }

      // Handle foreground messages
      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

      // Handle background/terminated messages
      FirebaseMessaging.onBackgroundMessage(
        _firebaseMessagingBackgroundHandler,
      );

      // Handle message open events
      FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);
    } else {
      print('User declined permission');
    }
  }

  // Get FCM token for device
  Future<String?> getToken() async {
    return await _fcm.getToken();
  }

  // For compatibility with notification_settings_controller
  Future<String?> getDeviceToken() async {
    return await getToken();
  }

  // Register device token
  Future<void> registerDeviceToken(String userId, String token) async {
    await _firestore.collection('users').doc(userId).update({
      'fcmTokens': FieldValue.arrayUnion([token]),
      'lastTokenUpdate': FieldValue.serverTimestamp(),
    });
  }

  // Unregister device token
  Future<void> unregisterDeviceToken(String userId, String token) async {
    await _firestore.collection('users').doc(userId).update({
      'fcmTokens': FieldValue.arrayRemove([token]),
    });
  }

  // Subscribe to topic
  Future<void> subscribeToTopic(String topic) async {
    await _fcm.subscribeToTopic(topic);
  }

  // Unsubscribe from topic
  Future<void> unsubscribeFromTopic(String topic) async {
    await _fcm.unsubscribeFromTopic(topic);
  }

  // Save FCM token to Firestore
  Future<void> saveTokenToFirestore(String userId) async {
    // Get token
    String? token = await getToken();

    if (token != null) {
      // Save to Firestore
      await _firestore.collection('users').doc(userId).update({
        'fcmTokens': FieldValue.arrayUnion([token]),
        'lastTokenUpdate': FieldValue.serverTimestamp(),
      });

      // Save locally
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('fcm_token', token);
    }
  }

  // Remove FCM token from Firestore (logout)
  Future<void> removeTokenFromFirestore(String userId) async {
    // Get token
    final prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('fcm_token');

    if (token != null) {
      // Remove from Firestore
      await _firestore.collection('users').doc(userId).update({
        'fcmTokens': FieldValue.arrayRemove([token]),
      });

      // Remove locally
      await prefs.remove('fcm_token');
    }
  }

  // Handle foreground message
  void _handleForegroundMessage(RemoteMessage message) {
    print('Handling foreground message: ${message.messageId}');

    RemoteNotification? notification = message.notification;
    AndroidNotification? android = message.notification?.android;

    // Show notification if it has title and body
    if (notification != null && android != null) {
      _flutterLocalNotificationsPlugin.show(
        notification.hashCode,
        notification.title,
        notification.body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            'high_importance_channel',
            'High Importance Notifications',
            channelDescription:
                'This channel is used for important notifications.',
            importance: Importance.high,
            priority: Priority.high,
            showWhen: true,
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        payload: json.encode(message.data),
      );
    }

    // Save notification to Firestore
    _saveNotificationToFirestore(message);
  }

  // Handle notification tap
  void _handleNotificationTap(dynamic message) {
    print('Notification tapped: $message');

    // Navigate to specific screen based on notification type
    if (message is Map<String, dynamic> && message.containsKey('type')) {
      String type = message['type'];
      String? id = message['id'];

      switch (type) {
        case 'booking':
          // Navigate to booking details
          if (id != null) {
            // context.pushNamed('booking-details', params: {'id': id});
            // TODO: Navigation to be implemented with global navigator
          }
          break;
        case 'chat':
          // Navigate to chat
          if (id != null) {
            // context.pushNamed('chat', params: {'id': id});
            // TODO: Navigation to be implemented with global navigator
          }
          break;
        case 'promotion':
          // Navigate to promotion
          // context.pushNamed('promotions');
          // TODO: Navigation to be implemented with global navigator
          break;
        default:
          // Navigate to notifications
          // context.pushNamed('notifications');
          // TODO: Navigation to be implemented with global navigator
          break;
      }
    }
  }

  // Save notification to Firestore
  Future<void> _saveNotificationToFirestore(RemoteMessage message) async {
    try {
      String? userId = message.data['userId'];

      if (userId != null) {
        await _firestore.collection('notifications').add({
          'userId': userId,
          'title': message.notification?.title ?? '',
          'body': message.notification?.body ?? '',
          'data': message.data,
          'read': false,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      print('Error saving notification: $e');
    }
  }

  // Get user notifications
  Stream<QuerySnapshot> getUserNotifications(String userId) {
    return _firestore
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  // Mark notification as read
  Future<void> markNotificationAsRead(String notificationId) async {
    await _firestore.collection('notifications').doc(notificationId).update({
      'read': true,
      'readAt': FieldValue.serverTimestamp(),
    });
  }

  // Mark all notifications as read
  Future<void> markAllNotificationsAsRead(String userId) async {
    // Get all unread notifications
    QuerySnapshot unreadNotifications =
        await _firestore
            .collection('notifications')
            .where('userId', isEqualTo: userId)
            .where('read', isEqualTo: false)
            .get();

    // Update each notification
    for (DocumentSnapshot doc in unreadNotifications.docs) {
      await doc.reference.update({
        'read': true,
        'readAt': FieldValue.serverTimestamp(),
      });
    }
  }

  // Delete notification
  Future<void> deleteNotification(String notificationId) async {
    await _firestore.collection('notifications').doc(notificationId).delete();
  }

  // Clear all notifications
  Future<void> clearAllNotifications(String userId) async {
    // Get all user notifications
    QuerySnapshot notifications =
        await _firestore
            .collection('notifications')
            .where('userId', isEqualTo: userId)
            .get();

    // Delete each notification
    for (DocumentSnapshot doc in notifications.docs) {
      await doc.reference.delete();
    }
  }

  // Subscribe to user notifications
  void subscribeToUserNotifications({
    required String userId,
    required Function(UserNotification) onNotification,
  }) {
    if (userId.isEmpty) return;

    _firestore
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .listen((snapshot) {
          for (var change in snapshot.docChanges) {
            // Only process new notifications
            if (change.type == DocumentChangeType.added) {
              final notification = UserNotification.fromMap({
                ...change.doc.data() as Map<String, dynamic>,
                'id': change.doc.id,
              });
              onNotification(notification);
            }
          }
        });
  }
}

// Background message handler (must be top-level function)
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print('Handling background message: ${message.messageId}');

  // Save notification to local storage for later handling
  // This won't save to Firestore because this function runs in a separate isolate
  final prefs = await SharedPreferences.getInstance();
  List<String> notifications =
      prefs.getStringList('background_notifications') ?? [];
  notifications.add(
    json.encode({
      'title': message.notification?.title,
      'body': message.notification?.body,
      'data': message.data,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    }),
  );
  await prefs.setStringList('background_notifications', notifications);
}

// Notification manager class
class NotificationManager {
  final PushNotificationService _pushNotificationService =
      PushNotificationService();

  // Initialize
  Future<void> initialize() async {
    await _pushNotificationService.initialize();
  }

  // Setup user-specific notifications
  Future<void> setupUserNotifications(String userId, String role) async {
    await _pushNotificationService.saveTokenToFirestore(userId);

    // Subscribe to relevant topics
    await _pushNotificationService.subscribeToTopic('all_users');
    await _pushNotificationService.subscribeToTopic(role);

    // User-specific topics
    await _pushNotificationService.subscribeToTopic('user_$userId');
  }

  // Clean up on logout
  Future<void> cleanupOnLogout(String userId) async {
    await _pushNotificationService.removeTokenFromFirestore(userId);

    // Unsubscribe from topics
    await _pushNotificationService.unsubscribeFromTopic('all_users');
    await _pushNotificationService.unsubscribeFromTopic('user_$userId');
  }

  // Get user notifications stream
  Stream<QuerySnapshot> getUserNotifications(String userId) {
    return _pushNotificationService.getUserNotifications(userId);
  }

  // Mark notification as read
  Future<void> markNotificationAsRead(String notificationId) async {
    await _pushNotificationService.markNotificationAsRead(notificationId);
  }

  // Mark all notifications as read
  Future<void> markAllNotificationsAsRead(String userId) async {
    await _pushNotificationService.markAllNotificationsAsRead(userId);
  }

  // Clear all notifications
  Future<void> clearAllNotifications(String userId) async {
    await _pushNotificationService.clearAllNotifications(userId);
  }

  // Process any background notifications received while app was closed
  Future<void> processBackgroundNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    List<String> notifications =
        prefs.getStringList('background_notifications') ?? [];

    if (notifications.isNotEmpty) {
      // TODO: Process stored notifications

      // Clear the list after processing
      await prefs.setStringList('background_notifications', []);
    }
  }
}
