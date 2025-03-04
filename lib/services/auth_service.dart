import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'device_service.dart';

class AuthService {
  static void logout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    // ignore: use_build_context_synchronously
    Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
  }

  static void login(BuildContext context, DocumentSnapshot userDoc, String id, bool isLoading, TextEditingController idController) async {
    // Récupérer le rôle dans Firestore
    userDoc = await FirebaseFirestore.instance.collection('Users').doc(id).get();

    if (userDoc.exists) {
      String userType = userDoc['type'];

      if (userType == 'enseignant') {
        Navigator.pushReplacementNamed(
          // ignore: use_build_context_synchronously
          context,
          '/homeEns',
        );
      } else if (userType == 'etudiant') {
        // ignore: use_build_context_synchronously
        Navigator.pushReplacementNamed(context, '/homeEtud');
      } else if (userType == 'conducteur') {
        // ignore: use_build_context_synchronously
        Navigator.pushReplacementNamed(context, '/homeCond');
      } else if (userType == 'parent') {
        // ignore: use_build_context_synchronously
        Navigator.pushReplacementNamed(context, '/homePar');
      } else {
        // ignore: use_build_context_synchronously
        _showErrorDialog(context, "Type d'utilisateur inconnu");
      }
    } else {
      // ignore: use_build_context_synchronously
      _showErrorDialog(context, "Utilisateur non trouvé");
    }
  }

  static Future<void> createSession(String identifiant) async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    // Récupérer le nom de l'appareil (facultatif, nécessite un package externe)
    String deviceName = await DeviceService.getDeviceName();
    String devicePlatform = await DeviceService.getDevicePlatform();
    String deviceLocation = await DeviceService.getDeviceLocation();
    // Générer un ID unique pour la session
    String sessionId = identifiant;

    // Vérifier si la session existe déjà
    DocumentSnapshot sessionDoc = await FirebaseFirestore.instance
        .collection('Users')
        .doc(identifiant)
        .collection('Sessions')
        .doc(sessionId)
        .get();

    if (sessionDoc.exists) {
      // Si la session existe, mettre à jour lastActive
      await updateLastActive(sessionId, identifiant);
    } else {
      // Sinon, créer une nouvelle session
      await FirebaseFirestore.instance
          .collection('Users')
          .doc(identifiant)
          .collection('Sessions')
          .doc(sessionId)
          .set({
        'deviceName': deviceName,
        'lastActive': DateTime.now().toIso8601String(),
        'devicePlatform': devicePlatform,
        'deviceLocation': deviceLocation,
      });
    }
  }

  static Future<List<Session>> getActiveSessions(String? idUser) async {
    if (idUser == null) return []; // Retourner une liste vide si aucun utilisateur n'est connecté

    try {
      // Récupérer le document utilisateur en vérifiant le champ 'uid'
      QuerySnapshot userSnapshot = await FirebaseFirestore.instance
          .collection('Users')
          .where('uid', isEqualTo: idUser)
          .limit(1)
          .get();

      if (userSnapshot.docs.isEmpty) {
        return [];
      }

      // Récupérer l'ID du document utilisateur
      String userId = userSnapshot.docs.first.id;

      // Récupérer les sessions de l'utilisateur depuis Firestore
      QuerySnapshot sessionsSnapshot = await FirebaseFirestore.instance
          .collection('Users')
          .doc(userId)
          .collection('Sessions')
          .get();

      if (sessionsSnapshot.docs.isEmpty) {
        return [];
      }

      // Convertir les documents en objets Session
      List<Session> sessions = sessionsSnapshot.docs.map((doc) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        return Session(
          deviceName: data['deviceName'] ?? 'Inconnu', // Valeur par défaut si le champ est manquant
          lastActive: data['lastActive'] ?? 'Inconnu',
          devicePlatform: data['devicePlatform'] ?? 'Inconnu',
          deviceLocation: data['deviceLocation'] ?? 'Inconnu',
          sessionId: doc.id, // L'ID du document Firestore est utilisé comme ID de session
        );
      }).toList();

      return sessions;
    } catch (e) {
      // Gérer les erreurs (par exemple, problèmes de réseau ou Firestore indisponible)
      SnackBar(content: Text("Erreur lors de la récupération des sessions : $e"));
      return [];
    }
  }

  static Future<void> logoutSession(String sessionId, String? idUser) async {
    if (idUser == null) return;

    try {
      // Récupérer le document utilisateur en vérifiant le champ 'uid'
      QuerySnapshot userSnapshot = await FirebaseFirestore.instance
          .collection('Users')
          .where('uid', isEqualTo: idUser)
          .limit(1)
          .get();

      if (userSnapshot.docs.isEmpty) {
        return;
      }

      // Récupérer l'ID du document utilisateur
      String userId = userSnapshot.docs.first.id;

      await FirebaseFirestore.instance
          .collection('Users')
          .doc(userId)
          .collection('Sessions')
          .doc(sessionId)
          .delete();
    } catch (e) {
      // Gérer les erreurs (par exemple, problèmes de réseau ou Firestore indisponible)
      SnackBar(content: Text("Erreur lors de la récupération des sessions : $e"));
      return;
    }
  }

  static Future<void> updateLastActive(String sessionId, String idUser) async {

    try {
      // Récupérer le document utilisateur en vérifiant le champ 'uid'
      QuerySnapshot userSnapshot = await FirebaseFirestore.instance
          .collection('Users')
          .where('uid', isEqualTo: idUser)
          .limit(1)
          .get();

      if (userSnapshot.docs.isEmpty) {
        return;
      }

      // Récupérer l'ID du document utilisateur
      String userId = userSnapshot.docs.first.id;

      await FirebaseFirestore.instance
          .collection('Users')
          .doc(userId)
          .collection('Sessions')
          .doc(sessionId)
          .update({'lastActive': DateTime.now().toIso8601String()});
    } catch (e) {
      // Gérer les erreurs (par exemple, problèmes de réseau ou Firestore indisponible)
      SnackBar(content: Text("Erreur lors de la récupération des sessions : $e"));
      return;
    }
  }

  // Fonction pour afficher une boîte de dialogue en cas d'erreur
  static void _showErrorDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.error, color: Colors.red),
            SizedBox(width: 10),
            Text('Erreur'),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}

class Session {
  final String deviceName;
  final String lastActive;
  final String devicePlatform;
  final String deviceLocation;
  final String sessionId;

  Session({required this.deviceName, required this.lastActive, required this.devicePlatform, required this.deviceLocation, required this.sessionId});
}