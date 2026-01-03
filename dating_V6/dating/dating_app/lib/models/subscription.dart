import 'package:in_app_purchase/in_app_purchase.dart';

enum SubscriptionType { free, monthly, yearly }

class Subscription {
  final String id;
  final String name;
  final String description;
  final String price;
  final String duration;
  final ProductDetails? productDetails;
  final String? userId;
  final bool? isValid;
  final DateTime? expiryDate;
  final SubscriptionType? type;
  final DateTime? purchaseDate;

  Subscription({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.duration,
    this.productDetails,
    this.userId,
    this.isValid,
    this.expiryDate,
    this.type,
    this.purchaseDate,
  });
}
