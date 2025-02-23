
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';
import 'package:firebase_core/firebase_core.dart';

class SuiviBusPage extends StatefulWidget {
  const SuiviBusPage({super.key});

  @override
  _SuiviBusPageState createState() => _SuiviBusPageState();
}

class _SuiviBusPageState extends State<SuiviBusPage> {
  GoogleMapController? _mapController;
  Location _location = Location();
  LatLng _busPosition = const LatLng(37.7749, -122.4194); // Position initiale fictive
  bool _isTripStarted = false;

  void _getCurrentLocation() async {
    var currentLocation = await _location.getLocation();
    setState(() {
      _busPosition = LatLng(currentLocation.latitude!, currentLocation.longitude!);
    });
  }

  void _startTrip() {
    setState(() {
      _isTripStarted = !_isTripStarted;
    });
    if (_isTripStarted) {
      _getCurrentLocation();
      _location.onLocationChanged.listen((LocationData locationData) {
        setState(() {
          _busPosition = LatLng(locationData.latitude!, locationData.longitude!);
        });
        _mapController?.animateCamera(CameraUpdate.newLatLng(_busPosition));
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Suivi du Bus'),
        backgroundColor: Colors.blue,
      ),
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: _busPosition,
              zoom: 14.0,
            ),
            markers: {
              Marker(
                markerId: const MarkerId("bus"),
                position: _busPosition,
                infoWindow: const InfoWindow(title: "Bus Scolaire"),
              ),
            },
            onMapCreated: (GoogleMapController controller) {
              _mapController = controller;
            },
          ),
          Positioned(
            bottom: 20,
            left: 20,
            right: 20,
            child: ElevatedButton(
              onPressed: _startTrip,
              style: ElevatedButton.styleFrom(
                backgroundColor: _isTripStarted ? Colors.red : Colors.green,
                padding: const EdgeInsets.symmetric(vertical: 15),
              ),
              child: Text(_isTripStarted ? "Arrêter le trajet" : "Démarrer le trajet"),
            ),
          ),
        ],
      ),
    );
  }
}
