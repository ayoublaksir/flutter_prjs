import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/place.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class PlaceSearchService {
  final String apiKey =
      'AIzaSyA0ng4k81a8VMxkEPQ45Hix4SNIhH5ATZA'; // Replace with your API key

  Future<List<Place>> searchPlaces(String query) async {
    if (query.isEmpty) return [];

    final url = Uri.parse(
      'https://maps.googleapis.com/maps/api/place/textsearch/json?query=$query&key=$apiKey',
    );

    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final results = data['results'] as List;

      return results.map((place) {
        return Place(
          id: place['place_id'],
          name: place['name'],
          description: place['formatted_address'] ?? '',
          rating: place['rating']?.toDouble() ?? 0.0,
          address: place['formatted_address'] ?? '',
          latitude: place['geometry']['location']['lat'],
          longitude: place['geometry']['location']['lng'],
          categories: _extractTypes(place['types']),
          moods: [],
          priceRange: place['price_level']?.toDouble() ?? 0.0,
          openingHours: '',
          amenities: [],
        );
      }).toList();
    } else {
      throw Exception('Failed to search places');
    }
  }

  List<String> _extractTypes(List? types) {
    if (types == null) return [];

    // Convert API types to user-friendly categories
    final Map<String, String> typeMapping = {
      'restaurant': 'Dining',
      'cafe': 'Coffee',
      'bar': 'Nightlife',
      'movie_theater': 'Movies',
      'park': 'Outdoor',
      'museum': 'Cultural',
      'art_gallery': 'Art',
      'shopping_mall': 'Shopping',
      'gym': 'Fitness',
    };

    return types
        .map((type) => typeMapping[type.toString()] ?? type.toString())
        .where((type) => type != null)
        .toSet() // Remove duplicates
        .toList();
  }

  String _formatOpeningHours(List? weekdayText) {
    if (weekdayText == null || weekdayText.isEmpty)
      return 'Hours not available';
    return weekdayText.join('\n');
  }

  Future<String> getPlacePhotoUrl(
    String photoReference, {
    int maxWidth = 400,
  }) async {
    return 'https://maps.googleapis.com/maps/api/place/photo?maxwidth=$maxWidth&photo_reference=$photoReference&key=$apiKey';
  }

  Future<List<Place>> searchNearbyPlaces(
    double latitude,
    double longitude, {
    int radius = 1000,
  }) async {
    final url = Uri.parse(
      'https://maps.googleapis.com/maps/api/place/nearbysearch/json?'
      'location=$latitude,$longitude'
      '&radius=$radius'
      '&key=$apiKey',
    );

    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final results = data['results'] as List;

      return results.map((place) {
        return Place(
          id: place['place_id'],
          name: place['name'],
          description: place['vicinity'] ?? '',
          rating: place['rating']?.toDouble() ?? 0.0,
          address: place['vicinity'] ?? '',
          latitude: place['geometry']['location']['lat'],
          longitude: place['geometry']['location']['lng'],
          categories: _extractTypes(place['types']),
          moods: [],
          priceRange: place['price_level']?.toDouble() ?? 0.0,
          openingHours: '',
          amenities: [],
        );
      }).toList();
    } else {
      throw Exception('Failed to search nearby places');
    }
  }
}
