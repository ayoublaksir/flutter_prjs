import 'package:hive/hive.dart';

part 'user_profile.g.dart';

/// User profile information
@HiveType(typeId: 1)
class UserProfile extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String name;

  @HiveField(2)
  String? email;

  @HiveField(3)
  String? profileImagePath;

  @HiveField(4)
  DateTime joinDate;

  @HiveField(5)
  String skinType; // 'oily', 'dry', 'combination', 'normal', 'sensitive'

  @HiveField(6)
  List<String> skinConcerns; // ['acne', 'aging', 'dryness', 'dark spots', etc.]

  @HiveField(7)
  String preferredRoutineTime; // 'morning', 'evening', 'both'

  @HiveField(8)
  bool notificationsEnabled;

  @HiveField(9)
  String? notificationTime; // e.g., "08:00" for morning routine reminder

  @HiveField(10)
  Map<String, dynamic> preferences; // Additional user preferences

  UserProfile({
    required this.id,
    required this.name,
    this.email,
    this.profileImagePath,
    required this.joinDate,
    this.skinType = 'normal',
    List<String>? skinConcerns,
    this.preferredRoutineTime = 'both',
    this.notificationsEnabled = true,
    this.notificationTime,
    Map<String, dynamic>? preferences,
  })  : skinConcerns = skinConcerns ?? [],
        preferences = preferences ?? {};

  /// Create a default user profile
  factory UserProfile.defaultProfile() {
    return UserProfile(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: 'Beauty Lover',
      joinDate: DateTime.now(),
      skinType: 'normal',
      skinConcerns: [],
      preferredRoutineTime: 'both',
      notificationsEnabled: true,
      preferences: {},
    );
  }

  /// Copy with method for updating profile
  UserProfile copyWith({
    String? name,
    String? email,
    String? profileImagePath,
    String? skinType,
    List<String>? skinConcerns,
    String? preferredRoutineTime,
    bool? notificationsEnabled,
    String? notificationTime,
    Map<String, dynamic>? preferences,
  }) {
    return UserProfile(
      id: id,
      name: name ?? this.name,
      email: email ?? this.email,
      profileImagePath: profileImagePath ?? this.profileImagePath,
      joinDate: joinDate,
      skinType: skinType ?? this.skinType,
      skinConcerns: skinConcerns ?? this.skinConcerns,
      preferredRoutineTime: preferredRoutineTime ?? this.preferredRoutineTime,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      notificationTime: notificationTime ?? this.notificationTime,
      preferences: preferences ?? this.preferences,
    );
  }

  /// Get display name with fallback
  String get displayName => name.isEmpty ? 'Beauty Lover' : name;

  /// Get initials for avatar
  String get initials {
    final names = name.trim().split(' ');
    if (names.isEmpty) return 'BL';
    if (names.length == 1) {
      return names[0].substring(0, 1).toUpperCase();
    }
    return '${names[0].substring(0, 1)}${names[1].substring(0, 1)}'
        .toUpperCase();
  }

  /// Get member duration
  String get memberDuration {
    final now = DateTime.now();
    final difference = now.difference(joinDate);

    if (difference.inDays < 30) {
      return '${difference.inDays} days';
    } else if (difference.inDays < 365) {
      final months = (difference.inDays / 30).floor();
      return '$months month${months > 1 ? 's' : ''}';
    } else {
      final years = (difference.inDays / 365).floor();
      return '$years year${years > 1 ? 's' : ''}';
    }
  }
}
