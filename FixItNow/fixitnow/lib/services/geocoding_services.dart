// services/geocoding_services.dart
// Service for handling geocoding operations

import 'package:geocoding/geocoding.dart' as geocoding;

class GeocodingService {
  // Format address from placemark
  String formatAddress(geocoding.Placemark placemark) {
    final components = [
      placemark.street,
      placemark.locality,
      placemark.subAdministrativeArea,
      placemark.administrativeArea,
      placemark.postalCode,
      placemark.country,
    ];

    // Filter out empty components and join with commas
    return components
        .where((component) => component != null && component.isNotEmpty)
        .join(', ');
  }
}
