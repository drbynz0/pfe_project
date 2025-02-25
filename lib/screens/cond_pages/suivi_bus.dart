import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:location/location.dart';

class SuiviBusPage extends StatefulWidget {
  const SuiviBusPage({super.key});

  @override
  SuiviBusPageState createState() => SuiviBusPageState();
}

class SuiviBusPageState extends State<SuiviBusPage> {
  final Location _location = Location();
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
          FlutterMap(
            mapController: MapController(), // Ajout du contrôleur
            options: const MapOptions(),
            children: [
              TileLayer(
                urlTemplate: "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
                subdomains: ['a', 'b', 'c'],
              ),
              MarkerLayer(
                markers: [
                  Marker(
                    point: _busPosition,
                    width: 80.0,
                    height: 80.0,
                    alignment: Alignment.center, // Ajouté pour éviter les erreurs
                    rotate: true, // Indispensable dans Flutter Map 8.0.0
                    child: const Icon(
                      Icons.directions_bus,
                      color: Colors.red,
                      size: 40,
                    ),
                  ),
                ],
              ),
            ],
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
