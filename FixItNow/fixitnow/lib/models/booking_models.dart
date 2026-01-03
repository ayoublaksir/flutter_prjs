// models/booking_models.dart
// Contains all booking-related models including booking, payment, and review

import 'package:flutter/foundation.dart';
import 'dart:convert';

// Booking status enum
enum BookingStatus {
  pending,
  accepted,
  confirmed,
  completed,
  declined,
  cancelled,
}

// Booking model
class Booking {
  final String id;
  final String seekerId;
  final String providerId;
  final String serviceId;
  final DateTime bookingDate;
  final String bookingTime;
  final String
  status; // 'pending', 'confirmed', 'in_progress', 'completed', 'cancelled'
  final String address;
  final String description;
  final double latitude;
  final double longitude;
  final double price;
  final Map<String, dynamic> additionalServices;
  final DateTime startTime;
  final DateTime endTime;
  final String paymentId;
  final bool isPaid;
  final String cancellationReason;
  final String cancellationPolicy;
  final String paymentMethod;
  final String notes;
  final DateTime createdAt;
  final String location;

  Booking({
    required this.id,
    required this.seekerId,
    required this.providerId,
    required this.serviceId,
    required this.bookingDate,
    required this.bookingTime,
    required this.status,
    required this.address,
    required this.description,
    this.latitude = 0.0,
    this.longitude = 0.0,
    required this.price,
    this.additionalServices = const {},
    required this.startTime,
    required this.endTime,
    this.paymentId = '',
    this.isPaid = false,
    this.cancellationReason = '',
    this.cancellationPolicy = 'standard',
    required this.paymentMethod,
    this.notes = '',
    required this.createdAt,
    required this.location,
  });

  Booking copyWith({
    String? id,
    String? seekerId,
    String? providerId,
    String? serviceId,
    DateTime? bookingDate,
    String? bookingTime,
    String? status,
    String? address,
    String? description,
    double? latitude,
    double? longitude,
    double? price,
    Map<String, dynamic>? additionalServices,
    DateTime? startTime,
    DateTime? endTime,
    String? paymentId,
    bool? isPaid,
    String? cancellationReason,
    String? cancellationPolicy,
    String? paymentMethod,
    String? notes,
    DateTime? createdAt,
    String? location,
  }) {
    return Booking(
      id: id ?? this.id,
      seekerId: seekerId ?? this.seekerId,
      providerId: providerId ?? this.providerId,
      serviceId: serviceId ?? this.serviceId,
      bookingDate: bookingDate ?? this.bookingDate,
      bookingTime: bookingTime ?? this.bookingTime,
      status: status ?? this.status,
      address: address ?? this.address,
      description: description ?? this.description,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      price: price ?? this.price,
      additionalServices: additionalServices ?? this.additionalServices,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      paymentId: paymentId ?? this.paymentId,
      isPaid: isPaid ?? this.isPaid,
      cancellationReason: cancellationReason ?? this.cancellationReason,
      cancellationPolicy: cancellationPolicy ?? this.cancellationPolicy,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      location: location ?? this.location,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'seekerId': seekerId,
      'providerId': providerId,
      'serviceId': serviceId,
      'bookingDate': bookingDate.millisecondsSinceEpoch,
      'bookingTime': bookingTime,
      'status': status,
      'address': address,
      'description': description,
      'latitude': latitude,
      'longitude': longitude,
      'price': price,
      'additionalServices': additionalServices,
      'startTime': startTime.millisecondsSinceEpoch,
      'endTime': endTime.millisecondsSinceEpoch,
      'paymentId': paymentId,
      'isPaid': isPaid,
      'cancellationReason': cancellationReason,
      'cancellationPolicy': cancellationPolicy,
      'paymentMethod': paymentMethod,
      'notes': notes,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'location': location,
    };
  }

  factory Booking.fromMap(Map<String, dynamic> map) {
    return Booking(
      id: map['id'] ?? '',
      seekerId: map['seekerId'] ?? '',
      providerId: map['providerId'] ?? '',
      serviceId: map['serviceId'] ?? '',
      bookingDate: DateTime.fromMillisecondsSinceEpoch(map['bookingDate']),
      bookingTime: map['bookingTime'] ?? '',
      status: map['status'] ?? 'pending',
      address: map['address'] ?? '',
      description: map['description'] ?? '',
      latitude: map['latitude']?.toDouble() ?? 0.0,
      longitude: map['longitude']?.toDouble() ?? 0.0,
      price: map['price']?.toDouble() ?? 0.0,
      additionalServices: Map<String, dynamic>.from(
        map['additionalServices'] ?? {},
      ),
      startTime: DateTime.fromMillisecondsSinceEpoch(map['startTime']),
      endTime: DateTime.fromMillisecondsSinceEpoch(map['endTime']),
      paymentId: map['paymentId'] ?? '',
      isPaid: map['isPaid'] ?? false,
      cancellationReason: map['cancellationReason'] ?? '',
      cancellationPolicy: map['cancellationPolicy'] ?? 'standard',
      paymentMethod: map['paymentMethod'] ?? '',
      notes: map['notes'] ?? '',
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt']),
      location: map['location'] ?? '',
    );
  }

  String toJson() => json.encode(toMap());

  factory Booking.fromJson(String source) =>
      Booking.fromMap(json.decode(source));

  @override
  String toString() {
    return 'Booking(id: $id, seekerId: $seekerId, providerId: $providerId, serviceId: $serviceId, bookingDate: $bookingDate, bookingTime: $bookingTime, status: $status, address: $address, description: $description, price: $price, startTime: $startTime, endTime: $endTime, isPaid: $isPaid)';
  }
}

// Payment model
class Payment {
  final String id;
  final String bookingId;
  final String userId; // Either seeker or provider id
  final double amount;
  final double serviceFee;
  final double taxAmount;
  final double tipAmount;
  final double totalAmount;
  final String status; // 'pending', 'completed', 'failed', 'refunded'
  final String paymentMethod; // 'credit_card', 'paypal', 'apple_pay', 'cash'
  final DateTime createdAt;
  final DateTime? completedAt;
  final String transactionId;
  final Map<String, dynamic> paymentDetails;

  Payment({
    required this.id,
    required this.bookingId,
    required this.userId,
    required this.amount,
    required this.serviceFee,
    required this.taxAmount,
    this.tipAmount = 0.0,
    required this.totalAmount,
    required this.status,
    required this.paymentMethod,
    required this.createdAt,
    this.completedAt,
    this.transactionId = '',
    this.paymentDetails = const {},
  });

  Payment copyWith({
    String? id,
    String? bookingId,
    String? userId,
    double? amount,
    double? serviceFee,
    double? taxAmount,
    double? tipAmount,
    double? totalAmount,
    String? status,
    String? paymentMethod,
    DateTime? createdAt,
    DateTime? completedAt,
    String? transactionId,
    Map<String, dynamic>? paymentDetails,
  }) {
    return Payment(
      id: id ?? this.id,
      bookingId: bookingId ?? this.bookingId,
      userId: userId ?? this.userId,
      amount: amount ?? this.amount,
      serviceFee: serviceFee ?? this.serviceFee,
      taxAmount: taxAmount ?? this.taxAmount,
      tipAmount: tipAmount ?? this.tipAmount,
      totalAmount: totalAmount ?? this.totalAmount,
      status: status ?? this.status,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      createdAt: createdAt ?? this.createdAt,
      completedAt: completedAt ?? this.completedAt,
      transactionId: transactionId ?? this.transactionId,
      paymentDetails: paymentDetails ?? this.paymentDetails,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'bookingId': bookingId,
      'userId': userId,
      'amount': amount,
      'serviceFee': serviceFee,
      'taxAmount': taxAmount,
      'tipAmount': tipAmount,
      'totalAmount': totalAmount,
      'status': status,
      'paymentMethod': paymentMethod,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'completedAt': completedAt?.millisecondsSinceEpoch,
      'transactionId': transactionId,
      'paymentDetails': paymentDetails,
    };
  }

  factory Payment.fromMap(Map<String, dynamic> map) {
    return Payment(
      id: map['id'] ?? '',
      bookingId: map['bookingId'] ?? '',
      userId: map['userId'] ?? '',
      amount: map['amount']?.toDouble() ?? 0.0,
      serviceFee: map['serviceFee']?.toDouble() ?? 0.0,
      taxAmount: map['taxAmount']?.toDouble() ?? 0.0,
      tipAmount: map['tipAmount']?.toDouble() ?? 0.0,
      totalAmount: map['totalAmount']?.toDouble() ?? 0.0,
      status: map['status'] ?? 'pending',
      paymentMethod: map['paymentMethod'] ?? 'credit_card',
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt']),
      completedAt:
          map['completedAt'] != null
              ? DateTime.fromMillisecondsSinceEpoch(map['completedAt'])
              : null,
      transactionId: map['transactionId'] ?? '',
      paymentDetails: Map<String, dynamic>.from(map['paymentDetails'] ?? {}),
    );
  }

  String toJson() => json.encode(toMap());

  factory Payment.fromJson(String source) =>
      Payment.fromMap(json.decode(source));
}

// Review model
class Review {
  final String id;
  final String bookingId;
  final String reviewerId; // User who left the review
  final String revieweeId; // User who received the review
  final String serviceId; // Add this field
  final double rating; // 1-5 rating
  final String comment;
  final Map<String, double> categoryRatings; // Add this field
  final DateTime createdAt;
  final List<String> images; // Optional images attached to review
  final String? providerResponse; // Provider's response to the review

  Review({
    required this.id,
    required this.bookingId,
    required this.reviewerId,
    required this.revieweeId,
    required this.serviceId, // Add this parameter
    required this.rating,
    required this.comment,
    required this.categoryRatings, // Add this parameter
    required this.createdAt,
    this.images = const [],
    this.providerResponse,
  });

  Review copyWith({
    String? id,
    String? bookingId,
    String? reviewerId,
    String? revieweeId,
    String? serviceId,
    double? rating,
    String? comment,
    Map<String, double>? categoryRatings,
    DateTime? createdAt,
    List<String>? images,
    String? providerResponse,
  }) {
    return Review(
      id: id ?? this.id,
      bookingId: bookingId ?? this.bookingId,
      reviewerId: reviewerId ?? this.reviewerId,
      revieweeId: revieweeId ?? this.revieweeId,
      serviceId: serviceId ?? this.serviceId,
      rating: rating ?? this.rating,
      comment: comment ?? this.comment,
      categoryRatings: categoryRatings ?? this.categoryRatings,
      createdAt: createdAt ?? this.createdAt,
      images: images ?? this.images,
      providerResponse: providerResponse ?? this.providerResponse,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'bookingId': bookingId,
      'reviewerId': reviewerId,
      'revieweeId': revieweeId,
      'serviceId': serviceId,
      'rating': rating,
      'comment': comment,
      'categoryRatings': categoryRatings,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'images': images,
      'providerResponse': providerResponse,
    };
  }

  factory Review.fromMap(Map<String, dynamic> map) {
    return Review(
      id: map['id'] ?? '',
      bookingId: map['bookingId'] ?? '',
      reviewerId: map['reviewerId'] ?? '',
      revieweeId: map['revieweeId'] ?? '',
      serviceId: map['serviceId'] ?? '',
      rating: map['rating']?.toDouble() ?? 0.0,
      comment: map['comment'] ?? '',
      categoryRatings: Map<String, double>.from(map['categoryRatings'] ?? {}),
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt']),
      images: List<String>.from(map['images'] ?? []),
      providerResponse: map['providerResponse'],
    );
  }

  String toJson() => json.encode(toMap());

  factory Review.fromJson(String source) => Review.fromMap(json.decode(source));

  Map<String, double> get ratingBreakdown => categoryRatings;
}

// Rename from Transaction to PaymentTransaction
class PaymentTransaction {
  final String id;
  final double amount;
  final String type; // 'credit' or 'debit'
  final String description;
  final DateTime timestamp;
  final String bookingId;
  final String providerId;
  final String seekerId;

  PaymentTransaction({
    required this.id,
    required this.amount,
    required this.type,
    required this.description,
    required this.timestamp,
    required this.bookingId,
    required this.providerId,
    required this.seekerId,
  });

  factory PaymentTransaction.fromMap(Map<String, dynamic> map) {
    return PaymentTransaction(
      id: map['id'] ?? '',
      amount: (map['amount'] ?? 0.0).toDouble(),
      type: map['type'] ?? 'credit',
      description: map['description'] ?? '',
      timestamp:
          map['timestamp'] != null
              ? (map['timestamp'] is DateTime
                  ? map['timestamp']
                  : DateTime.fromMillisecondsSinceEpoch(map['timestamp']))
              : DateTime.now(),
      bookingId: map['bookingId'] ?? '',
      providerId: map['providerId'] ?? '',
      seekerId: map['seekerId'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'amount': amount,
      'type': type,
      'description': description,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'bookingId': bookingId,
      'providerId': providerId,
      'seekerId': seekerId,
    };
  }
}

// Add this class to booking_models.dart
class Transaction {
  final String id;
  final String bookingId;
  final double amount;
  final String type; // 'credit' or 'debit'
  final String description;
  final DateTime timestamp;
  final String status;

  Transaction({
    required this.id,
    required this.bookingId,
    required this.amount,
    required this.type,
    required this.description,
    required this.timestamp,
    this.status = 'completed',
  });
}
