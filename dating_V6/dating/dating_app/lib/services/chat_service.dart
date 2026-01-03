import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/chat_message.dart';
import '../models/user_profile.dart';
import '../services/notification_service.dart';
import '../services/user_service.dart';
import 'dart:math';

// Move the ChatPreview class to the top level
class ChatPreview {
  final String userId;
  final String lastMessage;
  final DateTime timestamp;
  final int unreadCount;

  ChatPreview({
    required this.userId,
    required this.lastMessage,
    required this.timestamp,
    required this.unreadCount,
  });

  factory ChatPreview.fromMap(String userId, Map<String, dynamic> data) {
    return ChatPreview(
      userId: userId,
      lastMessage: data['lastMessage'] ?? '',
      timestamp: (data['timestamp'] as Timestamp).toDate(),
      unreadCount: data['unreadCount'] ?? 0,
    );
  }
}

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final NotificationService _notificationService = NotificationService();
  final UserService _userService = UserService();

  // Get a chat ID for two users (consistent regardless of who initiates)
  String getChatId(String userId1, String userId2) {
    // Sort the IDs to ensure the same chat ID regardless of order
    final sortedIds = [userId1, userId2]..sort();
    return '${sortedIds[0]}_${sortedIds[1]}';
  }

  // Send a message
  Future<void> sendMessage({
    required String senderId,
    required String receiverId,
    required String content,
    String? imageUrl,
  }) async {
    print(
      '🔍 sendMessage called - senderId: $senderId, receiverId: $receiverId',
    );
    final chatId = getChatId(senderId, receiverId);
    print('📝 Generated chatId: $chatId');
    final timestamp = DateTime.now();

    try {
      // Create message document
      final messageData =
          ChatMessage(
            id: '', // Will be set by Firestore
            senderId: senderId,
            receiverId: receiverId,
            content: content,
            timestamp: timestamp,
            imageUrl: imageUrl,
          ).toMap();

      print('📄 Message data prepared: $messageData');

      // Add to messages collection
      final messageRef = await _firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .add(messageData);
      print('✅ Message added with ID: ${messageRef.id}');

      // Update chat metadata
      await _firestore.collection('chats').doc(chatId).set({
        'participants': [senderId, receiverId],
        'lastMessage': content,
        'lastMessageTimestamp': Timestamp.fromDate(timestamp),
        'lastMessageSenderId': senderId,
      }, SetOptions(merge: true));
      print('✅ Chat metadata updated');

      // Update sender's chat list
      await _firestore
          .collection('users')
          .doc(senderId)
          .collection('chats')
          .doc(receiverId)
          .set({
            'userId': receiverId,
            'lastMessage': content,
            'timestamp': Timestamp.fromDate(timestamp),
            'unreadCount': 0, // Sender has read their own message
          }, SetOptions(merge: true));
      print('✅ Sender chat list updated');

      // Update receiver's chat list
      await _firestore
          .collection('users')
          .doc(receiverId)
          .collection('chats')
          .doc(senderId)
          .set({
            'userId': senderId,
            'lastMessage': content,
            'timestamp': Timestamp.fromDate(timestamp),
            'unreadCount': FieldValue.increment(
              1,
            ), // Increment unread for receiver
          }, SetOptions(merge: true));
      print('✅ Receiver chat list updated');

      // Send notification
      final senderProfile = await _userService.getUserProfile(senderId);
      if (senderProfile != null) {
        await _notificationService.sendMessageNotification(
          senderId,
          receiverId,
          senderProfile.name,
          content,
        );
      }

      print('✅ Message sent successfully');
    } catch (e) {
      print('❌ Error in sendMessage: $e');
      print('Stack trace: ${StackTrace.current}');
      throw e; // Re-throw to allow caller to handle
    }
  }

  // Get messages for a chat
  Stream<List<ChatMessage>> getMessages(String userId1, String userId2) {
    final chatId = getChatId(userId1, userId2);

    return _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs
                  .map((doc) => ChatMessage.fromFirestore(doc))
                  .toList(),
        );
  }

  // Mark messages as read
  Future<void> markMessagesAsRead(
    String currentUserId,
    String otherUserId,
  ) async {
    final chatId = getChatId(currentUserId, otherUserId);

    // Get unread messages
    final unreadMessages =
        await _firestore
            .collection('chats')
            .doc(chatId)
            .collection('messages')
            .where('receiverId', isEqualTo: currentUserId)
            .where('status', isLessThan: MessageStatus.read.index)
            .get();

    // Update each message
    final batch = _firestore.batch();
    for (var doc in unreadMessages.docs) {
      batch.update(doc.reference, {'status': MessageStatus.read.index});
    }

    // Reset unread count
    batch.update(
      _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('chats')
          .doc(otherUserId),
      {'unreadCount': 0},
    );

    await batch.commit();
  }

  // Get user's chat list
  Stream<List<Map<String, dynamic>>> getUserChats(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('chats')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .asyncMap((snapshot) async {
          List<Map<String, dynamic>> chats = [];

          for (var doc in snapshot.docs) {
            final data = doc.data();
            final otherUserId = data['userId'];

            // Get other user's profile
            final userDoc =
                await _firestore.collection('users').doc(otherUserId).get();
            final userData = userDoc.data() ?? {};

            chats.add({
              'userId': otherUserId,
              'name': userData['name'] ?? 'Unknown',
              'profileImageUrl': userData['profileImageUrl'],
              'lastMessage': data['lastMessage'] ?? '',
              'timestamp': (data['timestamp'] as Timestamp).toDate(),
              'unreadCount': data['unreadCount'] ?? 0,
            });
          }

          return chats;
        });
  }

  // Delete a message (mark as deleted)
  Future<void> deleteMessage(
    String messageId,
    String userId1,
    String userId2,
  ) async {
    final chatId = getChatId(userId1, userId2);

    await _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .doc(messageId)
        .update({'isDeleted': true});
  }

  // Add this method to your ChatService class
  Stream<List<ChatPreview>> getUserChatList(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('chats')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            return ChatPreview.fromMap(doc.id, doc.data());
          }).toList();
        });
  }

  // Add this debug method to ChatService
  Future<void> debugChatData(String userId) async {
    try {
      print('🔍 Debugging chat data for user: $userId');

      // Check if user document exists
      final userDoc = await _firestore.collection('users').doc(userId).get();
      print('👤 User document exists: ${userDoc.exists}');

      // Check user's chat list
      final chatListSnapshot =
          await _firestore
              .collection('users')
              .doc(userId)
              .collection('chats')
              .get();

      print('📋 Chat list count: ${chatListSnapshot.docs.length}');

      if (chatListSnapshot.docs.isEmpty) {
        print('⚠️ No chats found for user $userId');

        // Check if there are any chats where this user is a participant
        final chatsQuery =
            await _firestore
                .collection('chats')
                .where('participants', arrayContains: userId)
                .get();

        print(
          '🔍 Found ${chatsQuery.docs.length} chats with user as participant',
        );

        for (var chatDoc in chatsQuery.docs) {
          print('📝 Chat ID: ${chatDoc.id}');
          print('📝 Chat data: ${chatDoc.data()}');

          // Check messages in this chat
          final messagesSnapshot =
              await _firestore
                  .collection('chats')
                  .doc(chatDoc.id)
                  .collection('messages')
                  .get();

          print('📝 Message count: ${messagesSnapshot.docs.length}');

          // This is a potential issue - chat exists but not in user's chat list
          print('⚠️ Chat exists but not in user\'s chat list. Fixing...');

          // Try to fix by adding to user's chat list
          if (messagesSnapshot.docs.isNotEmpty) {
            final lastMessage = messagesSnapshot.docs
                .map((doc) => ChatMessage.fromFirestore(doc))
                .reduce((a, b) => a.timestamp.isAfter(b.timestamp) ? a : b);

            final otherUserId =
                lastMessage.senderId == userId
                    ? lastMessage.receiverId
                    : lastMessage.senderId;

            await _firestore
                .collection('users')
                .doc(userId)
                .collection('chats')
                .doc(otherUserId)
                .set({
                  'userId': otherUserId,
                  'lastMessage': lastMessage.content,
                  'timestamp': Timestamp.fromDate(lastMessage.timestamp),
                  'unreadCount': 0,
                });

            print('✅ Fixed missing chat entry for user');
          }
        }
      }

      for (var doc in chatListSnapshot.docs) {
        print('👥 Chat with user: ${doc.id}');
        print('📝 Chat data: ${doc.data()}');

        // Check if other user exists
        final otherUserDoc =
            await _firestore.collection('users').doc(doc.id).get();
        print('👤 Other user exists: ${otherUserDoc.exists}');

        // Check messages in this chat
        final chatId = getChatId(userId, doc.id);
        print('🔑 Chat ID: $chatId');

        final messagesSnapshot =
            await _firestore
                .collection('chats')
                .doc(chatId)
                .collection('messages')
                .get();

        print('📝 Message count: ${messagesSnapshot.docs.length}');

        if (messagesSnapshot.docs.isEmpty) {
          print('⚠️ No messages found for chat between $userId and ${doc.id}');
        } else {
          // Print the first few messages
          final messages =
              messagesSnapshot.docs
                  .map((doc) => ChatMessage.fromFirestore(doc))
                  .toList()
                ..sort((a, b) => b.timestamp.compareTo(a.timestamp));

          print('📝 Latest messages:');
          for (var i = 0; i < min(3, messages.length); i++) {
            print('📩 ${messages[i].senderId}: ${messages[i].content}');
          }
        }
      }
    } catch (e) {
      print('❌ Error debugging chat data: $e');
      print('Stack trace: ${StackTrace.current}');
    }
  }

  // Add this method to ChatService
  Future<void> repairChatData(String userId) async {
    try {
      print('🔧 Repairing chat data for user: $userId');

      // Find all chats where this user is a participant
      final chatsQuery =
          await _firestore
              .collection('chats')
              .where('participants', arrayContains: userId)
              .get();

      print(
        '🔍 Found ${chatsQuery.docs.length} chats with user as participant',
      );

      for (var chatDoc in chatsQuery.docs) {
        final chatId = chatDoc.id;
        print('🔧 Repairing chat: $chatId');

        // Get the participants
        final participants = List<String>.from(
          chatDoc.data()['participants'] ?? [],
        );
        if (participants.length != 2) {
          print('⚠️ Unexpected number of participants: ${participants.length}');
          continue;
        }

        // Get the other user ID
        final otherUserId = participants.firstWhere(
          (id) => id != userId,
          orElse: () => '',
        );
        if (otherUserId.isEmpty) {
          print('⚠️ Could not find other user ID');
          continue;
        }

        // Check messages in this chat
        final messagesSnapshot =
            await _firestore
                .collection('chats')
                .doc(chatId)
                .collection('messages')
                .orderBy('timestamp', descending: true)
                .limit(1)
                .get();

        if (messagesSnapshot.docs.isEmpty) {
          print('⚠️ No messages found for chat');
          continue;
        }

        // Get the last message
        final lastMessageDoc = messagesSnapshot.docs.first;
        final lastMessage = ChatMessage.fromFirestore(lastMessageDoc);

        // Update user's chat list
        await _firestore
            .collection('users')
            .doc(userId)
            .collection('chats')
            .doc(otherUserId)
            .set({
              'userId': otherUserId,
              'lastMessage': lastMessage.content,
              'timestamp': Timestamp.fromDate(lastMessage.timestamp),
              'unreadCount': lastMessage.receiverId == userId ? 1 : 0,
            }, SetOptions(merge: true));

        print('✅ Repaired chat entry for user');
      }

      print('✅ Chat data repair completed');
    } catch (e) {
      print('❌ Error repairing chat data: $e');
      print('Stack trace: ${StackTrace.current}');
    }
  }

  // Add this test method to ChatService
  Future<void> createTestChat(String userId1, String userId2) async {
    try {
      print('🧪 Creating test chat between $userId1 and $userId2');

      // Get user profiles
      final user1 = await _userService.getUserProfile(userId1);
      final user2 = await _userService.getUserProfile(userId2);

      if (user1 == null || user2 == null) {
        print('❌ One or both users not found');
        return;
      }

      print('👤 User 1: ${user1.name}');
      print('👤 User 2: ${user2.name}');

      // Send a test message from user1 to user2
      await sendMessage(
        senderId: userId1,
        receiverId: userId2,
        content:
            "Hello! This is a test message from ${user1.name} to ${user2.name}.",
      );

      // Send a test message from user2 to user1
      await sendMessage(
        senderId: userId2,
        receiverId: userId1,
        content:
            "Hi there! This is a test reply from ${user2.name} to ${user1.name}.",
      );

      print('✅ Test chat created successfully');
    } catch (e) {
      print('❌ Error creating test chat: $e');
      print('Stack trace: ${StackTrace.current}');
    }
  }
}
