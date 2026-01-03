// lib/services/database_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/challenge_model.dart';
import '../models/user_model.dart';
import '../models/reminder_model.dart';
import '../utils/date_extensions.dart';

class DatabaseService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // User Operations
  Future<UserModel> getUser(String uid) async {
    try {
      final doc = await _db.collection('users').doc(uid).get();
      if (!doc.exists) {
        throw Exception('User not found');
      }
      final data = doc.data()!;
      data['id'] = doc.id;
      return UserModel.fromJson(data);
    } catch (e) {
      throw Exception('Failed to get user: $e');
    }
  }

  Future<void> createUser(UserModel user) async {
    await _db.collection('users').doc(user.id).set(user.toJson());
  }

  Future<void> updateUser(UserModel user) async {
    await _db.collection('users').doc(user.id).update(user.toJson());
  }

  Stream<UserModel> getUserStream(String uid) {
    return _db.collection('users').doc(uid).snapshots().map((doc) {
      final data = doc.data()!;
      data['id'] = doc.id;
      return UserModel.fromJson(data);
    });
  }

  // Challenge Operations
  Stream<List<ChallengeModel>> getUserChallenges(String userId) {
    return _db
        .collection('challenges')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs
                  .map(
                    (doc) =>
                        ChallengeModel.fromJson(doc.data()..['id'] = doc.id),
                  )
                  .toList(),
        );
  }

  Future<void> createChallenge(ChallengeModel challenge) async {
    await _db.collection('challenges').add(challenge.toJson());
  }

  Future<void> updateChallenge(ChallengeModel challenge) async {
    await _db
        .collection('challenges')
        .doc(challenge.id)
        .update(challenge.toJson());
  }

  // Reminder Operations
  Future<void> createReminder(ReminderModel reminder) async {
    await _db.collection('reminders').add(reminder.toJson());
  }

  Stream<List<ReminderModel>> getChallengeReminders(String challengeId) {
    return _db
        .collection('reminders')
        .where('challengeId', isEqualTo: challengeId)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs
                  .map(
                    (doc) =>
                        ReminderModel.fromJson(doc.data()..['id'] = doc.id),
                  )
                  .toList(),
        );
  }

  Future<void> updateChallengeProgress(
    String challengeId,
    DayProgress progress,
  ) async {
    final doc = await _db.collection('challenges').doc(challengeId).get();
    if (!doc.exists) throw Exception('Challenge not found');

    final challenge = ChallengeModel.fromJson(doc.data()!..['id'] = doc.id);
    final today = DateTime.now().startOfDay;

    // Prevent multiple check-ins same day
    if (challenge.hasCheckedInToday()) {
      throw Exception('Already checked in for today');
    }

    // Add new progress entry
    final updatedProgress = List<Map<String, dynamic>>.from(
      challenge.progress.map((p) => p.toJson()),
    );
    updatedProgress.add(progress.toJson());

    // Calculate streaks
    int currentStreak = 0;
    if (progress.completed) {
      if (challenge.progress.isEmpty) {
        currentStreak = 1; // First day completed
      } else {
        final lastProgress = challenge.progress.last;
        final daysDifference =
            today.difference(lastProgress.date.startOfDay).inDays;

        if (daysDifference == 1 && lastProgress.completed) {
          // Continuing streak
          currentStreak = challenge.currentStreak + 1;
        } else if (daysDifference > 1) {
          // Missed a day - streak broken
          currentStreak = 1;
        }
      }
    }

    // Update longest streak if current is higher
    int longestStreak =
        currentStreak > challenge.longestStreak
            ? currentStreak
            : challenge.longestStreak;

    // Save to database
    await _db.collection('challenges').doc(challengeId).update({
      'progress': updatedProgress,
      'currentStreak': currentStreak,
      'longestStreak': longestStreak,
      'lastCheckIn': today.toIso8601String(),
    });
  }
}
