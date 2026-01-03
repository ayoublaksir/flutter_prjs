import 'package:cloud_firestore/cloud_firestore.dart';

enum NotificationType { message, match, dateOffer, response, decision }

class NotificationModel {
  final String id;
  final String title;
  final String message;
  final DateTime timestamp;
  final NotificationType type;
  final String relatedId;
  final bool read;

  NotificationModel({
    required this.id,
    required this.title,
    required this.message,
    required this.timestamp,
    required this.type,
    required this.relatedId,
    this.read = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'message': message,
      'timestamp': Timestamp.fromDate(timestamp),
      'type': type.index,
      'relatedId': relatedId,
      'read': read,
    };
  }

  factory NotificationModel.fromMap(Map<String, dynamic> map) {
    return NotificationModel(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      message: map['message'] ?? '',
      timestamp: (map['timestamp'] as Timestamp).toDate(),
      type: NotificationType.values[map['type'] ?? 0],
      relatedId: map['relatedId'] ?? '',
      read: map['read'] ?? false,
    );
  }
}
