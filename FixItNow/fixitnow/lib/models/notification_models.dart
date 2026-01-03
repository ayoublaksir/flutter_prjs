// models/notification_models.dart
// Contains notification-related models

import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';

// Notification types
enum NotificationType { booking, message, payment, review, general }

class UserNotification {
  final String id;
  final String userId;
  final String title;
  final String message;
  final String type;
  final DateTime timestamp;
  final bool isRead;
  final String? actionRoute;
  final Map<String, dynamic>? actionArguments;
  final Map<String, dynamic> data;

  UserNotification({
    required this.id,
    required this.userId,
    required this.title,
    required this.message,
    required this.type,
    required this.timestamp,
    this.isRead = false,
    this.actionRoute,
    this.actionArguments,
    required this.data,
  });

  UserNotification copyWith({
    String? id,
    String? userId,
    String? title,
    String? message,
    String? type,
    DateTime? timestamp,
    bool? isRead,
    String? actionRoute,
    Map<String, dynamic>? actionArguments,
    Map<String, dynamic>? data,
  }) {
    return UserNotification(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      message: message ?? this.message,
      type: type ?? this.type,
      timestamp: timestamp ?? this.timestamp,
      isRead: isRead ?? this.isRead,
      actionRoute: actionRoute ?? this.actionRoute,
      actionArguments: actionArguments ?? this.actionArguments,
      data: data ?? this.data,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'title': title,
      'message': message,
      'type': type,
      'timestamp': timestamp,
      'isRead': isRead,
      'actionRoute': actionRoute,
      'actionArguments': actionArguments,
      'data': data,
    };
  }

  factory UserNotification.fromMap(Map<String, dynamic> map) {
    return UserNotification(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      title: map['title'] ?? '',
      message: map['message'] ?? '',
      type: map['type'] ?? 'general',
      timestamp: (map['timestamp'] as Timestamp).toDate(),
      isRead: map['isRead'] ?? false,
      actionRoute: map['actionRoute'],
      actionArguments:
          map['actionArguments'] != null
              ? Map<String, dynamic>.from(map['actionArguments'])
              : null,
      data: Map<String, dynamic>.from(map['data'] ?? {}),
    );
  }
}
