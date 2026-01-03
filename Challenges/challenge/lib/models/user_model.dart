// lib/models/user_model.dart
class UserModel {
  final String id;
  final String email;
  final String name;
  final String? photoUrl;
  final DateTime createdAt;
  final List<Badge> badges;

  UserModel({
    required this.id,
    required this.email,
    required this.name,
    this.photoUrl,
    required this.createdAt,
    this.badges = const [],
  });

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
    id: json['id'],
    email: json['email'],
    name: json['name'],
    photoUrl: json['photoUrl'],
    createdAt: DateTime.parse(json['createdAt']),
    badges: List<Badge>.from(
      json['badges']?.map((x) => Badge.fromJson(x)) ?? [],
    ),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'email': email,
    'name': name,
    'photoUrl': photoUrl,
    'createdAt': createdAt.toIso8601String(),
    'badges': badges.map((e) => e.toJson()).toList(),
  };

  bool hasBadge(String badgeId) => badges.any((b) => b.id == badgeId);
}

class Badge {
  final String id;
  final String title;
  final String description;
  final String icon;
  final DateTime earnedAt;

  Badge({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.earnedAt,
  });

  factory Badge.fromJson(Map<String, dynamic> json) => Badge(
    id: json['id'],
    title: json['title'],
    description: json['description'],
    icon: json['icon'],
    earnedAt: DateTime.parse(json['earnedAt']),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'description': description,
    'icon': icon,
    'earnedAt': earnedAt.toIso8601String(),
  };
}
