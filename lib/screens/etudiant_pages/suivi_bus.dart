import 'dart:async';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_animated_marker/flutter_map_animated_marker.dart';
import 'package:flutter_map_cancellable_tile_provider/flutter_map_cancellable_tile_provider.dart';
import 'package:latlong2/latlong.dart';

class SuiviBusPage extends StatefulWidget {
  const SuiviBusPage({super.key});

  @override
  State<SuiviBusPage> createState() => _SuiviBusPageState();
}

class _SuiviBusPageState extends State<SuiviBusPage> {
  final MapController _mapController = MapController();
  final StreamController<List<LatLng>> _busPositions = StreamController<List<LatLng>>.broadcast();

  int index = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _listenToBusPosition();
  }

  void _listenToBusPosition() {
    DatabaseReference busPositionRef = FirebaseDatabase.instanceFor(
      app: Firebase.app(),
      databaseURL: "https://pfe-project-61a90-default-rtdb.europe-west1.firebasedatabase.app.firebaseio.com",
    ).ref("bus_position");

    busPositionRef.onValue.listen((DatabaseEvent event) {
      final data = event.snapshot.value as Map<dynamic, dynamic>?;
      if (data != null) {
        double latitude = data['latitude'];
        double longitude = data['longitude'];

        LatLng newPosition = LatLng(latitude, longitude);
        _busPositions.add([newPosition]);

        // Déplacer la carte vers la nouvelle position
        _mapController.move(newPosition, _mapController.camera.zoom);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _busPositions.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Suivi des Bus'),
        backgroundColor: Colors.indigo[900],
      ),
      body: Stack(
        children: [
          /// ---- 🗺 **Carte de suivi** ----
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: LatLng(34.020, -6.840),
              initialZoom: 14,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                tileProvider: CancellableNetworkTileProvider(),
              ),
              StreamBuilder<List<LatLng>>(
                stream: _busPositions.stream,
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return const SizedBox();
                  return AnimatedMarkerLayer(
                    options: AnimatedMarkerLayerOptions(
                      marker: Marker(
                        width: 40,
                        height: 40,
                        point: snapshot.data!.first,
                        child: Transform.rotate(
                          angle: 0,
                          child: const Icon(
                            Icons.directions_bus,
                            color: Colors.red,
                            size: 40,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),

          /// ---- 🔍 **Champ de recherche** ----
          Positioned(
            top: 10,
            left: 10,
            right: 10,
            child: TextField(
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.white,
                hintText: "Rechercher un bus...",
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ),

      /// ---- 🎛 **Bouton flottant pour afficher la modal bottom sheet** ----
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Affichage du showModalBottomSheet
          showModalBottomSheet(
            context: context,
            builder: (BuildContext context) {
              return Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Bus en service",
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const Divider(),
                    _buildBusInfo("Bus #1", "Route: Campus - Centre ville", Colors.green, "En route"),
                    _buildBusInfo("Bus #2", "Route: Campus - Résidence", Colors.orange, "5 min"),
                    _buildBusInfo("Bus #3", "Route: Campus - Bibliothèque", Colors.red, "Arrêté"),
                  ],
                ),
              );
            },
          );
        },
        backgroundColor: Colors.indigo[900],
        child: const Icon(Icons.list, color: Colors.white),
      ),
    );
  }

  /// ---- 🚌 Widget pour afficher un Bus ----
  Widget _buildBusInfo(String title, String route, Color color, String status) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          const Icon(Icons.directions_bus, color: Colors.blue),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
                Text(route, style: TextStyle(color: Colors.grey[700])),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            // ignore: deprecated_member_use
            decoration: BoxDecoration(color: color.withOpacity(0.2), borderRadius: BorderRadius.circular(8)),
            child: Text(status, style: TextStyle(color: color, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
