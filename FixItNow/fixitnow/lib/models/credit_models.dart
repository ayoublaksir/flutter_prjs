import 'package:cloud_firestore/cloud_firestore.dart';

/// Represents a credit bundle that providers can purchase
class CreditBundle {
  final String id;
  final String name;
  final int creditAmount;
  final double price;
  final String? description;
  final bool isPopular;
  final double? discountPercentage;

  CreditBundle({
    required this.id,
    required this.name,
    required this.creditAmount,
    required this.price,
    this.description,
    this.isPopular = false,
    this.discountPercentage,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'creditAmount': creditAmount,
      'price': price,
      'description': description,
      'isPopular': isPopular,
      'discountPercentage': discountPercentage,
    };
  }

  factory CreditBundle.fromMap(Map<String, dynamic> map) {
    return CreditBundle(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      creditAmount: map['creditAmount'] ?? 0,
      price: map['price'] ?? 0.0,
      description: map['description'],
      isPopular: map['isPopular'] ?? false,
      discountPercentage: map['discountPercentage'],
    );
  }

  factory CreditBundle.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return CreditBundle.fromMap({...data, 'id': doc.id});
  }
}

/// Represents a credit transaction in a provider's account
class CreditTransaction {
  final String id;
  final String providerId;
  final int amount;
  final String type; // 'purchase', 'refund', 'used', 'expired', 'bonus'
  final String? description;
  final DateTime timestamp;
  final String? relatedBookingId;
  final String? bundleId;
  final double? purchaseAmount;
  final String? paymentMethodId;

  CreditTransaction({
    required this.id,
    required this.providerId,
    required this.amount,
    required this.type,
    this.description,
    required this.timestamp,
    this.relatedBookingId,
    this.bundleId,
    this.purchaseAmount,
    this.paymentMethodId,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'providerId': providerId,
      'amount': amount,
      'type': type,
      'description': description,
      'timestamp': timestamp.toIso8601String(),
      'relatedBookingId': relatedBookingId,
      'bundleId': bundleId,
      'purchaseAmount': purchaseAmount,
      'paymentMethodId': paymentMethodId,
    };
  }

  factory CreditTransaction.fromMap(Map<String, dynamic> map) {
    return CreditTransaction(
      id: map['id'] ?? '',
      providerId: map['providerId'] ?? '',
      amount: map['amount'] ?? 0,
      type: map['type'] ?? '',
      description: map['description'],
      timestamp:
          map['timestamp'] is Timestamp
              ? (map['timestamp'] as Timestamp).toDate()
              : DateTime.parse(map['timestamp']),
      relatedBookingId: map['relatedBookingId'],
      bundleId: map['bundleId'],
      purchaseAmount: map['purchaseAmount'],
      paymentMethodId: map['paymentMethodId'],
    );
  }

  factory CreditTransaction.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return CreditTransaction.fromMap({...data, 'id': doc.id});
  }
}

/// Represents a provider's credit balance and history
class ProviderCreditAccount {
  final String providerId;
  final int currentBalance;
  final int totalPurchased;
  final int totalUsed;
  final DateTime? lastPurchaseDate;
  final DateTime? lastUsedDate;
  final List<CreditTransaction> recentTransactions;

  ProviderCreditAccount({
    required this.providerId,
    required this.currentBalance,
    required this.totalPurchased,
    required this.totalUsed,
    this.lastPurchaseDate,
    this.lastUsedDate,
    required this.recentTransactions,
  });

  Map<String, dynamic> toMap() {
    return {
      'providerId': providerId,
      'currentBalance': currentBalance,
      'totalPurchased': totalPurchased,
      'totalUsed': totalUsed,
      'lastPurchaseDate': lastPurchaseDate?.toIso8601String(),
      'lastUsedDate': lastUsedDate?.toIso8601String(),
    };
  }

  factory ProviderCreditAccount.fromMap(
    Map<String, dynamic> map, {
    List<CreditTransaction>? transactions,
  }) {
    return ProviderCreditAccount(
      providerId: map['providerId'] ?? '',
      currentBalance: map['currentBalance'] ?? 0,
      totalPurchased: map['totalPurchased'] ?? 0,
      totalUsed: map['totalUsed'] ?? 0,
      lastPurchaseDate:
          map['lastPurchaseDate'] != null
              ? (map['lastPurchaseDate'] is Timestamp
                  ? (map['lastPurchaseDate'] as Timestamp).toDate()
                  : DateTime.parse(map['lastPurchaseDate']))
              : null,
      lastUsedDate:
          map['lastUsedDate'] != null
              ? (map['lastUsedDate'] is Timestamp
                  ? (map['lastUsedDate'] as Timestamp).toDate()
                  : DateTime.parse(map['lastUsedDate']))
              : null,
      recentTransactions: transactions ?? [],
    );
  }

  factory ProviderCreditAccount.fromFirestore(
    DocumentSnapshot doc, {
    List<CreditTransaction>? transactions,
  }) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return ProviderCreditAccount.fromMap(data, transactions: transactions);
  }
}

/// Represents a pending credit hold for a provider's bid/offer
class CreditHold {
  final String id;
  final String providerId;
  final int amount;
  final DateTime createdAt;
  final DateTime expiresAt;
  final String status; // 'pending', 'applied', 'released', 'expired'
  final String requestId;
  final String? seekerId;

  CreditHold({
    required this.id,
    required this.providerId,
    required this.amount,
    required this.createdAt,
    required this.expiresAt,
    required this.status,
    required this.requestId,
    this.seekerId,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'providerId': providerId,
      'amount': amount,
      'createdAt': createdAt.toIso8601String(),
      'expiresAt': expiresAt.toIso8601String(),
      'status': status,
      'requestId': requestId,
      'seekerId': seekerId,
    };
  }

  factory CreditHold.fromMap(Map<String, dynamic> map) {
    return CreditHold(
      id: map['id'] ?? '',
      providerId: map['providerId'] ?? '',
      amount: map['amount'] ?? 0,
      createdAt:
          map['createdAt'] is Timestamp
              ? (map['createdAt'] as Timestamp).toDate()
              : DateTime.parse(map['createdAt']),
      expiresAt:
          map['expiresAt'] is Timestamp
              ? (map['expiresAt'] as Timestamp).toDate()
              : DateTime.parse(map['expiresAt']),
      status: map['status'] ?? 'pending',
      requestId: map['requestId'] ?? '',
      seekerId: map['seekerId'],
    );
  }

  factory CreditHold.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return CreditHold.fromMap({...data, 'id': doc.id});
  }
}
