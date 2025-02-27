import 'package:flutter/material.dart';
import 'package:location/location.dart';
import 'package:rxdart/subjects.dart';

class TripProvider extends ChangeNotifier {
  final Location _location = Location();
  final BehaviorSubject<LocationData> _locationStreamController = BehaviorSubject<LocationData>();
  LocationData? _lastLocation;
  bool _isTripStarted = false;

  Stream<LocationData> get locationStream => _locationStreamController.stream;
  bool get isTripStarted => _isTripStarted;

  TripProvider() {
    _checkPermissions();
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

  void toggleTrip() {
    _isTripStarted = !_isTripStarted;
    notifyListeners();

    if (_isTripStarted) {
      _location.onLocationChanged.listen((LocationData locationData) {
        _locationStreamController.add(locationData);
      });
    } else {
      _locationStreamController.add(_lastLocation!); // Stop updates
    }
  }

  @override
  void dispose() {
    _locationStreamController.close();
    super.dispose();
  }
}