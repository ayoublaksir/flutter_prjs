import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/date_models.dart';
import '../models/date_category.dart';
import '../models/place.dart';
import '../models/gender.dart';

class PlacesService {
  final String apiKey = 'AIzaSyA0ng4k81a8VMxkEPQ45Hix4SNIhH5ATZA';

  Future<List<Place>> getPlacesByFilters({
    required String city,
    required List<DateCategory> categories,
    required LatLng location,
    double radius = 10000,
    double? maxPrice,
  }) async {
    try {
      // First get the city bounds
      final cityBounds = await getCityBounds(city);
      if (cityBounds == null) {
        throw Exception('Could not find city boundaries');
      }

      // Get places for each category in parallel
      final futures = categories.map(
        (category) => _getPlacesForCategory(
          category: category,
          location: location,
          radius: radius,
          maxPrice: maxPrice,
          bounds: cityBounds,
        ),
      );

      final results = await Future.wait(futures);

      // Combine and deduplicate results
      final allPlaces = results.expand((places) => places).toList();
      final uniquePlaces = <String, Place>{};
      for (var place in allPlaces) {
        uniquePlaces[place.id] = place;
      }

      return uniquePlaces.values.toList();
    } catch (e) {
      print('Error fetching places: $e');
      throw Exception('Failed to fetch places: $e');
    }
  }

  Future<Map<String, dynamic>?> getCityBounds(String city) async {
    try {
      final url = Uri.parse(
        'https://maps.googleapis.com/maps/api/geocode/json'
        '?address=$city'
        '&key=$apiKey',
      );

      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['results'] != null && data['results'].isNotEmpty) {
          return data['results'][0]['geometry']['viewport'];
        }
      }
      return null;
    } catch (e) {
      print('Error getting city bounds: $e');
      return null;
    }
  }

  Future<List<Place>> _getPlacesForCategory({
    required DateCategory category,
    required LatLng location,
    required double radius,
    double? maxPrice,
    Map<String, dynamic>? bounds,
  }) async {
    try {
      final type = _getCategoryType(category);
      final queryParams = {
        'location': '${location.latitude},${location.longitude}',
        'radius': radius.toString(),
        'type': type,
        'key': apiKey,
      };

      if (bounds != null) {
        queryParams['bounds'] =
            '${bounds['southwest']['lat']},${bounds['southwest']['lng']}|${bounds['northeast']['lat']},${bounds['northeast']['lng']}';
      }

      if (maxPrice != null) {
        queryParams['maxprice'] = (maxPrice / 25).round().toString();
      }

      final url = Uri.https(
        'maps.googleapis.com',
        '/maps/api/place/nearbysearch/json',
        queryParams,
      );

      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return _parsePlacesResponse(data, maxPrice ?? double.infinity);
      } else {
        print('Places API Error: ${response.statusCode}');
        throw Exception('Failed to fetch places');
      }
    } catch (e) {
      print('Error fetching places for category $category: $e');
      return [];
    }
  }

  String _getCategoryType(DateCategory category) {
    // Using the correct type values from Places API documentation
    switch (category) {
      case DateCategory.restaurant:
        return 'restaurant';
      case DateCategory.cafe:
        return 'cafe';
      case DateCategory.bar:
        return 'bar';
      case DateCategory.park:
        return 'park';
      case DateCategory.museum:
        return 'museum|art_gallery';
      case DateCategory.movie:
        return 'movie_theater';
      case DateCategory.concert:
        return 'night_club';
      case DateCategory.beach:
        return 'natural_feature';
      case DateCategory.outdoorActivity:
        return 'park|hiking_trail';
      case DateCategory.sportsEvent:
        return 'stadium';
      case DateCategory.cookingClass:
        return 'restaurant|cafe';
      default:
        return 'tourist_attraction';
    }
  }

  List<Place> _parsePlacesResponse(Map<String, dynamic> data, double budget) {
    List<Place> places = [];
    if (data['results'] == null) return places;

    for (var result in data['results']) {
      try {
        final priceLevel = result['price_level'] ?? 2;
        final estimatedCost = priceLevel * 25.0;

        if (estimatedCost <= budget) {
          places.add(
            Place(
              id: result['place_id'] ?? '',
              name: result['name'] ?? '',
              description: result['vicinity'] ?? '',
              rating: (result['rating'] ?? 0.0).toDouble(),
              address: result['vicinity'] ?? '',
              latitude: result['geometry']['location']['lat'] ?? 0.0,
              longitude: result['geometry']['location']['lng'] ?? 0.0,
              categories: _extractCategories(result['types'] ?? []),
              moods: [],
              priceRange: estimatedCost,
              openingHours:
                  result['opening_hours']?['open_now'] == true
                      ? 'Open'
                      : 'Closed',
              amenities: [],
              websiteUrl: result['website'] ?? '',
              phoneNumber: result['formatted_phone_number'] ?? '',
              isActive: true,
            ),
          );
        }
      } catch (e) {
        print('Error parsing place: $e');
        continue;
      }
    }
    return places;
  }

  List<String> _extractCategories(List<dynamic> types) {
    final categoryMapping = {
      'restaurant': 'Restaurant',
      'cafe': 'Cafe',
      'bar': 'Bar',
      'park': 'Outdoor Activity',
      'museum': 'Museum',
      'art_gallery': 'Museum',
      'movie_theater': 'Movie',
      'night_club': 'Concert',
      'stadium': 'Sports',
      'natural_feature': 'Outdoor',
      'tourist_attraction': 'Tourist Spot',
    };

    return types
        .map((type) => categoryMapping[type.toString()] ?? type.toString())
        .where((category) => category != null)
        .toSet()
        .toList();
  }

  Future<List<Map<String, dynamic>>> searchNearbyPlaces(
    double latitude,
    double longitude,
    String type,
    int radius,
  ) async {
    // Simulate API call
    await Future.delayed(Duration(milliseconds: 500));

    // Return mock data
    return [
      {
        'name': 'Central Park',
        'address': '123 Park Avenue',
        'rating': 4.8,
        'photos': ['https://example.com/photo1.jpg'],
        'types': ['park', 'tourist_attraction'],
        'price_level': 0,
      },
      {
        'name': 'Cafe Milano',
        'address': '456 Main Street',
        'rating': 4.5,
        'photos': ['https://example.com/photo2.jpg'],
        'types': ['cafe', 'restaurant'],
        'price_level': 2,
      },
    ];
  }

  // Add back the method needed by RecommendationService
  Future<List<Place>> getPlacesByCategory(
    DateCategory category,
    LatLng location,
    double maxPrice,
  ) async {
    return getPlacesByFilters(
      city: '', // Empty city means no city restriction
      categories: [category],
      location: location,
      maxPrice: maxPrice,
    );
  }

  Gender _getOppositeGender(Gender userGender) {
    return userGender == Gender.male ? Gender.female : Gender.male;
  }
}
