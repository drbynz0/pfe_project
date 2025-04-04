import 'dart:async';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_animated_marker/flutter_map_animated_marker.dart';
import 'package:geodesy/geodesy.dart' as geodesy;
import 'package:latlong2/latlong.dart';
import 'package:location/location.dart';
import 'package:rxdart/subjects.dart';
import 'package:flutter_map_cancellable_tile_provider/flutter_map_cancellable_tile_provider.dart'; // Importation du package

class SuiviBusPage extends StatefulWidget {
  const SuiviBusPage({super.key});

  @override
  SuiviBusPageState createState() => SuiviBusPageState();
}

class SuiviBusPageState extends State<SuiviBusPage> with TickerProviderStateMixin {
  final Location _location = Location();
  final MapController _mapController = MapController();
  final BehaviorSubject<LocationData> _locationStreamController = BehaviorSubject();
  final geodesy.Geodesy _geodesy = geodesy.Geodesy();

  LocationData? _lastLocation;
  double _distance = 0.0;
  int _duration = 0;
  bool _isTripStarted = false;

  @override
  void initState() {
    super.initState();
    _checkPermissions();
    _listenToLocationUpdates();
    _sendBusPosition();
  }

  Future<void> _checkPermissions() async {
    bool serviceEnabled = await _location.serviceEnabled();
    if (!serviceEnabled) {
      serviceEnabled = await _location.requestService();
      if (!serviceEnabled) return;
    }

    PermissionStatus permissionGranted = await _location.hasPermission();
    if (permissionGranted == PermissionStatus.denied) {
      permissionGranted = await _location.requestPermission();
      if (permissionGranted != PermissionStatus.granted) return;
    }
  }

  void _listenToLocationUpdates() {
    _locationStreamController.stream.listen((LocationData locationData) {
      if (_lastLocation != null) {
        _duration = ((locationData.time ?? 0) - (_lastLocation!.time ?? 0)).toInt();
        _distance = _geodesy.distanceBetweenTwoGeoPoints(
          geodesy.LatLng(locationData.latitude ?? 0, locationData.longitude ?? 0),
          geodesy.LatLng(_lastLocation!.latitude ?? 0, _lastLocation!.longitude ?? 0),
        ).toDouble();
      }
      _lastLocation = locationData;

      // Déplacer la carte vers la nouvelle position
      _mapController.move(
        LatLng(locationData.latitude ?? 0, locationData.longitude ?? 0),
        _mapController.camera.zoom,
      );
    });
  }

  void _sendBusPosition() async {

    FirebaseDatabase.instanceFor(
      app: Firebase.app(),
      databaseURL: "https://console.firebase.google.com/u/1/project/pfe-project-61a90/database/pfe-project-61a90-default-rtdb/data/~2F", // 🔥 Mets ton URL ici
    );
    DatabaseReference busPositionRef = FirebaseDatabase.instance.ref("bus_position");

    Geolocator.getPositionStream().listen((Position position) {
      print("Position envoyée : ${position.latitude}, ${position.longitude}");
      
      busPositionRef.update({
        'latitude': position.latitude,
        'longitude': position.longitude,
        'timestamp': DateTime.now().millisecondsSinceEpoch, // Ajout d'un timestamp
      });
    });
  }

  void _toggleTrip() {
    setState(() {
      _isTripStarted = !_isTripStarted;
    });

    if (_isTripStarted) {
      _location.onLocationChanged.listen((LocationData locationData) {
        _locationStreamController.add(locationData);
      });
    } else {
      _locationStreamController.add(_lastLocation!); // Arrêter les mises à jour
    }
  }

  @override
  void dispose() {
    _locationStreamController.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Suivi du Bus'),
        backgroundColor: Colors.blue,
      ),
      body: StreamBuilder<LocationData>(
        stream: _locationStreamController.stream,
        builder: (context, snapshot) {
          final locationData = snapshot.data;
          final nextSimulatedLocation = _geodesy.destinationPointByDistanceAndBearing(
            geodesy.LatLng(
              locationData?.latitude ?? 0.0,
              locationData?.longitude ?? 0.0,
            ),
            _distance,
            locationData?.heading ?? 0.0,
          );

          return Stack(
            children: [
              FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: LatLng(locationData?.latitude ?? 37.7749, locationData?.longitude ?? -122.4194),
                  initialZoom: 16.0,
                ),
                children: [
                  TileLayer(
                    urlTemplate: "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
                    tileProvider: CancellableNetworkTileProvider(), // Utilisation de CancellableTileProvider
                  ),
                  if (locationData != null)
                    AnimatedMarkerLayer(
                      options: AnimatedMarkerLayerOptions(
                        duration: Duration(milliseconds: _duration),
                        marker: Marker(
                          width: 40,
                          height: 40,
                          point: LatLng(
                            nextSimulatedLocation.latitude,
                            nextSimulatedLocation.longitude,
                          ),
                          child: Transform.rotate(
                            angle: (locationData.heading ?? 0) * pi / 180,
                            child: const Icon(
                              Icons.directions_bus,
                              color: Colors.red,
                              size: 40,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              Positioned(
                bottom: 20,
                left: 20,
                right: 20,
                child: ElevatedButton(
                  onPressed: _toggleTrip,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isTripStarted ? Colors.red : Colors.green,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                  ),
                  child: Text(_isTripStarted ? "Arrêter le trajet" : "Démarrer le trajet"),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}