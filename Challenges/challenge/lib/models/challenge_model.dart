// lib/models/challenge_model.dart
import '../utils/date_extensions.dart';

class ChallengeModel {
  final String id;
  final String userId;
  final String title;
  final String description;
  final DateTime startDate;
  final int duration;
  final List<DayProgress> progress;
  final String motivation;
  final bool isCompleted;
  final int currentStreak;
  final int longestStreak;

  ChallengeModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.description,
    required this.startDate,
    this.duration = 30,
    required this.progress,
    required this.motivation,
    this.isCompleted = false,
    this.currentStreak = 0,
    this.longestStreak = 0,
  });

  factory ChallengeModel.fromJson(Map<String, dynamic> json) => ChallengeModel(
    id: json['id'],
    userId: json['userId'],
    title: json['title'],
    description: json['description'],
    startDate: DateTime.parse(json['startDate']),
    duration: json['duration'],
    progress:
        (json['progress'] as List?)
            ?.map((x) => DayProgress.fromJson(x))
            .toList() ??
        [],
    motivation: json['motivation'],
    isCompleted: json['isCompleted'] ?? false,
    currentStreak: json['currentStreak'] ?? 0,
    longestStreak: json['longestStreak'] ?? 0,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'userId': userId,
    'title': title,
    'description': description,
    'startDate': startDate.toIso8601String(),
    'duration': duration,
    'progress': progress.map((p) => p.toJson()).toList(),
    'motivation': motivation,
    'isCompleted': isCompleted,
    'currentStreak': currentStreak,
    'longestStreak': longestStreak,
  };

  bool hasMissedDay() {
    if (progress.isEmpty) return false;

    final today = DateTime.now().startOfDay;
    final lastCheckIn = progress.last.date.startOfDay;
    final daysDifference = today.difference(lastCheckIn).inDays;

    // If more than 1 day has passed since last check-in
    return daysDifference > 1;
  }

  bool hasCheckedInToday() {
    final today = DateTime.now().startOfDay;
    return progress.any((p) => p.date.startOfDay == today);
  }
}

class DayProgress {
  final DateTime date;
  final bool completed;
  final String? note;
  final String? photoUrl;

  DayProgress({
    required this.date,
    required this.completed,
    this.note,
    this.photoUrl,
  });

  factory DayProgress.fromJson(Map<String, dynamic> json) => DayProgress(
    date: DateTime.parse(json['date']),
    completed: json['completed'],
    note: json['note'],
    photoUrl: json['photoUrl'],
  );

  Map<String, dynamic> toJson() => {
    'date': date.toIso8601String(),
    'completed': completed,
    'note': note,
    'photoUrl': photoUrl,
  };
}
