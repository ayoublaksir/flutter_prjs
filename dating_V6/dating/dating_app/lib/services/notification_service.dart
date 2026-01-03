import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/notification.dart';

class NotificationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'notifications';

  // Send notification when user responds to date offer
  Future<void> sendResponseNotification({
    required String toUserId,
    required String fromUserId,
    required String fromUserName,
    String? fromUserImageUrl,
    required String offerId,
    required String offerTitle,
  }) async {
    final notification = NotificationModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: 'Date Offer Response',
      message: '$fromUserName responded to your date offer: $offerTitle',
      timestamp: DateTime.now(),
      type: NotificationType.response,
      relatedId: offerId,
    );

    await _firestore.collection(_collection).add(notification.toMap());
  }

  // Send notification when offer creator accepts/declines response
  Future<void> sendDecisionNotification({
    required String toUserId,
    required String fromUserId,
    required String fromUserName,
    required String offerId,
    required String offerTitle,
    required bool accepted,
  }) async {
    final notification = NotificationModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: accepted ? 'Date Offer Accepted' : 'Date Offer Declined',
      message:
          accepted
              ? '$fromUserName accepted your response to: $offerTitle'
              : '$fromUserName declined your response to: $offerTitle',
      timestamp: DateTime.now(),
      type: accepted ? NotificationType.match : NotificationType.decision,
      relatedId: offerId,
    );

    await _firestore.collection(_collection).add(notification.toMap());
  }

  // Get user's notifications
  Stream<List<NotificationModel>> getUserNotifications(String userId) {
    return _firestore
        .collection(_collection)
        .where('toUserId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs
                  .map((doc) => NotificationModel.fromMap(doc.data()))
                  .toList(),
        );
  }

  // Mark notification as read
  Future<void> markAsRead(String notificationId) async {
    await _firestore.collection(_collection).doc(notificationId).update({
      'read': true,
    });
  }

  Future<void> sendNotification(
    String userId,
    String title,
    String body,
  ) async {
    await _firestore.collection('notifications').add({
      'userId': userId,
      'title': title,
      'body': body,
      'isRead': false,
      'createdAt': FieldValue.serverTimestamp(),
    });

    // In a real app, you would integrate with FCM (Firebase Cloud Messaging)
    // to send push notifications to the user's device
  }

  Future<void> sendMessageNotification(
    String senderId,
    String receiverId,
    String senderName,
    String message,
  ) async {
    try {
      // Create notification
      final notification = NotificationModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: 'New Message from $senderName',
        message: message,
        timestamp: DateTime.now(),
        type: NotificationType.message,
        relatedId: senderId,
      );

      // Save to Firestore
      await _firestore
          .collection('users')
          .doc(receiverId)
          .collection('notifications')
          .add(notification.toMap());

      // Update unread count
      await _firestore.collection('users').doc(receiverId).update({
        'unreadNotifications': FieldValue.increment(1),
      });
    } catch (e) {
      print('Error sending message notification: $e');
    }
  }
}
