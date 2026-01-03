// services/location_services.dart
// Location services for handling geolocation

import 'dart:math'; // Import for mathematical constants
import 'package:location/location.dart' as loc; // Use 'loc' as an alias
import 'package:geocoding/geocoding.dart' as geocoding;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geofence_service_in_app/geofence_service_in_app.dart'; // Ensure this package is correctly imported
import 'package:permission_handler/permission_handler.dart'
    as ph; // Use 'ph' as an alias

class LocationService {
  final loc.Location _location = loc.Location();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get user's current location
  Future<loc.LocationData?> getCurrentLocation() async {
    bool serviceEnabled;
    loc.PermissionStatus
    permissionGranted; // Use loc.PermissionStatus instead of ph.PermissionStatus

    // Check if location service is enabled
    serviceEnabled = await _location.serviceEnabled();
    if (!serviceEnabled) {
      serviceEnabled = await _location.requestService();
      if (!serviceEnabled) {
        return null;
      }
    }

    // Check if permission is granted
    permissionGranted = await _location.hasPermission();
    if (permissionGranted == loc.PermissionStatus.denied) {
      // Use loc.PermissionStatus
      permissionGranted = await _location.requestPermission();
      if (permissionGranted != loc.PermissionStatus.granted) {
        // Use loc.PermissionStatus
        return null;
      }
    }

    // Get location
    return await _location.getLocation();
  }

  // Convert address to coordinates
  Future<List<geocoding.Location>> getCoordinatesFromAddress(
    String address,
  ) async {
    try {
      List<geocoding.Location> locations = await geocoding.locationFromAddress(
        address,
      );
      return locations;
    } catch (e) {
      rethrow;
    }
  }

  // Convert coordinates to address
  Future<List<geocoding.Placemark>> getAddressFromCoordinates(
    double latitude,
    double longitude,
  ) async {
    try {
      List<geocoding.Placemark> placemarks = await geocoding
          .placemarkFromCoordinates(latitude, longitude);
      return placemarks;
    } catch (e) {
      rethrow;
    }
  }

  // Create GeoPoint for Firestore
  GeoPoint createGeoPoint(double latitude, double longitude) {
    return GeoPoint(latitude, longitude);
  }

  // Find nearby providers
  Stream<List<DocumentSnapshot>> getNearbyProviders(
    double latitude,
    double longitude,
    double radius, // in kilometers
  ) {
    final CollectionReference providers = _firestore.collection('providers');

    // Convert radius to degrees (approximate)
    final double radiusInDegrees = radius / 111.32;

    return providers
        .where('latitude', isGreaterThanOrEqualTo: latitude - radiusInDegrees)
        .where('latitude', isLessThanOrEqualTo: latitude + radiusInDegrees)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.where((doc) {
            // Further filter by longitude and exact distance
            final providerLat = doc.get('latitude') as double;
            final providerLng = doc.get('longitude') as double;
            final distance = calculateDistance(
              latitude,
              longitude,
              providerLat,
              providerLng,
            );
            return distance <= radius;
          }).toList();
        });
  }

  // Find nearby services (similar modification as getNearbyProviders)
  Stream<List<DocumentSnapshot>> getNearbyServices(
    double latitude,
    double longitude,
    double radius,
  ) {
    final CollectionReference providerServices = _firestore.collection(
      'provider_services',
    );

    final double radiusInDegrees = radius / 111.32;

    return providerServices
        .where('latitude', isGreaterThanOrEqualTo: latitude - radiusInDegrees)
        .where('latitude', isLessThanOrEqualTo: latitude + radiusInDegrees)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.where((doc) {
            final serviceLat = doc.get('latitude') as double;
            final serviceLng = doc.get('longitude') as double;
            final distance = calculateDistance(
              latitude,
              longitude,
              serviceLat,
              serviceLng,
            );
            return distance <= radius;
          }).toList();
        });
  }

  // Update provider location
  Future<void> updateProviderLocation(
    String providerId,
    double latitude,
    double longitude,
  ) async {
    try {
      final DocumentReference providerRef = _firestore
          .collection('providers')
          .doc(providerId);

      await providerRef.update({
        'latitude': latitude,
        'longitude': longitude,
        'position': GeoPoint(latitude, longitude),
        'lastLocationUpdate': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      rethrow;
    }
  }

  // Calculate distance between two points (in kilometers)
  double calculateDistance(
    double startLatitude,
    double startLongitude,
    double endLatitude,
    double endLongitude,
  ) {
    const double earthRadius = 6371; // Earth's radius in kilometers

    // Convert degrees to radians
    final double lat1 = startLatitude * (pi / 180);
    final double lon1 = startLongitude * (pi / 180);
    final double lat2 = endLatitude * (pi / 180);
    final double lon2 = endLongitude * (pi / 180);

    // Haversine formula
    final double dLat = lat2 - lat1;
    final double dLon = lon2 - lon1;
    final double a =
        sin(dLat / 2) * sin(dLat / 2) +
        cos(lat1) * cos(lat2) * sin(dLon / 2) * sin(dLon / 2);
    final double c = 2 * atan2(sqrt(a), sqrt(1 - a));

    return earthRadius * c;
  }

  // Start location tracking
  Stream<loc.LocationData> trackLocation() {
    _location.enableBackgroundMode(enable: true);
    _location.changeSettings(interval: 10000); // Update every 10 seconds
    return _location.onLocationChanged;
  }

  // Stop location tracking
  Future<void> stopLocationTracking() async {
    await _location.enableBackgroundMode(enable: false);
  }

  // Optional factory method to get GeofenceService when actually needed
  GeofenceService? getGeofenceService() {
    try {
      // Return the GeofenceService with whatever constructor is available
      // You'll need to check the package documentation for the correct syntax
      return null; // Replace with actual implementation when known
    } catch (e) {
      print('Error initializing GeofenceService: $e');
      return null;
    }
  }
}
