// models/payment_models.dart
// Contains payment-related models

import 'dart:convert';

enum PaymentMethodType { creditCard, bankAccount, paypal }

class Transaction {
  final String id;
  final String userId;
  final String bookingId;
  final double amount;
  final String type; // 'payment', 'refund', 'payout'
  final String status; // 'pending', 'completed', 'failed'
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
}

class PaymentMethod {
  final String id;
  final String userId;
  final PaymentMethodType type;
  final String last4;
  final String brand;
  final String holderName;
  final bool isDefault;
  final String expiryMonth;
  final String expiryYear;
  final String? provider;
  final String? bankName;
  final String? email;
  final DateTime? createdAt;

  PaymentMethod({
    required this.id,
    required this.userId,
    required this.type,
    required this.last4,
    required this.brand,
    required this.holderName,
    this.isDefault = false,
    required this.expiryMonth,
    required this.expiryYear,
    this.provider,
    this.bankName,
    this.email,
    this.createdAt,
  });

  PaymentMethod copyWith({
    String? id,
    String? userId,
    PaymentMethodType? type,
    String? last4,
    String? brand,
    String? holderName,
    bool? isDefault,
    String? expiryMonth,
    String? expiryYear,
    String? provider,
    String? bankName,
    String? email,
    DateTime? createdAt,
  }) {
    return PaymentMethod(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      type: type ?? this.type,
      last4: last4 ?? this.last4,
      brand: brand ?? this.brand,
      holderName: holderName ?? this.holderName,
      isDefault: isDefault ?? this.isDefault,
      expiryMonth: expiryMonth ?? this.expiryMonth,
      expiryYear: expiryYear ?? this.expiryYear,
      provider: provider ?? this.provider,
      bankName: bankName ?? this.bankName,
      email: email ?? this.email,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'type': type.toString(),
      'last4': last4,
      'brand': brand,
      'holderName': holderName,
      'isDefault': isDefault,
      'expiryMonth': expiryMonth,
      'expiryYear': expiryYear,
      'provider': provider,
      'bankName': bankName,
      'email': email,
      'createdAt': createdAt?.millisecondsSinceEpoch,
    };
  }

  factory PaymentMethod.fromMap(Map<String, dynamic> map) {
    return PaymentMethod(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      type: _parsePaymentMethodType(map['type'] ?? ''),
      last4: map['last4'] ?? '',
      brand: map['brand'] ?? '',
      holderName: map['holderName'] ?? '',
      isDefault: map['isDefault'] ?? false,
      expiryMonth: map['expiryMonth'] ?? '',
      expiryYear: map['expiryYear'] ?? '',
      provider: map['provider'],
      bankName: map['bankName'],
      email: map['email'],
      createdAt:
          map['createdAt'] != null
              ? DateTime.fromMillisecondsSinceEpoch(map['createdAt'])
              : null,
    );
  }

  static PaymentMethodType _parsePaymentMethodType(String type) {
    if (type.contains('creditCard')) {
      return PaymentMethodType.creditCard;
    } else if (type.contains('bankAccount')) {
      return PaymentMethodType.bankAccount;
    } else if (type.contains('paypal')) {
      return PaymentMethodType.paypal;
    }
    return PaymentMethodType.creditCard; // Default
  }
}

class Payment {
  final String id;
  final String bookingId;
  final String userId;
  final double amount;
  final double serviceFee;
  final double taxAmount;
  final double totalAmount;
  final String status;
  final String paymentMethod;
  final DateTime timestamp;

  Payment({
    required this.id,
    required this.bookingId,
    required this.userId,
    required this.amount,
    required this.serviceFee,
    required this.taxAmount,
    required this.totalAmount,
    required this.status,
    required this.paymentMethod,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'bookingId': bookingId,
      'userId': userId,
      'amount': amount,
      'serviceFee': serviceFee,
      'taxAmount': taxAmount,
      'totalAmount': totalAmount,
      'status': status,
      'paymentMethod': paymentMethod,
      'timestamp': timestamp.millisecondsSinceEpoch,
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
      totalAmount: map['totalAmount']?.toDouble() ?? 0.0,
      status: map['status'] ?? '',
      paymentMethod: map['paymentMethod'] ?? '',
      timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp']),
    );
  }
}
