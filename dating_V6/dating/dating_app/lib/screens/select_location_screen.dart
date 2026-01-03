import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import '../services/place_search_service.dart';
import '../models/place.dart';
import 'dart:async';
import 'dart:math' show sqrt;

class SelectLocationScreen extends StatefulWidget {
  @override
  _SelectLocationScreenState createState() => _SelectLocationScreenState();
}

class _SelectLocationScreenState extends State<SelectLocationScreen> {
  final Completer<GoogleMapController> _controller = Completer();
  final PlaceSearchService _placeSearchService = PlaceSearchService();

  LatLng? _selectedLocation;
  Place? _selectedPlace;
  List<Place> _nearbyPlaces = [];
  bool _isLoading = false;
  Set<Marker> _markers = {};
  TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _getCurrentLocation() async {
    setState(() => _isLoading = true);
    try {
      final position = await Geolocator.getCurrentPosition();
      final latLng = LatLng(position.latitude, position.longitude);

      final controller = await _controller.future;
      controller.animateCamera(CameraUpdate.newLatLngZoom(latLng, 15));

      // Load nearby places
      await _loadNearbyPlaces(latLng);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error getting location: $e')));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadNearbyPlaces(LatLng location) async {
    try {
      final places = await _placeSearchService.searchNearbyPlaces(
        location.latitude,
        location.longitude,
        radius: 1000, // 1km radius
      );

      setState(() {
        _nearbyPlaces = places;

        // Create markers for each place
        _markers =
            places.map((place) {
              return Marker(
                markerId: MarkerId(place.id),
                position: LatLng(place.latitude, place.longitude),
                infoWindow: InfoWindow(
                  title: place.name,
                  snippet: place.address,
                  onTap: () {
                    _selectPlace(place);
                  },
                ),
                onTap: () {
                  _selectPlace(place);
                },
              );
            }).toSet();
      });
    } catch (e) {
      print('Error loading nearby places: $e');
    }
  }

  void _selectPlace(Place place) {
    setState(() {
      _selectedPlace = place;
      _selectedLocation = LatLng(place.latitude, place.longitude);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Select Location'),
        actions: [
          if (_selectedPlace != null)
            TextButton(
              onPressed: () {
                Navigator.pop(context, _selectedPlace);
              },
              child: Text('SELECT', style: TextStyle(color: Colors.white)),
            ),
        ],
      ),
      body: Stack(
        children: [
          // Map
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: _selectedLocation ?? LatLng(0, 0),
              zoom: 15,
            ),
            onMapCreated: (controller) {
              _controller.complete(controller);
            },
            markers: _markers,
            myLocationEnabled: true,
            myLocationButtonEnabled: true,
            onTap: (latLng) async {
              // When tapping on the map, find the nearest place
              await _handleMapTap(latLng);
            },
          ),

          // Search bar at top
          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search for places',
                  prefixIcon: Icon(Icons.search),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                ),
                onSubmitted: (query) {
                  _searchPlaces(query);
                },
              ),
            ),
          ),

          // Selected place info at bottom
          if (_selectedPlace != null)
            Positioned(
              bottom: 16,
              left: 16,
              right: 16,
              child: Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 4,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _selectedPlace!.name,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(_selectedPlace!.address),
                    SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context, _selectedPlace);
                      },
                      child: Text('Select This Place'),
                      style: ElevatedButton.styleFrom(
                        minimumSize: Size(double.infinity, 40),
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Loading indicator
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.3),
              child: Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }

  Future<void> _searchPlaces(String query) async {
    if (query.isEmpty) return;

    setState(() => _isLoading = true);
    try {
      final places = await _placeSearchService.searchPlaces(query);

      if (places.isNotEmpty) {
        final place = places.first;
        final latLng = LatLng(place.latitude, place.longitude);

        final controller = await _controller.future;
        controller.animateCamera(CameraUpdate.newLatLngZoom(latLng, 15));

        await _loadNearbyPlaces(latLng);
        _selectPlace(place);
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error searching places: $e')));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _handleMapTap(LatLng latLng) async {
    setState(() => _isLoading = true);

    try {
      // First check if we tapped near an existing place
      Place? nearestPlace;
      double nearestDistance = double.infinity;

      for (final place in _nearbyPlaces) {
        final placeLatLng = LatLng(place.latitude, place.longitude);
        final distance = _calculateDistance(latLng, placeLatLng);

        // If within 50 meters, consider it a tap on this place
        if (distance < 50 && distance < nearestDistance) {
          nearestPlace = place;
          nearestDistance = distance;
        }
      }

      if (nearestPlace != null) {
        _selectPlace(nearestPlace);
      } else {
        // If no nearby place, search for places at this location
        final places = await _placeSearchService.searchNearbyPlaces(
          latLng.latitude,
          latLng.longitude,
          radius: 100, // Very small radius to get exact location
        );

        if (places.isNotEmpty) {
          _selectPlace(places.first);
        } else {
          // If still no places found, create a custom place from geocoding
          final placemarks = await placemarkFromCoordinates(
            latLng.latitude,
            latLng.longitude,
          );

          if (placemarks.isNotEmpty) {
            final placemark = placemarks.first;
            final address = [
              placemark.name,
              placemark.street,
              placemark.locality,
              placemark.administrativeArea,
            ].where((e) => e != null && e.isNotEmpty).join(', ');

            final customPlace = Place(
              id: 'custom-${DateTime.now().millisecondsSinceEpoch}',
              name: placemark.name ?? 'Selected Location',
              address: address,
              latitude: latLng.latitude,
              longitude: latLng.longitude,
              rating: 0,
              categories: [],
              description: address,
              moods: [],
              priceRange: 0.0,
              openingHours: '',
              amenities: [],
            );

            _selectPlace(customPlace);
          }
        }
      }
    } catch (e) {
      print('Error handling map tap: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  double _calculateDistance(LatLng point1, LatLng point2) {
    // Simple Euclidean distance for quick calculation (not accurate for long distances)
    final dx = point1.latitude - point2.latitude;
    final dy = point1.longitude - point2.longitude;
    return 111000 * sqrt(dx * dx + dy * dy); // Rough conversion to meters
  }
}
