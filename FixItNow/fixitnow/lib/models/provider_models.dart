import 'user_models.dart';
import 'dart:convert';
import 'package:flutter/material.dart';

// This file contains models specific to service providers
// The main ServiceProvider class is in user_models.dart

// Portfolio Item model
class PortfolioItem {
  final String id;
  final String title;
  final String description;
  final List<String> images;
  final DateTime createdAt;

  PortfolioItem({
    required this.id,
    required this.title,
    required this.description,
    required this.images,
    required this.createdAt,
  });

  PortfolioItem copyWith({
    String? id,
    String? title,
    String? description,
    List<String>? images,
    DateTime? createdAt,
  }) {
    return PortfolioItem(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      images: images ?? this.images,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'images': images,
      'createdAt': createdAt.millisecondsSinceEpoch,
    };
  }

  factory PortfolioItem.fromMap(Map<String, dynamic> map) {
    return PortfolioItem(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      images: List<String>.from(map['images'] ?? []),
      createdAt: DateTime.fromMillisecondsSinceEpoch(
        map['createdAt'] ?? DateTime.now().millisecondsSinceEpoch,
      ),
    );
  }
}

// Provider statistics model
class ProviderStats {
  final int totalBookings;
  final int pendingBookings;
  final int completedBookings;
  final int cancelledBookings;
  final double totalEarnings;
  final double rating;
  final int totalReviews;

  ProviderStats({
    required this.totalBookings,
    required this.pendingBookings,
    required this.completedBookings,
    required this.cancelledBookings,
    required this.totalEarnings,
    required this.rating,
    required this.totalReviews,
  });

  ProviderStats copyWith({
    int? totalBookings,
    int? pendingBookings,
    int? completedBookings,
    int? cancelledBookings,
    double? totalEarnings,
    double? rating,
    int? totalReviews,
  }) {
    return ProviderStats(
      totalBookings: totalBookings ?? this.totalBookings,
      pendingBookings: pendingBookings ?? this.pendingBookings,
      completedBookings: completedBookings ?? this.completedBookings,
      cancelledBookings: cancelledBookings ?? this.cancelledBookings,
      totalEarnings: totalEarnings ?? this.totalEarnings,
      rating: rating ?? this.rating,
      totalReviews: totalReviews ?? this.totalReviews,
    );
  }

  factory ProviderStats.fromMap(Map<String, dynamic> map) {
    return ProviderStats(
      totalBookings: map['totalBookings'] ?? 0,
      pendingBookings: map['pendingBookings'] ?? 0,
      completedBookings: map['completedBookings'] ?? 0,
      cancelledBookings: map['cancelledBookings'] ?? 0,
      totalEarnings: (map['totalEarnings'] ?? 0).toDouble(),
      rating: (map['rating'] ?? 0).toDouble(),
      totalReviews: map['totalReviews'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'totalBookings': totalBookings,
      'pendingBookings': pendingBookings,
      'completedBookings': completedBookings,
      'cancelledBookings': cancelledBookings,
      'totalEarnings': totalEarnings,
      'rating': rating,
      'totalReviews': totalReviews,
    };
  }
}

// Working Hours model
class WorkingHours {
  final bool isWorking;
  final String start;
  final String end;

  WorkingHours({
    this.isWorking = false,
    this.start = '09:00',
    this.end = '17:00',
  });

  WorkingHours copyWith({bool? isWorking, String? start, String? end}) {
    return WorkingHours(
      isWorking: isWorking ?? this.isWorking,
      start: start ?? this.start,
      end: end ?? this.end,
    );
  }

  Map<String, dynamic> toMap() {
    return {'isWorking': isWorking, 'start': start, 'end': end};
  }

  factory WorkingHours.fromMap(Map<String, dynamic> map) {
    return WorkingHours(
      isWorking: map['isWorking'] ?? false,
      start: map['start'] ?? '09:00',
      end: map['end'] ?? '17:00',
    );
  }

  String toJson() => json.encode(toMap());

  factory WorkingHours.fromJson(String source) =>
      WorkingHours.fromMap(json.decode(source));
}

// Pricing Settings model
class PricingSettings {
  final double baseHourlyRate;
  final double minimumServiceFee;
  final double cancellationFee;
  final double weekendRate;
  final double emergencyRate;
  final double holidayRate;
  final double discount;
  final bool offerDiscount;

  PricingSettings({
    this.baseHourlyRate = 0.0,
    this.minimumServiceFee = 0.0,
    this.cancellationFee = 0.0,
    this.weekendRate = 0.0,
    this.emergencyRate = 0.0,
    this.holidayRate = 0.0,
    this.discount = 0.0,
    this.offerDiscount = false,
  });

  PricingSettings copyWith({
    double? baseHourlyRate,
    double? minimumServiceFee,
    double? cancellationFee,
    double? weekendRate,
    double? emergencyRate,
    double? holidayRate,
    double? discount,
    bool? offerDiscount,
  }) {
    return PricingSettings(
      baseHourlyRate: baseHourlyRate ?? this.baseHourlyRate,
      minimumServiceFee: minimumServiceFee ?? this.minimumServiceFee,
      cancellationFee: cancellationFee ?? this.cancellationFee,
      weekendRate: weekendRate ?? this.weekendRate,
      emergencyRate: emergencyRate ?? this.emergencyRate,
      holidayRate: holidayRate ?? this.holidayRate,
      discount: discount ?? this.discount,
      offerDiscount: offerDiscount ?? this.offerDiscount,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'baseHourlyRate': baseHourlyRate,
      'minimumServiceFee': minimumServiceFee,
      'cancellationFee': cancellationFee,
      'weekendRate': weekendRate,
      'emergencyRate': emergencyRate,
      'holidayRate': holidayRate,
      'discount': discount,
      'offerDiscount': offerDiscount,
    };
  }

  factory PricingSettings.fromMap(Map<String, dynamic> map) {
    return PricingSettings(
      baseHourlyRate: (map['baseHourlyRate'] ?? 0.0).toDouble(),
      minimumServiceFee: (map['minimumServiceFee'] ?? 0.0).toDouble(),
      cancellationFee: (map['cancellationFee'] ?? 0.0).toDouble(),
      weekendRate: (map['weekendRate'] ?? 0.0).toDouble(),
      emergencyRate: (map['emergencyRate'] ?? 0.0).toDouble(),
      holidayRate: (map['holidayRate'] ?? 0.0).toDouble(),
      discount: (map['discount'] ?? 0.0).toDouble(),
      offerDiscount: map['offerDiscount'] ?? false,
    );
  }

  String toJson() => json.encode(toMap());

  factory PricingSettings.fromJson(String source) =>
      PricingSettings.fromMap(json.decode(source));
}

// Provider Details model
class ProviderDetails {
  final String id;
  final String name;
  final String businessName;
  final String email;
  final String phone;
  final String profileImage;
  final String bio;
  final double rating;
  final int reviewCount;
  final int completedJobs;
  final bool isVerified;
  final List<String> certificates;
  final List<String> serviceCategories;
  final List<String> serviceIds;
  final Map<String, WorkingHours> workingHours;
  final List<DateTime> vacationDays;
  final PricingSettings? pricingSettings;
  final List<String> workGallery;
  final String address;
  final String website;
  final int yearsOfExperience;
  final bool isAvailable;
  final double completionRate;
  final String responseTime;

  ProviderDetails({
    required this.id,
    required this.name,
    required this.businessName,
    required this.email,
    required this.phone,
    this.profileImage = '',
    this.bio = '',
    this.rating = 0.0,
    this.reviewCount = 0,
    this.completedJobs = 0,
    this.isVerified = false,
    this.certificates = const [],
    this.serviceCategories = const [],
    this.serviceIds = const [],
    required this.workingHours,
    this.vacationDays = const [],
    this.pricingSettings,
    this.workGallery = const [],
    required this.address,
    this.website = '',
    this.yearsOfExperience = 0,
    this.isAvailable = true,
    this.completionRate = 0.0,
    this.responseTime = '',
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'businessName': businessName,
      'email': email,
      'phone': phone,
      'profileImage': profileImage,
      'bio': bio,
      'rating': rating,
      'reviewCount': reviewCount,
      'completedJobs': completedJobs,
      'isVerified': isVerified,
      'certificates': certificates,
      'serviceCategories': serviceCategories,
      'serviceIds': serviceIds,
      'workingHours': workingHours.map(
        (key, value) => MapEntry(key, value.toMap()),
      ),
      'vacationDays':
          vacationDays.map((x) => x.millisecondsSinceEpoch).toList(),
      'pricingSettings': pricingSettings?.toMap(),
      'workGallery': workGallery,
      'address': address,
      'website': website,
      'yearsOfExperience': yearsOfExperience,
      'isAvailable': isAvailable,
      'completionRate': completionRate,
      'responseTime': responseTime,
    };
  }

  factory ProviderDetails.fromMap(Map<String, dynamic> map) {
    return ProviderDetails(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      businessName: map['businessName'] ?? '',
      email: map['email'] ?? '',
      phone: map['phone'] ?? '',
      profileImage: map['profileImage'] ?? '',
      bio: map['bio'] ?? '',
      rating: (map['rating'] ?? 0.0).toDouble(),
      reviewCount: map['reviewCount'] ?? 0,
      completedJobs: map['completedJobs'] ?? 0,
      isVerified: map['isVerified'] ?? false,
      certificates: List<String>.from(map['certificates'] ?? []),
      serviceCategories: List<String>.from(map['serviceCategories'] ?? []),
      serviceIds: List<String>.from(map['serviceIds'] ?? []),
      workingHours:
          (map['workingHours'] as Map<String, dynamic>?)?.map(
            (key, value) => MapEntry(key, WorkingHours.fromMap(value)),
          ) ??
          {},
      vacationDays:
          (map['vacationDays'] as List<dynamic>?)
              ?.map((x) => DateTime.fromMillisecondsSinceEpoch(x))
              .toList() ??
          [],
      pricingSettings:
          map['pricingSettings'] != null
              ? PricingSettings.fromMap(map['pricingSettings'])
              : null,
      workGallery: List<String>.from(map['workGallery'] ?? []),
      address: map['address'] ?? '',
      website: map['website'] ?? '',
      yearsOfExperience: map['yearsOfExperience'] ?? 0,
      isAvailable: map['isAvailable'] ?? true,
      completionRate: (map['completionRate'] ?? 0.0).toDouble(),
      responseTime: map['responseTime'] ?? '',
    );
  }
}

// Bank Account model
class BankAccount {
  final String id;
  final String userId;
  final String accountName;
  final String accountNumber;
  final String routingNumber;
  final String bankName;
  final DateTime createdAt;
  final DateTime updatedAt;

  BankAccount({
    required this.id,
    required this.userId,
    required this.accountName,
    required this.accountNumber,
    required this.routingNumber,
    required this.bankName,
    required this.createdAt,
    required this.updatedAt,
  });

  BankAccount copyWith({
    String? id,
    String? userId,
    String? accountName,
    String? accountNumber,
    String? routingNumber,
    String? bankName,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return BankAccount(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      accountName: accountName ?? this.accountName,
      accountNumber: accountNumber ?? this.accountNumber,
      routingNumber: routingNumber ?? this.routingNumber,
      bankName: bankName ?? this.bankName,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'accountName': accountName,
      'accountNumber': accountNumber,
      'routingNumber': routingNumber,
      'bankName': bankName,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'updatedAt': updatedAt.millisecondsSinceEpoch,
    };
  }

  factory BankAccount.fromMap(Map<String, dynamic> map) {
    return BankAccount(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      accountName: map['accountName'] ?? '',
      accountNumber: map['accountNumber'] ?? '',
      routingNumber: map['routingNumber'] ?? '',
      bankName: map['bankName'] ?? '',
      createdAt: DateTime.fromMillisecondsSinceEpoch(
        map['createdAt'] ?? DateTime.now().millisecondsSinceEpoch,
      ),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(
        map['updatedAt'] ?? DateTime.now().millisecondsSinceEpoch,
      ),
    );
  }
}
