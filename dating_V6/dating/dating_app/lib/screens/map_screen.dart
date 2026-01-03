import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class MapScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final args =
        ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
    final latitude = args['latitude'] as double;
    final longitude = args['longitude'] as double;
    final name = args['name'] as String;

    return Scaffold(
      appBar: AppBar(title: Text(name)),
      body: GoogleMap(
        initialCameraPosition: CameraPosition(
          target: LatLng(latitude, longitude),
          zoom: 15,
        ),
        markers: {
          Marker(
            markerId: MarkerId('place'),
            position: LatLng(latitude, longitude),
            infoWindow: InfoWindow(title: name),
          ),
        },
      ),
    );
  }
}
