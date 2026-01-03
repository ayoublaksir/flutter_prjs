import 'package:flutter/material.dart';

// Support ticket model
class SupportTicket {
  final String id;
  final String subject;
  final String description;
  final String category;
  final String status; // 'open', 'in_progress', 'resolved', 'closed'
  final DateTime createdAt;
  final DateTime? updatedAt;
  final String? assignedTo;
  final List<TicketMessage>? messages;
  final String userId;

  SupportTicket({
    required this.id,
    required this.subject,
    required this.description,
    required this.category,
    required this.status,
    required this.createdAt,
    this.updatedAt,
    this.assignedTo,
    this.messages,
    this.userId = '',
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'subject': subject,
      'description': description,
      'category': category,
      'status': status,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'updatedAt': updatedAt?.millisecondsSinceEpoch,
      'assignedTo': assignedTo,
      'messages': messages?.map((m) => m.toMap()).toList(),
      'userId': userId,
    };
  }

  factory SupportTicket.fromMap(Map<String, dynamic> map) {
    return SupportTicket(
      id: map['id'] ?? '',
      subject: map['subject'] ?? '',
      description: map['description'] ?? '',
      category: map['category'] ?? '',
      status: map['status'] ?? 'open',
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt']),
      updatedAt:
          map['updatedAt'] != null
              ? DateTime.fromMillisecondsSinceEpoch(map['updatedAt'])
              : null,
      assignedTo: map['assignedTo'],
      messages:
          map['messages'] != null
              ? List<TicketMessage>.from(
                map['messages']?.map((x) => TicketMessage.fromMap(x)),
              )
              : null,
      userId: map['userId'] ?? '',
    );
  }
}

// Ticket message model
class TicketMessage {
  final String id;
  final String ticketId;
  final String senderId;
  final String message;
  final DateTime timestamp;
  final bool isStaff;

  TicketMessage({
    required this.id,
    required this.ticketId,
    required this.senderId,
    required this.message,
    required this.timestamp,
    this.isStaff = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'ticketId': ticketId,
      'senderId': senderId,
      'message': message,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'isStaff': isStaff,
    };
  }

  factory TicketMessage.fromMap(Map<String, dynamic> map) {
    return TicketMessage(
      id: map['id'] ?? '',
      ticketId: map['ticketId'] ?? '',
      senderId: map['senderId'] ?? '',
      message: map['message'] ?? '',
      timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp']),
      isStaff: map['isStaff'] ?? false,
    );
  }
}

// FAQ model
class FAQ {
  final String question;
  final String answer;

  FAQ({required this.question, required this.answer});

  Map<String, dynamic> toMap() {
    return {'question': question, 'answer': answer};
  }

  factory FAQ.fromMap(Map<String, dynamic> map) {
    return FAQ(question: map['question'] ?? '', answer: map['answer'] ?? '');
  }
}

// FAQ Category model
class FAQCategory {
  final String id;
  final String name;
  final IconData icon;
  final List<FAQ> faqs;

  FAQCategory({
    required this.id,
    required this.name,
    required this.icon,
    required this.faqs,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'icon': icon.codePoint,
      'faqs': faqs.map((faq) => faq.toMap()).toList(),
    };
  }

  factory FAQCategory.fromMap(Map<String, dynamic> map) {
    return FAQCategory(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      icon: IconData(map['icon'] ?? 0, fontFamily: 'MaterialIcons'),
      faqs: List<FAQ>.from(map['faqs']?.map((x) => FAQ.fromMap(x)) ?? []),
    );
  }
}
