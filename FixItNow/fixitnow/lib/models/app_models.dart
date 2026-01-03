// models/app_models.dart
// Contains general app models and notification models

import 'dart:convert';

// Notification model
class AppNotification {
  final String id;
  final String userId;
  final String title;
  final String body;
  final Map<String, dynamic> data;
  final bool read;
  final DateTime createdAt;
  final DateTime? readAt;

  AppNotification({
    required this.id,
    required this.userId,
    required this.title,
    required this.body,
    required this.data,
    this.read = false,
    required this.createdAt,
    this.readAt,
  });

  AppNotification copyWith({
    String? id,
    String? userId,
    String? title,
    String? body,
    Map<String, dynamic>? data,
    bool? read,
    DateTime? createdAt,
    DateTime? readAt,
  }) {
    return AppNotification(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      body: body ?? this.body,
      data: data ?? this.data,
      read: read ?? this.read,
      createdAt: createdAt ?? this.createdAt,
      readAt: readAt ?? this.readAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'title': title,
      'body': body,
      'data': data,
      'read': read,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'readAt': readAt?.millisecondsSinceEpoch,
    };
  }

  factory AppNotification.fromMap(Map<String, dynamic> map) {
    return AppNotification(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      title: map['title'] ?? '',
      body: map['body'] ?? '',
      data: Map<String, dynamic>.from(map['data'] ?? {}),
      read: map['read'] ?? false,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt']),
      readAt:
          map['readAt'] != null
              ? DateTime.fromMillisecondsSinceEpoch(map['readAt'])
              : null,
    );
  }

  String toJson() => json.encode(toMap());

  factory AppNotification.fromJson(String source) =>
      AppNotification.fromMap(json.decode(source));
}

// App settings model
class AppSettings {
  final bool notificationsEnabled;
  final bool emailNotificationsEnabled;
  final bool locationTrackingEnabled;
  final String preferredLanguage;
  final String theme;
  final Map<String, bool> notificationPreferences;

  AppSettings({
    this.notificationsEnabled = true,
    this.emailNotificationsEnabled = true,
    this.locationTrackingEnabled = true,
    this.preferredLanguage = 'en',
    this.theme = 'system',
    this.notificationPreferences = const {
      'bookings': true,
      'messages': true,
      'payments': true,
      'promotions': false,
    },
  });

  AppSettings copyWith({
    bool? notificationsEnabled,
    bool? emailNotificationsEnabled,
    bool? locationTrackingEnabled,
    String? preferredLanguage,
    String? theme,
    Map<String, bool>? notificationPreferences,
  }) {
    return AppSettings(
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      emailNotificationsEnabled:
          emailNotificationsEnabled ?? this.emailNotificationsEnabled,
      locationTrackingEnabled:
          locationTrackingEnabled ?? this.locationTrackingEnabled,
      preferredLanguage: preferredLanguage ?? this.preferredLanguage,
      theme: theme ?? this.theme,
      notificationPreferences:
          notificationPreferences ?? this.notificationPreferences,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'notificationsEnabled': notificationsEnabled,
      'emailNotificationsEnabled': emailNotificationsEnabled,
      'locationTrackingEnabled': locationTrackingEnabled,
      'preferredLanguage': preferredLanguage,
      'theme': theme,
      'notificationPreferences': notificationPreferences,
    };
  }

  factory AppSettings.fromMap(Map<String, dynamic> map) {
    return AppSettings(
      notificationsEnabled: map['notificationsEnabled'] ?? true,
      emailNotificationsEnabled: map['emailNotificationsEnabled'] ?? true,
      locationTrackingEnabled: map['locationTrackingEnabled'] ?? true,
      preferredLanguage: map['preferredLanguage'] ?? 'en',
      theme: map['theme'] ?? 'system',
      notificationPreferences: Map<String, bool>.from(
        map['notificationPreferences'] ??
            {
              'bookings': true,
              'messages': true,
              'payments': true,
              'promotions': false,
            },
      ),
    );
  }

  String toJson() => json.encode(toMap());

  factory AppSettings.fromJson(String source) =>
      AppSettings.fromMap(json.decode(source));
}

// Transaction model (for payments and earnings)
class Transaction {
  final String id;
  final String userId;
  final String bookingId;
  final double amount;
  final String type; // 'payment', 'payout', 'refund', 'tip'
  final String status; // 'pending', 'completed', 'failed', 'cancelled'
  final DateTime createdAt;
  final DateTime? completedAt;
  final String paymentMethod;
  final Map<String, dynamic> details;

  Transaction({
    required this.id,
    required this.userId,
    required this.bookingId,
    required this.amount,
    required this.type,
    required this.status,
    required this.createdAt,
    this.completedAt,
    required this.paymentMethod,
    this.details = const {},
  });

  Transaction copyWith({
    String? id,
    String? userId,
    String? bookingId,
    double? amount,
    String? type,
    String? status,
    DateTime? createdAt,
    DateTime? completedAt,
    String? paymentMethod,
    Map<String, dynamic>? details,
  }) {
    return Transaction(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      bookingId: bookingId ?? this.bookingId,
      amount: amount ?? this.amount,
      type: type ?? this.type,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      completedAt: completedAt ?? this.completedAt,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      details: details ?? this.details,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'bookingId': bookingId,
      'amount': amount,
      'type': type,
      'status': status,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'completedAt': completedAt?.millisecondsSinceEpoch,
      'paymentMethod': paymentMethod,
      'details': details,
    };
  }

  factory Transaction.fromMap(Map<String, dynamic> map) {
    return Transaction(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      bookingId: map['bookingId'] ?? '',
      amount: map['amount']?.toDouble() ?? 0.0,
      type: map['type'] ?? '',
      status: map['status'] ?? '',
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt']),
      completedAt:
          map['completedAt'] != null
              ? DateTime.fromMillisecondsSinceEpoch(map['completedAt'])
              : null,
      paymentMethod: map['paymentMethod'] ?? '',
      details: Map<String, dynamic>.from(map['details'] ?? {}),
    );
  }

  String toJson() => json.encode(toMap());

  factory Transaction.fromJson(String source) =>
      Transaction.fromMap(json.decode(source));
}

class Address {
  final String id;
  final String name;
  final String label;
  final String street;
  final String city;
  final String state;
  final String zipCode;
  final String country;
  final String type; // 'home', 'work', 'other'
  final String formattedAddress;
  final double latitude;
  final double longitude;
  final String coordinates;
  final bool isDefault;

  Address({
    required this.id,
    this.name = '',
    this.label = '',
    this.street = '',
    this.city = '',
    this.state = '',
    this.zipCode = '',
    this.country = '',
    this.type = 'home',
    this.formattedAddress = '',
    this.latitude = 0.0,
    this.longitude = 0.0,
    this.coordinates = '',
    this.isDefault = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'label': label,
      'street': street,
      'city': city,
      'state': state,
      'zipCode': zipCode,
      'country': country,
      'type': type,
      'formattedAddress': formattedAddress,
      'latitude': latitude,
      'longitude': longitude,
      'coordinates': coordinates,
      'isDefault': isDefault,
    };
  }

  factory Address.fromMap(Map<String, dynamic> map) {
    return Address(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      label: map['label'] ?? '',
      street: map['street'] ?? '',
      city: map['city'] ?? '',
      state: map['state'] ?? '',
      zipCode: map['zipCode'] ?? '',
      country: map['country'] ?? '',
      type: map['type'] ?? 'home',
      formattedAddress: map['formattedAddress'] ?? '',
      latitude: map['latitude']?.toDouble() ?? 0.0,
      longitude: map['longitude']?.toDouble() ?? 0.0,
      coordinates: map['coordinates'] ?? '',
      isDefault: map['isDefault'] ?? false,
    );
  }
}

// For the UserAddress class used in the dialog
class UserAddress extends Address {
  UserAddress({
    required String id,
    required String label,
    required String type,
    required String formattedAddress,
    required double latitude,
    required double longitude,
    bool isDefault = false,
  }) : super(
         id: id,
         name: label,
         type: type,
         formattedAddress: formattedAddress,
         latitude: latitude,
         longitude: longitude,
         isDefault: isDefault,
       );
}
