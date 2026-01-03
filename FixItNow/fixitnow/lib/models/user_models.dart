// models/user_models.dart
// Contains all user-related models for the app

import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'app_models.dart'; // Import the file with Address class

// Base User model with common properties
class User {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String profileImage;
  final DateTime createdAt;
  final String role; // "seeker" or "provider"

  User({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    this.profileImage = '',
    required this.createdAt,
    required this.role,
  });

  User copyWith({
    String? id,
    String? name,
    String? email,
    String? phone,
    String? profileImage,
    DateTime? createdAt,
    String? role,
  }) {
    return User(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      profileImage: profileImage ?? this.profileImage,
      createdAt: createdAt ?? this.createdAt,
      role: role ?? this.role,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'profileImage': profileImage,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'role': role,
    };
  }

  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      phone: map['phone'] ?? '',
      profileImage: map['profileImage'] ?? '',
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt']),
      role: map['role'] ?? '',
    );
  }

  String toJson() => json.encode(toMap());

  factory User.fromJson(String source) => User.fromMap(json.decode(source));

  @override
  String toString() {
    return 'User(id: $id, name: $name, email: $email, phone: $phone, profileImage: $profileImage, createdAt: $createdAt, role: $role)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is User &&
        other.id == id &&
        other.name == name &&
        other.email == email &&
        other.phone == phone &&
        other.profileImage == profileImage &&
        other.createdAt == createdAt &&
        other.role == role;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        name.hashCode ^
        email.hashCode ^
        phone.hashCode ^
        profileImage.hashCode ^
        createdAt.hashCode ^
        role.hashCode;
  }
}

// Service Seeker (Customer) model
class ServiceSeeker extends User {
  final String address;
  final List<Address> addresses; // List of addresses
  final String? defaultAddressId; // ID of default address
  final List<String> savedProviders;
  final List<String> recentSearches;
  final String defaultAddress;
  final Map<String, dynamic> paymentMethods;
  final UserSettings settings;

  ServiceSeeker({
    required super.id,
    required super.name,
    required super.email,
    required super.phone,
    super.profileImage,
    required super.createdAt,
    this.address = '',
    this.addresses = const [], // Initialize with empty list
    this.defaultAddressId, // Can be null
    this.savedProviders = const [],
    this.recentSearches = const [],
    this.defaultAddress = '',
    this.paymentMethods = const {},
    required this.settings,
  }) : super(role: 'seeker');

  @override
  ServiceSeeker copyWith({
    String? id,
    String? name,
    String? email,
    String? phone,
    String? profileImage,
    DateTime? createdAt,
    String? role,
    String? address,
    List<Address>? addresses,
    String? defaultAddressId,
    List<String>? savedProviders,
    List<String>? recentSearches,
    String? defaultAddress,
    Map<String, dynamic>? paymentMethods,
    UserSettings? settings,
  }) {
    return ServiceSeeker(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      profileImage: profileImage ?? this.profileImage,
      createdAt: createdAt ?? this.createdAt,
      address: address ?? this.address,
      addresses: addresses ?? this.addresses,
      defaultAddressId: defaultAddressId ?? this.defaultAddressId,
      savedProviders: savedProviders ?? this.savedProviders,
      recentSearches: recentSearches ?? this.recentSearches,
      defaultAddress: defaultAddress ?? this.defaultAddress,
      paymentMethods: paymentMethods ?? this.paymentMethods,
      settings: settings ?? this.settings,
    );
  }

  @override
  Map<String, dynamic> toMap() {
    final map = super.toMap();
    map.addAll({
      'address': address,
      'addresses': addresses.map((x) => x.toMap()).toList(),
      'defaultAddressId': defaultAddressId,
      'savedProviders': savedProviders,
      'recentSearches': recentSearches,
      'defaultAddress': defaultAddress,
      'paymentMethods': paymentMethods,
      'settings': settings.toMap(),
    });
    return map;
  }

  factory ServiceSeeker.fromMap(Map<String, dynamic> map) {
    return ServiceSeeker(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      phone: map['phone'] ?? '',
      profileImage: map['profileImage'] ?? '',
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt']),
      address: map['address'] ?? '',
      addresses: List<Address>.from(
        map['addresses']?.map((x) => Address.fromMap(x)) ?? [],
      ),
      defaultAddressId: map['defaultAddressId'],
      savedProviders: List<String>.from(map['savedProviders'] ?? []),
      recentSearches: List<String>.from(map['recentSearches'] ?? []),
      defaultAddress: map['defaultAddress'] ?? '',
      paymentMethods: Map<String, dynamic>.from(map['paymentMethods'] ?? {}),
      settings: UserSettings.fromMap(map['settings'] ?? {}),
    );
  }
}

// Service Provider model
class ServiceProvider extends User {
  final String businessName;
  final String businessAddress;
  final List<String> services;
  final double rating;
  final int completedJobs;
  final String bio;
  final Map<String, WorkingHours> workingHours;
  final List<DateTime> vacationDays;
  final int bufferTime;
  final bool isAvailable;
  final Map<String, dynamic> pricingSettings;
  final Map<String, dynamic> bankDetails;
  final List<String> workGallery;
  final bool isVerified;
  final String description;
  final List<String> certificates;
  final String? website;
  final UserSettings settings;
  final int reviewCount;
  final int yearsOfExperience;
  final String averageResponseTime;
  final double completionRate;
  final int serviceCount;
  final double latitude;
  final double longitude;
  final String address;

  ServiceProvider({
    required String id,
    required String name,
    required String email,
    required String phone,
    String? profileImage,
    required DateTime createdAt,
    required String role,
    required this.businessName,
    required this.businessAddress,
    required this.services,
    this.rating = 0.0,
    this.completedJobs = 0,
    this.bio = '',
    required this.workingHours,
    required this.vacationDays,
    this.bufferTime = 15,
    this.isAvailable = true,
    required this.pricingSettings,
    required this.bankDetails,
    this.workGallery = const [],
    this.isVerified = false,
    this.description = '',
    this.certificates = const [],
    this.website,
    this.settings = const UserSettings(),
    this.reviewCount = 0,
    this.yearsOfExperience = 0,
    this.averageResponseTime = 'N/A',
    this.completionRate = 0.0,
    this.serviceCount = 0,
    this.latitude = 0.0,
    this.longitude = 0.0,
    this.address = '',
  }) : super(
         id: id,
         name: name,
         email: email,
         phone: phone,
         profileImage: profileImage ?? '',
         createdAt: createdAt,
         role: role,
       );

  @override
  ServiceProvider copyWith({
    String? id,
    String? name,
    String? email,
    String? phone,
    String? profileImage,
    DateTime? createdAt,
    String? role,
    String? businessName,
    String? businessAddress,
    List<String>? services,
    double? rating,
    int? completedJobs,
    String? bio,
    Map<String, WorkingHours>? workingHours,
    List<DateTime>? vacationDays,
    int? bufferTime,
    bool? isAvailable,
    Map<String, dynamic>? pricingSettings,
    Map<String, dynamic>? bankDetails,
    List<String>? workGallery,
    bool? isVerified,
    String? description,
    List<String>? certificates,
    String? website,
    UserSettings? settings,
    int? reviewCount,
    int? yearsOfExperience,
    String? averageResponseTime,
    double? completionRate,
    int? serviceCount,
    double? latitude,
    double? longitude,
    String? address,
  }) {
    return ServiceProvider(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      profileImage: profileImage ?? this.profileImage,
      createdAt: createdAt ?? this.createdAt,
      role: role ?? this.role,
      businessName: businessName ?? this.businessName,
      businessAddress: businessAddress ?? this.businessAddress,
      services: services ?? this.services,
      rating: rating ?? this.rating,
      completedJobs: completedJobs ?? this.completedJobs,
      bio: bio ?? this.bio,
      workingHours: workingHours ?? this.workingHours,
      vacationDays: vacationDays ?? this.vacationDays,
      bufferTime: bufferTime ?? this.bufferTime,
      isAvailable: isAvailable ?? this.isAvailable,
      pricingSettings: pricingSettings ?? this.pricingSettings,
      bankDetails: bankDetails ?? this.bankDetails,
      workGallery: workGallery ?? this.workGallery,
      isVerified: isVerified ?? this.isVerified,
      description: description ?? this.description,
      certificates: certificates ?? this.certificates,
      website: website ?? this.website,
      settings: settings ?? this.settings,
      reviewCount: reviewCount ?? this.reviewCount,
      yearsOfExperience: yearsOfExperience ?? this.yearsOfExperience,
      averageResponseTime: averageResponseTime ?? this.averageResponseTime,
      completionRate: completionRate ?? this.completionRate,
      serviceCount: serviceCount ?? this.serviceCount,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      address: address ?? this.address,
    );
  }

  @override
  Map<String, dynamic> toMap() {
    final map = super.toMap();
    map.addAll({
      'businessName': businessName,
      'businessAddress': businessAddress,
      'services': services,
      'rating': rating,
      'completedJobs': completedJobs,
      'bio': bio,
      'workingHours': workingHours,
      'vacationDays': vacationDays,
      'bufferTime': bufferTime,
      'isAvailable': isAvailable,
      'pricingSettings': pricingSettings,
      'bankDetails': bankDetails,
      'workGallery': workGallery,
      'isVerified': isVerified,
      'description': description,
      'certificates': certificates,
      'website': website,
      'settings': settings.toMap(),
      'reviewCount': reviewCount,
      'yearsOfExperience': yearsOfExperience,
      'averageResponseTime': averageResponseTime,
      'completionRate': completionRate,
      'serviceCount': serviceCount,
      'latitude': latitude,
      'longitude': longitude,
      'address': address,
    });
    return map;
  }

  factory ServiceProvider.fromMap(Map<String, dynamic> map) {
    return ServiceProvider(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      phone: map['phone'] ?? '',
      profileImage: map['profileImage'] ?? '',
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt']),
      role: map['role'] ?? '',
      businessName: map['businessName'] ?? '',
      businessAddress: map['businessAddress'] ?? '',
      services: List<String>.from(map['services'] ?? []),
      rating: map['rating']?.toDouble() ?? 0.0,
      completedJobs: map['completedJobs']?.toInt() ?? 0,
      bio: map['bio'] ?? '',
      workingHours: Map<String, WorkingHours>.from(map['workingHours'] ?? {}),
      vacationDays: List<DateTime>.from(map['vacationDays'] ?? []),
      bufferTime: map['bufferTime']?.toInt() ?? 15,
      isAvailable: map['isAvailable'] ?? true,
      pricingSettings: Map<String, dynamic>.from(map['pricingSettings'] ?? {}),
      bankDetails: Map<String, dynamic>.from(map['bankDetails'] ?? {}),
      workGallery: List<String>.from(map['workGallery'] ?? []),
      isVerified: map['isVerified'] ?? false,
      description: map['description'] ?? '',
      certificates: List<String>.from(map['certificates'] ?? []),
      website: map['website'],
      settings:
          map['settings'] != null
              ? UserSettings.fromMap(map['settings'])
              : const UserSettings(),
      reviewCount: map['reviewCount']?.toInt() ?? 0,
      yearsOfExperience: map['yearsOfExperience']?.toInt() ?? 0,
      averageResponseTime: map['averageResponseTime'] ?? 'N/A',
      completionRate: map['completionRate']?.toDouble() ?? 0.0,
      serviceCount: map['serviceCount']?.toInt() ?? 0,
      latitude: map['latitude']?.toDouble() ?? 0.0,
      longitude: map['longitude']?.toDouble() ?? 0.0,
      address: map['address'] ?? '',
    );
  }
}

// Add this class at the end of the file
class WorkingHours {
  final bool isWorking;
  final String start;
  final String end;
  final List<Break> breaks;

  WorkingHours({
    required this.isWorking,
    required this.start,
    required this.end,
    this.breaks = const [],
  });

  WorkingHours copyWith({
    bool? isWorking,
    String? start,
    String? end,
    List<Break>? breaks,
  }) {
    return WorkingHours(
      isWorking: isWorking ?? this.isWorking,
      start: start ?? this.start,
      end: end ?? this.end,
      breaks: breaks ?? this.breaks,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'isWorking': isWorking,
      'start': start,
      'end': end,
      'breaks': breaks,
    };
  }

  factory WorkingHours.fromMap(Map<String, dynamic> map) {
    return WorkingHours(
      isWorking: map['isWorking'] ?? false,
      start: map['start'] ?? '09:00',
      end: map['end'] ?? '17:00',
      breaks: List<Break>.from(map['breaks'] ?? []),
    );
  }
}

// Add this class after WorkingHours
class Break {
  final String start;
  final String end;

  Break({required this.start, required this.end});

  Map<String, String> toMap() {
    return {'start': start, 'end': end};
  }

  factory Break.fromMap(Map<String, String> map) {
    return Break(start: map['start'] ?? '12:00', end: map['end'] ?? '13:00');
  }
}

// Also add this class
class UserSettings {
  final bool pushNotifications;
  final bool emailNotifications;
  final bool smsNotifications;
  final String language;
  final String theme;
  final bool locationServices;
  final bool savePaymentInfo;
  final Map<String, bool>? notificationPreferences;

  const UserSettings({
    this.pushNotifications = true,
    this.emailNotifications = true,
    this.smsNotifications = false,
    this.language = 'English',
    this.theme = 'system',
    this.locationServices = true,
    this.savePaymentInfo = true,
    this.notificationPreferences,
  });

  UserSettings copyWith({
    bool? pushNotifications,
    bool? emailNotifications,
    bool? smsNotifications,
    String? language,
    String? theme,
    bool? locationServices,
    bool? savePaymentInfo,
    Map<String, bool>? notificationPreferences,
  }) {
    return UserSettings(
      pushNotifications: pushNotifications ?? this.pushNotifications,
      emailNotifications: emailNotifications ?? this.emailNotifications,
      smsNotifications: smsNotifications ?? this.smsNotifications,
      language: language ?? this.language,
      theme: theme ?? this.theme,
      locationServices: locationServices ?? this.locationServices,
      savePaymentInfo: savePaymentInfo ?? this.savePaymentInfo,
      notificationPreferences:
          notificationPreferences ?? this.notificationPreferences,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'pushNotifications': pushNotifications,
      'emailNotifications': emailNotifications,
      'smsNotifications': smsNotifications,
      'language': language,
      'theme': theme,
      'locationServices': locationServices,
      'savePaymentInfo': savePaymentInfo,
      'notificationPreferences': notificationPreferences,
    };
  }

  factory UserSettings.fromMap(Map<String, dynamic> map) {
    return UserSettings(
      pushNotifications: map['pushNotifications'] ?? true,
      emailNotifications: map['emailNotifications'] ?? true,
      smsNotifications: map['smsNotifications'] ?? false,
      language: map['language'] ?? 'English',
      theme: map['theme'] ?? 'system',
      locationServices: map['locationServices'] ?? true,
      savePaymentInfo: map['savePaymentInfo'] ?? true,
      notificationPreferences:
          map['notificationPreferences'] != null
              ? Map<String, bool>.from(map['notificationPreferences'])
              : null,
    );
  }
}
