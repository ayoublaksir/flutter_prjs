import 'package:hive/hive.dart';

part 'beauty_tip.g.dart';

/// Beauty tip model (mock data - not stored in Hive)
@HiveType(typeId: 8)
class BeautyTip extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String title;

  @HiveField(2)
  final String category; // 'skincare', 'makeup', 'haircare', 'lifestyle'

  @HiveField(3)
  final String shortDescription;

  @HiveField(4)
  final String fullContent;

  @HiveField(5)
  final String imagePath;

  @HiveField(6)
  final int readTimeMinutes;

  @HiveField(7)
  final List<String> tags;

  bool isFavorite; // Local session only

  BeautyTip({
    required this.id,
    required this.title,
    required this.category,
    required this.shortDescription,
    required this.fullContent,
    required this.imagePath,
    required this.readTimeMinutes,
    required this.tags,
    this.isFavorite = false,
  });

  /// Create from JSON (for mock data loading)
  factory BeautyTip.fromJson(Map<String, dynamic> json) {
    return BeautyTip(
      id: json['id'] as String,
      title: json['title'] as String,
      category: json['category'] as String,
      shortDescription: json['shortDescription'] as String,
      fullContent: json['fullContent'] as String,
      imagePath: json['imagePath'] as String,
      readTimeMinutes: json['readTimeMinutes'] as int,
      tags: List<String>.from(json['tags'] as List),
      isFavorite: false,
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'category': category,
      'shortDescription': shortDescription,
      'fullContent': fullContent,
      'imagePath': imagePath,
      'readTimeMinutes': readTimeMinutes,
      'tags': tags,
      'isFavorite': isFavorite,
    };
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
      case 'lifestyle':
        return 'Lifestyle';
      default:
        return category;
    }
  }

  /// Get formatted read time
  String get formattedReadTime {
    if (readTimeMinutes < 60) {
      return '$readTimeMinutes min read';
    } else {
      final hours = readTimeMinutes ~/ 60;
      final minutes = readTimeMinutes % 60;
      return minutes > 0 ? '${hours}h ${minutes}m read' : '${hours}h read';
    }
  }

  /// Toggle favorite status
  void toggleFavorite() {
    isFavorite = !isFavorite;
  }

  // Factory method to create a beauty tip
  factory BeautyTip.create({
    required String title,
    required String category,
    required String shortDescription,
    required String fullContent,
    required String imagePath,
    List<String>? tags,
  }) {
    return BeautyTip(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      category: category,
      shortDescription: shortDescription,
      fullContent: fullContent,
      imagePath: imagePath,
      readTimeMinutes: (fullContent.split(' ').length / 200)
          .ceil(), // Assuming 200 words per minute reading speed
      tags: tags ?? [],
      isFavorite: false,
    );
  }
}
