import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class MapWidget extends StatefulWidget {
  @override
  _MapWidgetState createState() => _MapWidgetState();
}

class _MapWidgetState extends State<MapWidget> {
  late GoogleMapController mapController;

  final LatLng _center = const LatLng(4.7110, -74.0721); // Bogotá

  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 300,
      child: GoogleMap(
        onMapCreated: _onMapCreated,
        initialCameraPosition: CameraPosition(
          target: _center,
          zoom: 11.0,
        ),
        markers: {
          const Marker(
            markerId: const MarkerId("Sydney"),
            position: LatLng(4.7110, -74.0721),
            infoWindow: InfoWindow(
               title: "bogota",
               snippet: "Capital of New South Wales",
            ), 
          ), // Marker
        }, // markers
      ),
    );
  }
}