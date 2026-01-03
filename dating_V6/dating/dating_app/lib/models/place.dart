class Place {
  final String id;
  final String name;
  final String description;
  final double rating;
  final String address;
  final double latitude;
  final double longitude;
  final List<String> categories;
  final List<String> moods;
  final bool isActive; // New field to control visibility
  final double priceRange;
  final String openingHours;
  final List<String> amenities;
  final String websiteUrl;
  final String phoneNumber;

  Place({
    required this.id,
    required this.name,
    required this.description,
    required this.rating,
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.categories,
    required this.moods,
    this.isActive = true,
    required this.priceRange,
    required this.openingHours,
    required this.amenities,
    this.websiteUrl = '',
    this.phoneNumber = '',
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'rating': rating,
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
      'categories': categories,
      'moods': moods,
      'isActive': isActive,
      'priceRange': priceRange,
      'openingHours': openingHours,
      'amenities': amenities,
      'websiteUrl': websiteUrl,
      'phoneNumber': phoneNumber,
    };
  }

  factory Place.fromMap(Map<String, dynamic> map) {
    return Place(
      id: map['id'],
      name: map['name'],
      description: map['description'],
      rating: map['rating'],
      address: map['address'],
      latitude: map['latitude'],
      longitude: map['longitude'],
      categories: List<String>.from(map['categories']),
      moods: List<String>.from(map['moods']),
      isActive: map['isActive'] ?? true,
      priceRange: map['priceRange'],
      openingHours: map['openingHours'],
      amenities: List<String>.from(map['amenities']),
      websiteUrl: map['websiteUrl'] ?? '',
      phoneNumber: map['phoneNumber'] ?? '',
    );
  }
}
