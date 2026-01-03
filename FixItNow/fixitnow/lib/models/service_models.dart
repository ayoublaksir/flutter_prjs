// models/service_models.dart
// Contains all service-related models

import 'dart:convert';
import 'package:flutter/material.dart';
import 'user_models.dart';

// Service Category model
class ServiceCategory {
  final String id;
  final String name;
  final String description;
  final bool isActive;
  final IconData icon;
  final bool isPopular;
  final String imageUrl;
  final List<ServiceItem> services;
  final String iconUrl;
  final int serviceCount;
  final List<String> subcategories;

  ServiceCategory({
    required this.id,
    required this.name,
    required this.description,
    this.isActive = true,
    required this.icon,
    this.isPopular = false,
    required this.imageUrl,
    this.services = const [],
    this.iconUrl = '',
    this.serviceCount = 0,
    this.subcategories = const [],
  });

  ServiceCategory copyWith({
    String? id,
    String? name,
    String? description,
    bool? isActive,
    IconData? icon,
    bool? isPopular,
    String? imageUrl,
    List<ServiceItem>? services,
    String? iconUrl,
    int? serviceCount,
    List<String>? subcategories,
  }) {
    return ServiceCategory(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      isActive: isActive ?? this.isActive,
      icon: icon ?? this.icon,
      isPopular: isPopular ?? this.isPopular,
      imageUrl: imageUrl ?? this.imageUrl,
      services: services ?? this.services,
      iconUrl: iconUrl ?? this.iconUrl,
      serviceCount: serviceCount ?? this.serviceCount,
      subcategories: subcategories ?? this.subcategories,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'isActive': isActive,
      'icon': icon.codePoint,
      'isPopular': isPopular,
      'imageUrl': imageUrl,
      'services': services.map((x) => x.toMap()).toList(),
      'iconUrl': iconUrl,
      'serviceCount': serviceCount,
      'subcategories': subcategories,
    };
  }

  factory ServiceCategory.fromMap(Map<String, dynamic> map) {
    return ServiceCategory(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      isActive: map['isActive'] ?? true,
      icon: IconData(map['icon'] ?? 0, fontFamily: 'MaterialIcons'),
      isPopular: map['isPopular'] ?? false,
      imageUrl: map['imageUrl'] ?? '',
      services: List<ServiceItem>.from(
        map['services']?.map((x) => ServiceItem.fromMap(x)) ?? [],
      ),
      iconUrl: map['iconUrl'] ?? '',
      serviceCount: map['serviceCount'] ?? 0,
      subcategories: List<String>.from(map['subcategories'] ?? []),
    );
  }

  String toJson() => json.encode(toMap());

  factory ServiceCategory.fromJson(String source) =>
      ServiceCategory.fromMap(json.decode(source));

  @override
  String toString() {
    return 'ServiceCategory(id: $id, name: $name, description: $description, isActive: $isActive, icon: $icon, isPopular: $isPopular, imageUrl: $imageUrl, services: $services, iconUrl: $iconUrl, serviceCount: $serviceCount, subcategories: $subcategories)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is ServiceCategory &&
        other.id == id &&
        other.name == name &&
        other.description == description &&
        other.isActive == isActive &&
        other.icon == icon &&
        other.isPopular == isPopular &&
        other.imageUrl == imageUrl &&
        other.services.toString() == services.toString() &&
        other.iconUrl == iconUrl &&
        other.serviceCount == serviceCount &&
        other.subcategories.toString() == subcategories.toString();
  }

  @override
  int get hashCode {
    return id.hashCode ^
        name.hashCode ^
        description.hashCode ^
        isActive.hashCode ^
        icon.hashCode ^
        isPopular.hashCode ^
        imageUrl.hashCode ^
        services.hashCode ^
        iconUrl.hashCode ^
        serviceCount.hashCode ^
        subcategories.hashCode;
  }
}

// Individual Service Item
class ServiceItem {
  final String id;
  final String categoryId;
  final String name;
  final String description;
  final double basePrice;
  final String pricingType; // 'fixed', 'hourly', 'custom'
  final bool isPopular;
  final List<String> tags;
  final Map<String, dynamic>
  additionalOptions; // Extra service options with prices

  ServiceItem({
    required this.id,
    required this.categoryId,
    required this.name,
    required this.description,
    required this.basePrice,
    required this.pricingType,
    this.isPopular = false,
    this.tags = const [],
    this.additionalOptions = const {},
  });

  ServiceItem copyWith({
    String? id,
    String? categoryId,
    String? name,
    String? description,
    double? basePrice,
    String? pricingType,
    bool? isPopular,
    List<String>? tags,
    Map<String, dynamic>? additionalOptions,
  }) {
    return ServiceItem(
      id: id ?? this.id,
      categoryId: categoryId ?? this.categoryId,
      name: name ?? this.name,
      description: description ?? this.description,
      basePrice: basePrice ?? this.basePrice,
      pricingType: pricingType ?? this.pricingType,
      isPopular: isPopular ?? this.isPopular,
      tags: tags ?? this.tags,
      additionalOptions: additionalOptions ?? this.additionalOptions,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'categoryId': categoryId,
      'name': name,
      'description': description,
      'basePrice': basePrice,
      'pricingType': pricingType,
      'isPopular': isPopular,
      'tags': tags,
      'additionalOptions': additionalOptions,
    };
  }

  factory ServiceItem.fromMap(Map<String, dynamic> map) {
    return ServiceItem(
      id: map['id'] ?? '',
      categoryId: map['categoryId'] ?? '',
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      basePrice: map['basePrice']?.toDouble() ?? 0.0,
      pricingType: map['pricingType'] ?? 'fixed',
      isPopular: map['isPopular'] ?? false,
      tags: List<String>.from(map['tags'] ?? []),
      additionalOptions: Map<String, dynamic>.from(
        map['additionalOptions'] ?? {},
      ),
    );
  }

  String toJson() => json.encode(toMap());

  factory ServiceItem.fromJson(String source) =>
      ServiceItem.fromMap(json.decode(source));

  @override
  String toString() {
    return 'ServiceItem(id: $id, categoryId: $categoryId, name: $name, description: $description, basePrice: $basePrice, pricingType: $pricingType, isPopular: $isPopular, tags: $tags, additionalOptions: $additionalOptions)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is ServiceItem &&
        other.id == id &&
        other.categoryId == categoryId &&
        other.name == name &&
        other.description == description &&
        other.basePrice == basePrice &&
        other.pricingType == pricingType &&
        other.isPopular == isPopular &&
        other.tags.toString() == tags.toString() &&
        other.additionalOptions.toString() == additionalOptions.toString();
  }

  @override
  int get hashCode {
    return id.hashCode ^
        categoryId.hashCode ^
        name.hashCode ^
        description.hashCode ^
        basePrice.hashCode ^
        pricingType.hashCode ^
        isPopular.hashCode ^
        tags.hashCode ^
        additionalOptions.hashCode;
  }
}

// Provider Service offering (connects providers to services)
class ProviderService {
  final String id;
  final String providerId;
  final String serviceItemId;
  final String name;
  final String description;
  final double price;
  final String priceType;
  final String categoryId;
  final bool isActive;
  final List<String> images;
  final List<ServiceOption> additionalOptions;
  final List<String> inclusions;

  ProviderService({
    required this.id,
    required this.providerId,
    required this.serviceItemId,
    required this.name,
    required this.description,
    required this.price,
    this.priceType = 'per service',
    required this.categoryId,
    required this.isActive,
    this.images = const [],
    this.additionalOptions = const [],
    this.inclusions = const [],
  });

  ProviderService copyWith({
    String? id,
    String? providerId,
    String? serviceItemId,
    String? name,
    String? description,
    double? price,
    String? priceType,
    String? categoryId,
    bool? isActive,
    List<String>? images,
    List<ServiceOption>? additionalOptions,
    List<String>? inclusions,
  }) {
    return ProviderService(
      id: id ?? this.id,
      providerId: providerId ?? this.providerId,
      serviceItemId: serviceItemId ?? this.serviceItemId,
      name: name ?? this.name,
      description: description ?? this.description,
      price: price ?? this.price,
      priceType: priceType ?? this.priceType,
      categoryId: categoryId ?? this.categoryId,
      isActive: isActive ?? this.isActive,
      images: images ?? this.images,
      additionalOptions: additionalOptions ?? this.additionalOptions,
      inclusions: inclusions ?? this.inclusions,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'providerId': providerId,
      'serviceItemId': serviceItemId,
      'name': name,
      'description': description,
      'price': price,
      'priceType': priceType,
      'categoryId': categoryId,
      'isActive': isActive,
      'images': images,
      'additionalOptions': additionalOptions.map((x) => x.toMap()).toList(),
      'inclusions': inclusions,
    };
  }

  factory ProviderService.fromMap(Map<String, dynamic> map) {
    return ProviderService(
      id: map['id'] ?? '',
      providerId: map['providerId'] ?? '',
      serviceItemId: map['serviceItemId'] ?? '',
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      price: (map['price'] ?? 0.0).toDouble(),
      priceType: map['priceType'] ?? 'per service',
      categoryId: map['categoryId'] ?? '',
      isActive: map['isActive'] ?? true,
      images: List<String>.from(map['images'] ?? []),
      additionalOptions:
          List<ServiceOption>.from(
            map['additionalOptions']?.map((x) => ServiceOption.fromMap(x)),
          ) ??
          [],
      inclusions: List<String>.from(map['inclusions'] ?? []),
    );
  }

  String toJson() => json.encode(toMap());

  factory ProviderService.fromJson(String source) =>
      ProviderService.fromMap(json.decode(source));
}

// Service Option
class ServiceOption {
  final String name;
  final double price;
  final String description;

  ServiceOption({
    required this.name,
    required this.price,
    this.description = '',
  });

  Map<String, dynamic> toMap() => {
    'name': name,
    'price': price,
    'description': description,
  };

  factory ServiceOption.fromMap(Map<String, dynamic> map) {
    return ServiceOption(
      name: map['name'] ?? '',
      price: (map['price'] ?? 0.0).toDouble(),
      description: map['description'] ?? '',
    );
  }
}

// Recurring Service
class RecurringService {
  final String id;
  final String userId;
  final String providerId;
  final String serviceId;
  final String serviceName;
  final ServiceProvider provider;
  final String frequency;
  final DateTime startDate;
  final DateTime nextServiceDate;
  final double price;
  final String status;
  final Map<String, dynamic> details;

  RecurringService({
    required this.id,
    required this.userId,
    required this.providerId,
    required this.serviceId,
    required this.serviceName,
    required this.provider,
    required this.frequency,
    required this.startDate,
    required this.nextServiceDate,
    required this.price,
    required this.status,
    this.details = const {},
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'providerId': providerId,
      'serviceId': serviceId,
      'serviceName': serviceName,
      'frequency': frequency,
      'startDate': startDate.millisecondsSinceEpoch,
      'nextServiceDate': nextServiceDate.millisecondsSinceEpoch,
      'price': price,
      'status': status,
      'details': details,
    };
  }

  factory RecurringService.fromMap(
    Map<String, dynamic> map,
    ServiceProvider provider,
  ) {
    return RecurringService(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      providerId: map['providerId'] ?? '',
      serviceId: map['serviceId'] ?? '',
      serviceName: map['serviceName'] ?? '',
      provider: provider,
      frequency: map['frequency'] ?? '',
      startDate: DateTime.fromMillisecondsSinceEpoch(map['startDate']),
      nextServiceDate: DateTime.fromMillisecondsSinceEpoch(
        map['nextServiceDate'],
      ),
      price: map['price']?.toDouble() ?? 0.0,
      status: map['status'] ?? '',
      details: Map<String, dynamic>.from(map['details'] ?? {}),
    );
  }
}

// Service Details Model
class ServiceDetails {
  final String id;
  final String providerId;
  final String name;
  final String description;
  final double price;
  final int durationMinutes;
  final List<String> images;
  final double rating;
  final String category;
  final bool isAvailable;
  final Map<String, dynamic> additionalOptions;
  final List<String> inclusions;
  final List<String> exclusions;
  final List<String> tags;

  ServiceDetails({
    required this.id,
    required this.providerId,
    required this.name,
    required this.description,
    required this.price,
    required this.durationMinutes,
    this.images = const [],
    this.rating = 0.0,
    required this.category,
    this.isAvailable = true,
    this.additionalOptions = const {},
    this.inclusions = const [],
    this.exclusions = const [],
    this.tags = const [],
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'providerId': providerId,
      'name': name,
      'description': description,
      'price': price,
      'durationMinutes': durationMinutes,
      'images': images,
      'rating': rating,
      'category': category,
      'isAvailable': isAvailable,
      'additionalOptions': additionalOptions,
      'inclusions': inclusions,
      'exclusions': exclusions,
      'tags': tags,
    };
  }

  factory ServiceDetails.fromMap(Map<String, dynamic> map) {
    return ServiceDetails(
      id: map['id'] ?? '',
      providerId: map['providerId'] ?? '',
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      price: (map['price'] ?? 0.0).toDouble(),
      durationMinutes: map['durationMinutes'] ?? 0,
      images: List<String>.from(map['images'] ?? []),
      rating: (map['rating'] ?? 0.0).toDouble(),
      category: map['category'] ?? '',
      isAvailable: map['isAvailable'] ?? true,
      additionalOptions: Map<String, dynamic>.from(
        map['additionalOptions'] ?? {},
      ),
      inclusions: List<String>.from(map['inclusions'] ?? []),
      exclusions: List<String>.from(map['exclusions'] ?? []),
      tags: List<String>.from(map['tags'] ?? []),
    );
  }
}
