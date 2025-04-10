import 'dart:async';
import 'dart:io' show Platform; // Import for platform checks
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_animated_marker/flutter_map_animated_marker.dart';
import 'package:geodesy/geodesy.dart' as geodesy;
import 'package:latlong2/latlong.dart';
import 'package:location/location.dart';
import 'package:rxdart/subjects.dart';
import 'package:flutter_map_cancellable_tile_provider/flutter_map_cancellable_tile_provider.dart';

class SuiviBusPage extends StatefulWidget {
  
  const SuiviBusPage({super.key}); // Modification du constructeur

  @override
  SuiviBusPageState createState() => SuiviBusPageState();
}

class SuiviBusPageState extends State<SuiviBusPage> with TickerProviderStateMixin {
  String? currentUserId; // ID de l'utilisateur actuel
  String? busMatricule; // Variable to store the bus matricule
  final Location _location = Location();
  final MapController _mapController = MapController();
  final BehaviorSubject<LocationData> _locationStreamController = BehaviorSubject();
  final geodesy.Geodesy _geodesy = geodesy.Geodesy();

  LocationData? _lastLocation;
  double _distance = 0.0;
  int _duration = 0;
  bool _isTripStarted = false;
  late CollectionReference busPositionCollection; // Référence à la sous-collection Firestore

  @override
  void initState() {
    super.initState();
    _initialize();
    _checkPermissions();
    _listenToLocationUpdates();
  }

  Future<void> _initialize() async {
    await _getCurrentUserId();
    await _getBusMatricule();
    _initializeBusPositionCollection();
    _startRealtimePositionUpdates();
  }

  void _initializeBusPositionCollection() {
    if (currentUserId != null && busMatricule != null) {
      busPositionCollection = FirebaseFirestore.instance
          .collection('Conducteurs')
          .doc(currentUserId)
          .collection('Bus');
    }
  }

  Future<void> _getCurrentUserId() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      String uid = user.uid;
      QuerySnapshot userSnapshot = await FirebaseFirestore.instance
          .collection('Users')
          .where('uid', isEqualTo: uid)
          .limit(1)
          .get();

      if (userSnapshot.docs.isNotEmpty) {
        setState(() {
          currentUserId = userSnapshot.docs.first.id;
        });
      }
    }
  }

  Future<void> _getBusMatricule() async {
    if (currentUserId == null) return;

    DocumentSnapshot driverDoc = await FirebaseFirestore.instance
        .collection('Conducteurs')
        .doc(currentUserId)
        .get();

    if (driverDoc.exists) {
      setState(() {
        busMatricule = driverDoc['matricule_bus'];
      });
    }
  }

  Future<void> _checkPermissions() async {
    if (Platform.isAndroid || Platform.isIOS || Platform.isWindows) {
      // Only check permissions on supported platforms
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
    } else {
      print("Permissions check skipped for web.");
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

      _mapController.move(
        LatLng(locationData.latitude ?? 0, locationData.longitude ?? 0),
        _mapController.camera.zoom,
      );
    });
  }

  void _startRealtimePositionUpdates() async {
    _location.onLocationChanged.listen((LocationData locationData) async {
      if (locationData.latitude != null && locationData.longitude != null && busMatricule != null) {
        try {
          // Update the 'bus_position' document in the 'Conducteurs' collection
          await busPositionCollection.doc('bus_position').set({
            'matricule': busMatricule,
            'latitude': locationData.latitude,
            'longitude': locationData.longitude,
            'heading': locationData.heading,
            'speed': locationData.speed,
            'timestamp': FieldValue.serverTimestamp(),
            'actif': _isTripStarted,
          }, SetOptions(merge: true));

          // Update the document in the 'Bus' collection identified by its matricule
          await FirebaseFirestore.instance.collection('Bus').doc(busMatricule).set({
            'latitude': locationData.latitude,
            'longitude': locationData.longitude,
            'heading': locationData.heading,
            'speed': locationData.speed,
            'timestamp': FieldValue.serverTimestamp(),
            'actif': _isTripStarted, // État du trajet
          }, SetOptions(merge: true));
        } catch (error) {
          print("Erreur lors de la mise à jour de la position : $error");
        }
      }
    });
  }

  void _toggleTrip() async {
    setState(() {
      _isTripStarted = !_isTripStarted;
    });

    if (busMatricule != null) {
      try {
        // Update the 'actif' field in both 'bus_position' and 'Bus' collections
        await busPositionCollection.doc('bus_position').set({
          'actif': _isTripStarted,
        }, SetOptions(merge: true));

        await FirebaseFirestore.instance.collection('Bus').doc(busMatricule).set({
          'actif': _isTripStarted,
        }, SetOptions(merge: true));
      } catch (error) {
        print("Erreur lors de la mise à jour de l'état du bus : $error");
      }
    }

    if (_isTripStarted) {
      _location.onLocationChanged.listen((LocationData locationData) {
        _locationStreamController.add(locationData);
      });
    } else {
      _locationStreamController.add(_lastLocation!);
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
                    urlTemplate: "https://a.tile.openstreetmap.org/{z}/{x}/{y}.png", // Updated URL
                    tileProvider: CancellableNetworkTileProvider(),
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