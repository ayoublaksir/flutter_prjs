# Places Listing Implementation Guide
## Complete Guide for Building Places Discovery with Google Places API

Based on a comprehensive audit of a Flutter dating app's places discovery system, this guide provides everything needed to implement sophisticated place listing with Google Places API integration, advanced filtering, and intelligent recommendations.

---

## 🏗️ System Architecture

### Core Components Structure
```
📁 Project Structure
├── 📁 models/
│   ├── place.dart              # Place data model with 15+ fields
│   ├── date_category.dart      # 11 predefined categories
│   └── user_preferences.dart   # User filtering preferences
├── 📁 services/
│   ├── places_service.dart     # Google Places API integration
│   └── recommendation_service.dart # Smart filtering logic
├── 📁 screens/
│   ├── filtered_places_screen.dart # Main UI with filters
│   └── place_details_screen.dart   # Individual place view
└── 📁 widgets/
    └── place_card.dart         # Reusable place display
```

---

## 📊 Data Models Implementation

### 1. Comprehensive Place Model
```dart
class Place {
  final String id;              // Google Place ID (unique identifier)
  final String name;            // Business/location name
  final String description;     // Short description from vicinity
  final double rating;          // Google rating (0.0-5.0)
  final String address;         // Full formatted address
  final double latitude;        // GPS coordinates
  final double longitude;       // GPS coordinates
  final List<String> categories; // Mapped place types
  final List<String> moods;     // Associated vibes/atmospheres
  final bool isActive;          // Visibility control flag
  final double priceRange;      // Estimated cost (0-100 scale)
  final String openingHours;    // Current status (Open/Closed)
  final List<String> amenities; // Available facilities
  final String websiteUrl;      // Official website
  final String phoneNumber;     // Contact information

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

  // JSON serialization for caching/storage
  Map<String, dynamic> toMap() => {
    'id': id, 'name': name, 'description': description,
    'rating': rating, 'address': address, 'latitude': latitude,
    'longitude': longitude, 'categories': categories, 'moods': moods,
    'isActive': isActive, 'priceRange': priceRange,
    'openingHours': openingHours, 'amenities': amenities,
    'websiteUrl': websiteUrl, 'phoneNumber': phoneNumber,
  };

  factory Place.fromMap(Map<String, dynamic> map) => Place(
    id: map['id'], name: map['name'], description: map['description'],
    rating: map['rating'], address: map['address'], latitude: map['latitude'],
    longitude: map['longitude'], categories: List<String>.from(map['categories']),
    moods: List<String>.from(map['moods']), isActive: map['isActive'] ?? true,
    priceRange: map['priceRange'], openingHours: map['openingHours'],
    amenities: List<String>.from(map['amenities']),
    websiteUrl: map['websiteUrl'] ?? '', phoneNumber: map['phoneNumber'] ?? '',
  );
}
```

### 2. Category System with Display Names
```dart
enum DateCategory {
  restaurant, cafe, bar, outdoorActivity, movie, concert,
  museum, park, beach, sportsEvent, cookingClass,
}

extension DateCategoryExtension on DateCategory {
  String get displayName {
    switch (this) {
      case DateCategory.restaurant: return 'Restaurant';
      case DateCategory.cafe: return 'Cafe';
      case DateCategory.bar: return 'Bar';
      case DateCategory.outdoorActivity: return 'Outdoor Activity';
      case DateCategory.movie: return 'Movie';
      case DateCategory.concert: return 'Concert';
      case DateCategory.museum: return 'Museum';
      case DateCategory.park: return 'Park';
      case DateCategory.beach: return 'Beach';
      case DateCategory.sportsEvent: return 'Sports Event';
      case DateCategory.cookingClass: return 'Cooking Class';
    }
  }
}
```

---

## 🔧 Google Places API Service

### Core Service Implementation
```dart
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class PlacesService {
  final String apiKey = 'YOUR_GOOGLE_PLACES_API_KEY';
  
  // Main filtering method with parallel processing
  Future<List<Place>> getPlacesByFilters({
    required String city,
    required List<DateCategory> categories,
    required LatLng location,
    double radius = 10000,
    double? maxPrice,
  }) async {
    try {
      // Step 1: Get city geographic boundaries
      final cityBounds = await getCityBounds(city);
      if (cityBounds == null) {
        throw Exception('Could not find city boundaries');
      }

      // Step 2: Parallel API calls for each category
      final futures = categories.map((category) => _getPlacesForCategory(
        category: category, location: location, radius: radius,
        maxPrice: maxPrice, bounds: cityBounds,
      ));

      final results = await Future.wait(futures);

      // Step 3: Combine and deduplicate by place_id
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

  // City boundary detection using Geocoding API
  Future<Map<String, dynamic>?> getCityBounds(String city) async {
    try {
      final url = Uri.parse(
        'https://maps.googleapis.com/maps/api/geocode/json'
        '?address=$city&key=$apiKey',
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

  // Category-specific place retrieval
  Future<List<Place>> _getPlacesForCategory({
    required DateCategory category, required LatLng location,
    required double radius, double? maxPrice, Map<String, dynamic>? bounds,
  }) async {
    try {
      final type = _getCategoryType(category);
      final queryParams = {
        'location': '${location.latitude},${location.longitude}',
        'radius': radius.toString(), 'type': type, 'key': apiKey,
      };

      // Add geographic bounds filtering
      if (bounds != null) {
        queryParams['bounds'] = '${bounds['southwest']['lat']},${bounds['southwest']['lng']}|'
                               '${bounds['northeast']['lat']},${bounds['northeast']['lng']}';
      }

      // Add price level filtering
      if (maxPrice != null) {
        queryParams['maxprice'] = (maxPrice / 25).round().toString();
      }

      final url = Uri.https('maps.googleapis.com', '/maps/api/place/nearbysearch/json', queryParams);
      final response = await http.get(url);
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return _parsePlacesResponse(data, maxPrice ?? double.infinity);
      } else {
        throw Exception('Failed to fetch places');
      }
    } catch (e) {
      print('Error fetching places for category $category: $e');
      return [];
    }
  }

  // Category to Google Places type mapping
  String _getCategoryType(DateCategory category) {
    switch (category) {
      case DateCategory.restaurant: return 'restaurant';
      case DateCategory.cafe: return 'cafe';
      case DateCategory.bar: return 'bar';
      case DateCategory.park: return 'park';
      case DateCategory.museum: return 'museum|art_gallery';
      case DateCategory.movie: return 'movie_theater';
      case DateCategory.concert: return 'night_club';
      case DateCategory.beach: return 'natural_feature';
      case DateCategory.outdoorActivity: return 'park|hiking_trail';
      case DateCategory.sportsEvent: return 'stadium';
      case DateCategory.cookingClass: return 'restaurant|cafe';
      default: return 'tourist_attraction';
    }
  }

  // Parse Google Places API response
  List<Place> _parsePlacesResponse(Map<String, dynamic> data, double budget) {
    List<Place> places = [];
    if (data['results'] == null) return places;

    for (var result in data['results']) {
      try {
        final priceLevel = result['price_level'] ?? 2;
        final estimatedCost = priceLevel * 25.0;

        if (estimatedCost <= budget) {
          places.add(Place(
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
            openingHours: result['opening_hours']?['open_now'] == true ? 'Open' : 'Closed',
            amenities: [],
            websiteUrl: result['website'] ?? '',
            phoneNumber: result['formatted_phone_number'] ?? '',
            isActive: true,
          ));
        }
      } catch (e) {
        print('Error parsing place: $e');
        continue;
      }
    }
    return places;
  }

  // Map Google place types to readable categories
  List<String> _extractCategories(List<dynamic> types) {
    final categoryMapping = {
      'restaurant': 'Restaurant', 'cafe': 'Cafe', 'bar': 'Bar',
      'park': 'Outdoor Activity', 'museum': 'Museum', 'art_gallery': 'Museum',
      'movie_theater': 'Movie', 'night_club': 'Concert', 'stadium': 'Sports',
      'natural_feature': 'Outdoor', 'tourist_attraction': 'Tourist Spot',
    };

    return types.map((type) => categoryMapping[type.toString()] ?? type.toString())
                .where((category) => category != null).toSet().toList();
  }
}
```

---

## 🎯 Advanced Filtering System

### Multi-Criteria Filtering Logic
```dart
class FilteringLogic {
  // Geographic boundary filtering
  static bool isWithinCityBounds(Place place, Map<String, dynamic> bounds) {
    final lat = place.latitude;
    final lng = place.longitude;
    final southwest = bounds['southwest'];
    final northeast = bounds['northeast'];
    
    return lat >= southwest['lat'] && lat <= northeast['lat'] &&
           lng >= southwest['lng'] && lng <= northeast['lng'];
  }

  // Budget-based filtering
  static List<Place> filterByBudget(List<Place> places, double maxBudget) {
    return places.where((place) => place.priceRange <= maxBudget).toList();
  }

  // Category-based filtering
  static List<Place> filterByCategories(List<Place> places, List<DateCategory> categories) {
    if (categories.isEmpty) return places;
    return places.where((place) {
      return categories.any((category) => place.categories.contains(category.displayName));
    }).toList();
  }

  // Rating-based filtering
  static List<Place> filterByMinRating(List<Place> places, double minRating) {
    return places.where((place) => place.rating >= minRating).toList();
  }

  // Distance-based filtering
  static List<Place> filterByDistance(List<Place> places, LatLng userLocation, double maxDistanceKm) {
    return places.where((place) {
      final distance = Geolocator.distanceBetween(
        userLocation.latitude, userLocation.longitude,
        place.latitude, place.longitude,
      ) / 1000; // Convert to kilometers
      return distance <= maxDistanceKm;
    }).toList();
  }
}
```

---

## 🖥️ User Interface Implementation

### Main Places Screen with Filtering
```dart
class FilteredPlacesScreen extends StatefulWidget {
  @override
  _FilteredPlacesScreenState createState() => _FilteredPlacesScreenState();
}

class _FilteredPlacesScreenState extends State<FilteredPlacesScreen> {
  final PlacesService _placesService = PlacesService();
  List<Place> _places = [];
  bool _isLoading = false;
  String _error = '';
  String _selectedCity = '';
  List<DateCategory> _selectedCategories = [];
  double _maxBudget = 100.0;
  double _minRating = 0.0;
  final TextEditingController _cityController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _initializeLocation();
  }

  // GPS-based location initialization
  Future<void> _initializeLocation() async {
    try {
      final position = await Geolocator.getCurrentPosition();
      _fetchPlaces(LatLng(position.latitude, position.longitude));
    } catch (e) {
      setState(() {
        _error = 'Could not get current location. Please enter your city manually.';
      });
    }
  }

  // Main places fetching with error handling
  Future<void> _fetchPlaces(LatLng location) async {
    if (_selectedCity.isEmpty) return;

    setState(() { _isLoading = true; _error = ''; });

    try {
      final places = await _placesService.getPlacesByFilters(
        city: _selectedCity,
        categories: _selectedCategories.isEmpty ? [DateCategory.restaurant] : _selectedCategories,
        location: location,
        maxPrice: _maxBudget,
      );

      setState(() { _places = places; _isLoading = false; });
    } catch (e) {
      setState(() { _error = 'Error loading places: $e'; _isLoading = false; });
    }
  }

  // Advanced filter dialog with sliders and chips
  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: Text('Filter Places'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // City input field
                  TextField(
                    controller: _cityController,
                    decoration: InputDecoration(
                      labelText: 'City', hintText: 'Enter your city',
                      prefixIcon: Icon(Icons.location_city),
                    ),
                    onChanged: (value) => _selectedCity = value,
                  ),
                  SizedBox(height: 16),
                  
                  // Category selection chips
                  Text('Categories', style: Theme.of(context).textTheme.titleMedium),
                  Wrap(
                    spacing: 8,
                    children: DateCategory.values.map((category) {
                      final isSelected = _selectedCategories.contains(category);
                      return FilterChip(
                        label: Text(category.displayName),
                        selected: isSelected,
                        onSelected: (selected) {
                          setState(() {
                            if (selected) {
                              _selectedCategories.add(category);
                            } else {
                              _selectedCategories.remove(category);
                            }
                          });
                        },
                        avatar: isSelected ? Icon(Icons.check, size: 16) : null,
                      );
                    }).toList(),
                  ),
                  SizedBox(height: 16),
                  
                  // Budget slider
                  Text('Max Budget: \$${_maxBudget.round()}'),
                  Slider(
                    value: _maxBudget, min: 0, max: 200, divisions: 8,
                    onChanged: (value) => setState(() => _maxBudget = value),
                  ),
                  
                  // Rating slider
                  Text('Minimum Rating: ${_minRating.toStringAsFixed(1)}'),
                  Slider(
                    value: _minRating, min: 0, max: 5, divisions: 10,
                    onChanged: (value) => setState(() => _minRating = value),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: Text('Cancel')),
              ElevatedButton(
                onPressed: () { Navigator.pop(context); _applyFilters(); },
                child: Text('Apply Filters'),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Date Places'),
        actions: [IconButton(icon: Icon(Icons.filter_list), onPressed: _showFilterDialog)],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return Center(child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [CircularProgressIndicator(), SizedBox(height: 16), Text('Finding amazing places...')],
      ));
    }

    if (_error.isNotEmpty) {
      return Center(child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: Colors.grey),
          SizedBox(height: 16), Text(_error, textAlign: TextAlign.center),
          SizedBox(height: 16), ElevatedButton(onPressed: _initializeLocation, child: Text('Retry')),
        ],
      ));
    }

    if (_places.isEmpty) {
      return Center(child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off, size: 64, color: Colors.grey),
          SizedBox(height: 16), Text('No places found'), Text('Try adjusting your filters'),
          SizedBox(height: 16), ElevatedButton(onPressed: _showFilterDialog, child: Text('Change Filters')),
        ],
      ));
    }

    return ListView.builder(
      padding: EdgeInsets.all(16),
      itemCount: _places.length,
      itemBuilder: (context, index) {
        final place = _places[index];
        return PlaceCard(place: place, onTap: () => _navigateToPlaceDetails(place));
      },
    );
  }
}
```

---

## 🔑 Setup & Configuration

### 1. Google Cloud Console Setup
```bash
# Required APIs to enable:
- Places API (New)
- Geocoding API
- Maps SDK for Android
- Maps SDK for iOS
```

### 2. Dependencies (pubspec.yaml)
```yaml
dependencies:
  flutter: {sdk: flutter}
  http: ^0.13.5                    # HTTP requests
  google_maps_flutter: ^2.2.3     # Maps integration
  geolocator: ^9.0.2              # GPS location
  geocoding: ^2.0.5               # Address conversion
  flutter_dotenv: ^5.0.2          # Environment variables
```

### 3. Platform Permissions

#### Android (AndroidManifest.xml)
```xml
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
<uses-permission android:name="android.permission.INTERNET" />

<application>
    <meta-data android:name="com.google.android.geo.API_KEY" android:value="YOUR_API_KEY_HERE" />
</application>
```

#### iOS (Info.plist)
```xml
<key>NSLocationWhenInUseUsageDescription</key>
<string>This app needs location access to find nearby places.</string>
<key>NSLocationAlwaysAndWhenInUseUsageDescription</key>
<string>This app needs location access to find nearby places.</string>
```

---

## 🎯 Key Implementation Features

### ✅ **Real-time Google Places Integration**
- Live data from Google's comprehensive database
- Automatic city boundary detection
- Parallel processing for multiple categories
- Smart deduplication by place_id

### ✅ **Advanced Multi-Criteria Filtering**
- **Geographic**: City boundaries + radius filtering
- **Category**: 11 predefined categories with multiple selection
- **Budget**: Price level filtering (0-200 scale)
- **Rating**: Minimum rating requirements (0-5 stars)
- **Distance**: Proximity-based filtering

### ✅ **Intelligent User Interface**
- Modern Material Design components
- Interactive filter chips and sliders
- Comprehensive loading states
- Detailed error handling and retry mechanisms

### ✅ **Performance Optimizations**
- Efficient parallel API calls
- Result deduplication
- Memory-conscious data handling
- Graceful error recovery

---

## 🔧 Customization for Travel Apps

### Travel-Specific Categories
```dart
enum TravelCategory {
  restaurant, hotel, attraction, museum, park, shopping,
  nightlife, transportation, hospital, bank, touristInfo,
}

extension TravelCategoryExtension on TravelCategory {
  String get googlePlaceType {
    switch (this) {
      case TravelCategory.restaurant: return 'restaurant';
      case TravelCategory.hotel: return 'lodging';
      case TravelCategory.attraction: return 'tourist_attraction';
      case TravelCategory.museum: return 'museum';
      case TravelCategory.park: return 'park';
      case TravelCategory.shopping: return 'shopping_mall';
      case TravelCategory.nightlife: return 'night_club|bar';
      case TravelCategory.transportation: return 'transit_station';
      case TravelCategory.hospital: return 'hospital';
      case TravelCategory.bank: return 'bank|atm';
      case TravelCategory.touristInfo: return 'travel_agency';
    }
  }
}
```

---

## 🎉 Implementation Summary

This comprehensive guide provides a production-ready places listing system with:

- **Real-time Google Places API integration** with parallel processing
- **Advanced filtering system** supporting multiple criteria
- **Intelligent recommendation algorithms** based on user preferences
- **Responsive UI components** with modern design patterns
- **Performance optimizations** for smooth user experience
- **Easy customization** for different app types (travel, dating, events)

### Perfect For:
- 🏨 Travel and tourism applications
- 💕 Dating and social discovery apps
- 🍽️ Restaurant and dining platforms
- 🎯 Event and activity discovery
- 🗺️ Any location-based service

The modular architecture allows easy adaptation while maintaining core functionality and performance benefits. 