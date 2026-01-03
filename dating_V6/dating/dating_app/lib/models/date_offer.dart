import 'package:cloud_firestore/cloud_firestore.dart';
import 'gender.dart';

enum DateOfferStatus {
  active, // Initial state, visible to potential matches
  pending, // Has responders but no accepted match yet
  matched, // Successfully matched with a responder
  declined, // Response was declined
  expired, // Past the date/time or manually expired
}

class DateOffer {
  final String id;
  final String creatorId;
  final String creatorName;
  final String? creatorImageUrl;
  final int creatorAge;
  final String title;
  final String? description;
  final String place;
  final DateTime dateTime;
  final double? estimatedCost;
  final List<String> interests;
  final DateOfferStatus status;
  final Map<String, ResponderInfo> responders;
  final String? acceptedResponderId;
  final DateTime createdAt;
  final GeoPoint? location;
  final Gender creatorGender;
  final String city;

  DateOffer({
    required this.id,
    required this.creatorId,
    required this.creatorName,
    this.creatorImageUrl,
    required this.creatorAge,
    required this.title,
    this.description,
    required this.place,
    required this.dateTime,
    this.estimatedCost,
    required this.interests,
    this.status = DateOfferStatus.active,
    this.responders = const {},
    this.acceptedResponderId,
    required this.createdAt,
    this.location,
    required this.creatorGender,
    required this.city,
  });

  factory DateOffer.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final creatorGender = Gender.values.firstWhere(
      (g) => g.toString() == data['creatorGender'],
    );
    return DateOffer(
      id: doc.id,
      creatorId: data['creatorId'],
      creatorName: data['creatorName'],
      creatorImageUrl: data['creatorImageUrl'],
      creatorAge: data['creatorAge'] as int? ?? 0,
      title: data['title'],
      description: data['description'],
      place: data['place'],
      dateTime: (data['dateTime'] as Timestamp).toDate(),
      estimatedCost: data['estimatedCost']?.toDouble(),
      interests: List<String>.from(data['interests'] ?? []),
      status: DateOfferStatus.values.firstWhere(
        (e) => e.toString() == data['status'],
        orElse: () => DateOfferStatus.active,
      ),
      responders:
          (data['responders'] as Map<String, dynamic>?)?.map(
            (key, value) => MapEntry(
              key,
              ResponderInfo.fromMap(value as Map<String, dynamic>),
            ),
          ) ??
          {},
      acceptedResponderId: data['acceptedResponderId'],
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      location: data['location'] as GeoPoint?,
      creatorGender: creatorGender,
      city: data['city'] as String? ?? 'Unknown',
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'creatorId': creatorId,
      'creatorName': creatorName,
      'creatorImageUrl': creatorImageUrl,
      'creatorAge': creatorAge,
      'title': title,
      'description': description,
      'place': place,
      'dateTime': Timestamp.fromDate(dateTime),
      'estimatedCost': estimatedCost,
      'status': status.toString(),
      'responders': responders,
      'acceptedResponderId': acceptedResponderId,
      'interests': interests,
      'createdAt': Timestamp.fromDate(createdAt),
      'location': location,
      'creatorGender': creatorGender.toString(),
      'city': city,
    };
  }

  String? get responderName {
    if (acceptedResponderId == null) return null;
    return responders[acceptedResponderId]?.name;
  }

  String? get responderImageUrl {
    if (acceptedResponderId == null) return null;
    return responders[acceptedResponderId]?.imageUrl;
  }

  String? get responderId => acceptedResponderId;

  List<ResponderInfo> get pendingResponders {
    return responders.values
        .where((r) => r.status == ResponderStatus.pending)
        .toList();
  }

  static DateOffer fromMap(Map<String, dynamic> map, String id) {
    return DateOffer(
      id: id,
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      creatorId: map['creatorId'] ?? '',
      creatorName: map['creatorName'] ?? '',
      creatorImageUrl: map['creatorImageUrl'],
      creatorGender: _parseGender(map['creatorGender']),
      creatorAge: map['creatorAge'] ?? 0,
      place: map['place'] ?? '',
      interests: List<String>.from(map['interests'] ?? []),
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      location: map['location'],
      dateTime: (map['dateTime'] as Timestamp?)?.toDate() ?? DateTime.now(),
      status: _parseStatus(map['status']),
      responders: _parseResponders(map['responders'] ?? {}),
      city: map['city'] ?? 'Unknown',
    );
  }

  static Gender _parseGender(String? genderStr) {
    if (genderStr == null) throw Exception('Gender is required');
    return Gender.values.firstWhere((g) => g.toString() == genderStr);
  }

  static DateOfferStatus _parseStatus(String? statusStr) {
    if (statusStr == null) return DateOfferStatus.active;
    return DateOfferStatus.values.firstWhere(
      (s) => s.toString() == statusStr,
      orElse: () => DateOfferStatus.active,
    );
  }

  static Map<String, ResponderInfo> _parseResponders(
    Map<String, dynamic> respondersMap,
  ) {
    final result = <String, ResponderInfo>{};
    respondersMap.forEach((userId, data) {
      if (data is Map<String, dynamic>) {
        result[userId] = ResponderInfo.fromMap(data);
      }
    });
    return result;
  }

  static ResponderStatus _parseResponderStatus(String? statusStr) {
    if (statusStr == null) return ResponderStatus.pending;
    return ResponderStatus.values.firstWhere(
      (s) => s.toString() == statusStr,
      orElse: () => ResponderStatus.pending,
    );
  }
}

class ResponderInfo {
  final String id;
  final String name;
  final String? imageUrl;
  final DateTime respondedAt;
  final ResponderStatus status;

  ResponderInfo({
    required this.id,
    required this.name,
    this.imageUrl,
    required this.respondedAt,
    required this.status,
  });

  factory ResponderInfo.fromMap(Map<String, dynamic> map) {
    print('Creating ResponderInfo from map: $map');
    return ResponderInfo(
      id: map['id'] ?? '',
      name: map['name'] ?? 'Unknown',
      imageUrl: map['imageUrl'],
      respondedAt:
          map['respondedAt'] is Timestamp
              ? (map['respondedAt'] as Timestamp).toDate()
              : DateTime.now(),
      status: ResponderStatus.values.firstWhere(
        (e) => e.toString() == map['status'],
        orElse: () => ResponderStatus.pending,
      ),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'imageUrl': imageUrl,
      'respondedAt': Timestamp.fromDate(respondedAt),
      'status': status.toString(),
    };
  }
}

enum ResponderStatus { pending, accepted, declined }
