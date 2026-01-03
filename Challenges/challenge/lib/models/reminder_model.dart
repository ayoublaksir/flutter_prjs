// lib/models/reminder_model.dart
import 'package:flutter/material.dart';

class ReminderModel {
  final String id;
  final String challengeId;
  final TimeOfDay time;
  final String message;
  final bool isEnabled;
  final List<int> activeDays; // 0 = Sunday, 6 = Saturday

  ReminderModel({
    required this.id,
    required this.challengeId,
    required this.time,
    required this.message,
    this.isEnabled = true,
    required this.activeDays,
  });

  factory ReminderModel.fromJson(Map<String, dynamic> json) => ReminderModel(
    id: json['id'],
    challengeId: json['challengeId'],
    time: TimeOfDay(hour: json['hour'], minute: json['minute']),
    message: json['message'],
    isEnabled: json['isEnabled'],
    activeDays: List<int>.from(json['activeDays']),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'challengeId': challengeId,
    'hour': time.hour,
    'minute': time.minute,
    'message': message,
    'isEnabled': isEnabled,
    'activeDays': activeDays,
  };
}
