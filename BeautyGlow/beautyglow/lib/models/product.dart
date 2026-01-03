import 'package:hive/hive.dart';

part 'product.g.dart';

/// Beauty product model
@HiveType(typeId: 2)
class Product extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String name;

  @HiveField(2)
  String brand;

  @HiveField(3)
  String category; // 'skincare', 'makeup', 'haircare', 'fragrance', 'bodycare'

  @HiveField(4)
  String? imagePath; // User's photo path

  @HiveField(5)
  double rating; // User's personal rating (0-5)

  @HiveField(6)
  String? review; // User's personal review

  @HiveField(7)
  double? price;

  @HiveField(8)
  DateTime dateAdded;

  @HiveField(9)
  bool isFavorite;

  @HiveField(10)
  List<String> tags; // ['moisturizing', 'anti-aging', 'fragrance-free', etc.]

  /// Get product image URL
  String? get imageUrl => imagePath;

  Product({
    required this.id,
    required this.name,
    required this.brand,
    required this.category,
    this.imagePath,
    this.rating = 0.0,
    this.review,
    this.price,
    required this.dateAdded,
    this.isFavorite = false,
    List<String>? tags,
  }) : tags = tags ?? [];

  /// Create a new product
  factory Product.create({
    required String name,
    required String brand,
    required String category,
    String? imagePath,
    double rating = 0.0,
    String? review,
    double? price,
    bool isFavorite = false,
    List<String>? tags,
  }) {
    return Product(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      brand: brand,
      category: category,
      imagePath: imagePath,
      rating: rating,
      review: review,
      price: price,
      dateAdded: DateTime.now(),
      isFavorite: isFavorite,
      tags: tags,
    );
  }

  /// Copy with method for updating product
  Product copyWith({
    String? name,
    String? brand,
    String? category,
    String? imagePath,
    double? rating,
    String? review,
    double? price,
    bool? isFavorite,
    List<String>? tags,
  }) {
    return Product(
      id: id,
      name: name ?? this.name,
      brand: brand ?? this.brand,
      category: category ?? this.category,
      imagePath: imagePath ?? this.imagePath,
      rating: rating ?? this.rating,
      review: review ?? this.review,
      price: price ?? this.price,
      dateAdded: dateAdded,
      isFavorite: isFavorite ?? this.isFavorite,
      tags: tags ?? this.tags,
    );
  }

  /// Get formatted price
  String get formattedPrice {
    if (price == null) return 'Price not set';
    return '\$${price!.toStringAsFixed(2)}';
  }

  /// Get category display name
  String get categoryDisplayName {
    switch (category.toLowerCase()) {
      case 'skincare':
        return 'Skincare';
      case 'makeup':
        return 'Makeup';
      case 'haircare':
        return 'Hair Care';
      case 'fragrance':
        return 'Fragrance';
      case 'bodycare':
        return 'Body Care';
      default:
        return category;
    }
  }

  /// Check if product has review
  bool get hasReview => review != null && review!.isNotEmpty;

  /// Check if product has image
  bool get hasImage => imagePath != null && imagePath!.isNotEmpty;

  /// Get rating stars (for display)
  int get ratingStars => rating.round();

  /// Format date added
  String get formattedDateAdded {
    final now = DateTime.now();
    final difference = now.difference(dateAdded);

    if (difference.inDays == 0) {
      return 'Added today';
    } else if (difference.inDays == 1) {
      return 'Added yesterday';
    } else if (difference.inDays < 7) {
      return 'Added ${difference.inDays} days ago';
    } else if (difference.inDays < 30) {
      final weeks = (difference.inDays / 7).floor();
      return 'Added $weeks week${weeks > 1 ? 's' : ''} ago';
    } else {
      final months = (difference.inDays / 30).floor();
      return 'Added $months month${months > 1 ? 's' : ''} ago';
    }
  }
}
