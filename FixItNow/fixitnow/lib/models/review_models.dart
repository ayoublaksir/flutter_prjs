// models/review_models.dart
// Contains review-related models

import 'dart:convert';

class Review {
  final String id;
  final String providerId;
  final String seekerId;
  final String bookingId;
  final double rating;
  final String comment;
  final DateTime timestamp;
  final String? response;
  final String reviewerName;
  final String? reviewerImage;
  final String? serviceDetails;
  final List<String> images;

  Review({
    required this.id,
    required this.providerId,
    required this.seekerId,
    required this.bookingId,
    required this.rating,
    required this.comment,
    required this.timestamp,
    this.response,
    required this.reviewerName,
    this.reviewerImage,
    this.serviceDetails,
    this.images = const [],
  });

  Review copyWith({
    String? id,
    String? providerId,
    String? seekerId,
    String? bookingId,
    double? rating,
    String? comment,
    DateTime? timestamp,
    String? response,
    String? reviewerName,
    String? reviewerImage,
    String? serviceDetails,
    List<String>? images,
  }) {
    return Review(
      id: id ?? this.id,
      providerId: providerId ?? this.providerId,
      seekerId: seekerId ?? this.seekerId,
      bookingId: bookingId ?? this.bookingId,
      rating: rating ?? this.rating,
      comment: comment ?? this.comment,
      timestamp: timestamp ?? this.timestamp,
      response: response ?? this.response,
      reviewerName: reviewerName ?? this.reviewerName,
      reviewerImage: reviewerImage ?? this.reviewerImage,
      serviceDetails: serviceDetails ?? this.serviceDetails,
      images: images ?? this.images,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'providerId': providerId,
      'seekerId': seekerId,
      'bookingId': bookingId,
      'rating': rating,
      'comment': comment,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'response': response,
      'reviewerName': reviewerName,
      'reviewerImage': reviewerImage,
      'serviceDetails': serviceDetails,
      'images': images,
    };
  }

  factory Review.fromMap(Map<String, dynamic> map) {
    return Review(
      id: map['id'] ?? '',
      providerId: map['providerId'] ?? '',
      seekerId: map['seekerId'] ?? '',
      bookingId: map['bookingId'] ?? '',
      rating: (map['rating'] ?? 0.0).toDouble(),
      comment: map['comment'] ?? '',
      timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp']),
      response: map['response'],
      reviewerName: map['reviewerName'] ?? '',
      reviewerImage: map['reviewerImage'],
      serviceDetails: map['serviceDetails'],
      images: List<String>.from(map['images'] ?? []),
    );
  }

  String toJson() => json.encode(toMap());

  factory Review.fromJson(String source) => Review.fromMap(json.decode(source));
}
