// models/chat_models.dart
// Contains all chat-related models

import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';

// Message model
class Message {
  final String id;
  final String conversationId;
  final String senderId;
  final String content;
  final DateTime timestamp;
  final bool isRead;
  final String? mediaUrl;
  final String mediaType; // 'image', 'document', 'location'

  Message({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.content,
    required this.timestamp,
    this.isRead = false,
    this.mediaUrl,
    this.mediaType = '',
  });

  Message copyWith({
    String? id,
    String? conversationId,
    String? senderId,
    String? content,
    DateTime? timestamp,
    bool? isRead,
    String? mediaUrl,
    String? mediaType,
  }) {
    return Message(
      id: id ?? this.id,
      conversationId: conversationId ?? this.conversationId,
      senderId: senderId ?? this.senderId,
      content: content ?? this.content,
      timestamp: timestamp ?? this.timestamp,
      isRead: isRead ?? this.isRead,
      mediaUrl: mediaUrl ?? this.mediaUrl,
      mediaType: mediaType ?? this.mediaType,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'conversationId': conversationId,
      'senderId': senderId,
      'content': content,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'isRead': isRead,
      'mediaUrl': mediaUrl,
      'mediaType': mediaType,
    };
  }

  factory Message.fromMap(Map<String, dynamic> map) {
    return Message(
      id: map['id'] ?? '',
      conversationId: map['conversationId'] ?? '',
      senderId: map['senderId'] ?? '',
      content: map['content'] ?? '',
      timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp']),
      isRead: map['isRead'] ?? false,
      mediaUrl: map['mediaUrl'],
      mediaType: map['mediaType'] ?? '',
    );
  }

  String toJson() => json.encode(toMap());

  factory Message.fromJson(String source) =>
      Message.fromMap(json.decode(source));
}

// Conversation model
class Conversation {
  final String id;
  final List<String> participants;
  final Message? latestMessage;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? bookingId;
  final Map<String, int> unreadCount;
  final String title;
  final Map<String, UserInfo> participantsInfo;

  Conversation({
    required this.id,
    required this.participants,
    this.latestMessage,
    required this.createdAt,
    required this.updatedAt,
    this.bookingId,
    required this.unreadCount,
    this.title = '',
    this.participantsInfo = const {},
  });

  Conversation copyWith({
    String? id,
    List<String>? participants,
    Message? latestMessage,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? bookingId,
    Map<String, int>? unreadCount,
    String? title,
    Map<String, UserInfo>? participantsInfo,
  }) {
    return Conversation(
      id: id ?? this.id,
      participants: participants ?? this.participants,
      latestMessage: latestMessage ?? this.latestMessage,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      bookingId: bookingId ?? this.bookingId,
      unreadCount: unreadCount ?? this.unreadCount,
      title: title ?? this.title,
      participantsInfo: participantsInfo ?? this.participantsInfo,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'participants': participants,
      'latestMessage': latestMessage?.toMap(),
      'createdAt': createdAt.millisecondsSinceEpoch,
      'updatedAt': updatedAt.millisecondsSinceEpoch,
      'bookingId': bookingId,
      'unreadCount': unreadCount,
      'title': title,
      'participantsInfo': participantsInfo.map(
        (key, value) => MapEntry(key, value.toMap()),
      ),
    };
  }

  factory Conversation.fromMap(Map<String, dynamic> map) {
    return Conversation(
      id: map['id'] ?? '',
      participants: List<String>.from(map['participants'] ?? []),
      latestMessage:
          map['latestMessage'] != null
              ? Message.fromMap(map['latestMessage'])
              : null,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt']),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updatedAt']),
      bookingId: map['bookingId'],
      unreadCount: Map<String, int>.from(map['unreadCount'] ?? {}),
      title: map['title'] ?? '',
      participantsInfo:
          map['participantsInfo'] != null
              ? (map['participantsInfo'] as Map).map(
                (key, value) =>
                    MapEntry(key.toString(), UserInfo.fromMap(value)),
              )
              : {},
    );
  }

  String toJson() => json.encode(toMap());

  factory Conversation.fromJson(String source) =>
      Conversation.fromMap(json.decode(source));
}

class UserInfo {
  final String name;
  final String? image;

  UserInfo({required this.name, this.image});

  Map<String, dynamic> toMap() => {'name': name, 'image': image};

  factory UserInfo.fromMap(Map<String, dynamic> map) {
    return UserInfo(name: map['name'] ?? '', image: map['image']);
  }
}

class ChatMessage {
  final String id;
  final String? bookingId;
  final String senderId;
  final String receiverId;
  final String content;
  final List<String>? images;
  final String? text;
  final DateTime timestamp;
  final bool isRead;

  // For compatibility with existing code, add recipientId accessor
  String get recipientId => receiverId;

  ChatMessage({
    this.id = '',
    this.bookingId,
    required this.senderId,
    required this.receiverId,
    required this.content,
    this.images,
    this.text,
    required this.timestamp,
    required this.isRead,
  });

  // Factory method for Firestore
  factory ChatMessage.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ChatMessage(
      id: doc.id,
      bookingId: data['bookingId'],
      senderId: data['senderId'] ?? '',
      receiverId: data['receiverId'] ?? '',
      content: data['content'] ?? '',
      images: data['images'] != null ? List<String>.from(data['images']) : null,
      text: data['text'],
      timestamp:
          data['timestamp'] != null
              ? DateTime.fromMillisecondsSinceEpoch(data['timestamp'])
              : DateTime.now(),
      isRead: data['isRead'] ?? false,
    );
  }

  ChatMessage copyWith({
    String? id,
    String? bookingId,
    String? senderId,
    String? receiverId,
    String? content,
    List<String>? images,
    String? text,
    DateTime? timestamp,
    bool? isRead,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      bookingId: bookingId ?? this.bookingId,
      senderId: senderId ?? this.senderId,
      receiverId: receiverId ?? this.receiverId,
      content: content ?? this.content,
      images: images ?? this.images,
      text: text ?? this.text,
      timestamp: timestamp ?? this.timestamp,
      isRead: isRead ?? this.isRead,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'bookingId': bookingId,
      'senderId': senderId,
      'receiverId': receiverId,
      'content': content,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'isRead': isRead,
    };
  }

  factory ChatMessage.fromMap(Map<String, dynamic> map) {
    return ChatMessage(
      id: map['id'] ?? '',
      bookingId: map['bookingId'],
      senderId: map['senderId'] ?? '',
      receiverId: map['receiverId'] ?? '',
      content: map['content'] ?? '',
      images: map['images'] != null ? List<String>.from(map['images']) : null,
      text: map['text'],
      timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp']),
      isRead: map['isRead'] ?? false,
    );
  }
}
