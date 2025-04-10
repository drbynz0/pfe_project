import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_cancellable_tile_provider/flutter_map_cancellable_tile_provider.dart';
import 'package:latlong2/latlong.dart';

class SuiviBusPage extends StatefulWidget {
  const SuiviBusPage({super.key});

  @override
  State<SuiviBusPage> createState() => _SuiviBusPageState();
}

class _SuiviBusPageState extends State<SuiviBusPage> {
  final MapController _mapController = MapController();
  final StreamController<Map<String, LatLng>> _busPositions = 
      StreamController<Map<String, LatLng>>.broadcast();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  late StreamSubscription<QuerySnapshot> _busesSubscription;
  final List<Map<String, dynamic>> _allBuses = [];

  @override
  void initState() {
    super.initState();
    _listenToActiveBuses();
    _loadAllBuses();
  }

  void _listenToActiveBuses() {
    _firestore.collection('Bus')
      .where('actif', isEqualTo: true)
      .snapshots()
      .listen((QuerySnapshot snapshot) {
        final Map<String, LatLng> activeBusPositions = {};
        
        for (var doc in snapshot.docs) {
          final data = doc.data() as Map<String, dynamic>;
          if (data['position'] != null) {
            final GeoPoint geoPoint = data['position'] as GeoPoint;
            activeBusPositions[doc.id] = LatLng(geoPoint.latitude, geoPoint.longitude);
          }
        }
        
        _busPositions.add(activeBusPositions);
      });
  }

  void _loadAllBuses() {
    _busesSubscription = _firestore.collection('Bus').snapshots().listen((snapshot) {
      _allBuses.clear();
      for (var doc in snapshot.docs) {
        _allBuses.add({
          'id': doc.id,
          ...doc.data()
        });
      }
    });
  }

  void _handleBusTap(String busId, BuildContext context) {
    final bus = _allBuses.firstWhere((bus) => bus['id'] == busId);
    
    if (bus['actif'] == true) {
      final GeoPoint geoPoint = bus['position'];
      _mapController.move(
        LatLng(geoPoint.latitude, geoPoint.longitude),
        _mapController.camera.zoom,
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Le bus $busId est actuellement arrêté'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  void dispose() {
    _busPositions.close();
    _busesSubscription.cancel();
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
              StreamBuilder<Map<String, LatLng>>(
                stream: _busPositions.stream,
                builder: (context, snapshot) {
                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const SizedBox();
                  }
                  
                  return MarkerLayer(
                    markers: snapshot.data!.entries.map((entry) {
                      return Marker(
                        width: 40,
                        height: 40,
                        point: entry.value,
                        child: GestureDetector(
                          onTap: () => _handleBusTap(entry.key, context),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.directions_bus,
                                color: Colors.red,
                                size: 30, // Réduit la taille pour éviter l'overflow
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                constraints: const BoxConstraints(maxWidth: 40), // Limite la largeur
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  entry.key,
                                  style: const TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  overflow: TextOverflow.ellipsis, // Gère le texte trop long
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
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
          showModalBottomSheet(
            context: context,
            isScrollControlled: true, // Permet le défilement si le contenu est trop long
            builder: (BuildContext context) {
              return Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min, // Prend seulement l'espace nécessaire
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Bus en service",
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const Divider(),
                    // Utilisation d'une ListView pour permettre le défilement
                    SizedBox(
                      height: MediaQuery.of(context).size.height * 0.5, // Limite la hauteur
                      child: ListView(
                        shrinkWrap: true,
                        children: _allBuses.map((bus) {
                          return GestureDetector(
                            onTap: () {
                              Navigator.pop(context); // Ferme le bottom sheet
                              _handleBusTap(bus['id'], context);
                            },
                            child: _buildBusInfo(
                              bus['id'],
                              bus['route'] ?? 'Route non spécifiée',
                              bus['actif'] == true ? Colors.green : Colors.red,
                              bus['actif'] == true ? "En route" : "Arrêté",
                            ),
                          );
                        }).toList(),
                      ),
                    ),
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
  Widget _buildBusInfo(String matricule, String route, Color color, String status) {
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
                Text(matricule, style: const TextStyle(fontWeight: FontWeight.bold)),
                Text(
                  route,
                  style: TextStyle(color: Colors.grey[700]),
                  overflow: TextOverflow.ellipsis, // Empêche le débordement de texte
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              // ignore: deprecated_member_use
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              status,
              style: TextStyle(color: color, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}