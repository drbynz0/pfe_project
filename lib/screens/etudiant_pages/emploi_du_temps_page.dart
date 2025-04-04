import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class EmploiDuTempsPage extends StatefulWidget {
  const EmploiDuTempsPage({super.key});

  @override
  EmploiDuTempsPageState createState() => EmploiDuTempsPageState();
}

class EmploiDuTempsPageState extends State<EmploiDuTempsPage> {
  final List<String> jours = ["Lundi", "Mardi", "Mercredi", "Jeudi", "Vendredi"];
  final List<String> horaires = ["08h00 - 10h00", "10h15 - 12h15", "14h00 - 16h00", "16h15 - 18h15"];

  String? currentUserId;
  String? classeEtudiant;
  Map<String, Map<String, String>> emploiDuTemps = {};

  @override
  void initState() {
    super.initState();
    _getCurrentUserId();
  }

  /// 🔹 Étape 1 : Récupérer l'ID de l'utilisateur connecté
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
        _getClasseEtudiant();
      }
    }
  }

  /// 🔹 Étape 2 : Récupérer la classe de l'étudiant
  Future<void> _getClasseEtudiant() async {
    if (currentUserId == null) return;

    DocumentSnapshot etudiantSnapshot = await FirebaseFirestore.instance
        .collection('Etudiants')
        .doc(currentUserId)
        .get();

    if (etudiantSnapshot.exists) {
      setState(() {
        classeEtudiant = etudiantSnapshot.get('classe');
      });
      _chargerEmploiDuTemps();
    }
  }

  /// 🔹 Étape 3 : Charger l'emploi du temps à partir de Firestore
  Future<void> _chargerEmploiDuTemps() async {
    if (classeEtudiant == null) return;

    DocumentSnapshot doc = await FirebaseFirestore.instance
        .collection('Matieres')
        .doc(classeEtudiant)
        .get();

    if (doc.exists) {
      List<dynamic> matieres = doc["matieres"];
      Map<String, Map<String, String>> tempEmploiDuTemps = {};

      // Initialiser la structure vide
      for (var jour in jours) {
        tempEmploiDuTemps[jour] = { for (var horaire in horaires) horaire: "" };
      }

      // Remplir avec les matières depuis Firestore
      for (var matiere in matieres) {
        String nom = matiere["nom"];
        String jour = matiere["jour"];
        String horaire = matiere["horaire"];

        if (jours.contains(jour) && horaires.contains(horaire)) {
          tempEmploiDuTemps[jour]![horaire] = nom;
        }
      }

      setState(() {
        emploiDuTemps = tempEmploiDuTemps;
      });
    }
  }

  /// 🔹 Étape 4 : Construire l'interface utilisateur
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF082E4A),
      appBar: AppBar(
        title: const Text(
          "Emploi du Temps",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontFamily: 'Inter Tight'),
        ),
        backgroundColor: const Color(0xFF140C5F),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: ConstrainedBox(
            constraints: BoxConstraints(minWidth: constraints.maxWidth),
            child: SingleChildScrollView(
              scrollDirection: Axis.vertical,
              child: Container( // Ajout du Container pour le fond blanc
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12), // Coins arrondis
                  boxShadow: [
                    BoxShadow(
                      // ignore: deprecated_member_use
                      color: Colors.grey.withOpacity(0.2), 
                      spreadRadius: 2,
                      blurRadius: 5,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(8),
                child: FittedBox(
                  alignment: Alignment.topLeft,
                  child: DataTable(
                    border: TableBorder.all(
                      color: Colors.blue[200]!,
                      borderRadius: BorderRadius.circular(12),
                      width: 1,
                    ),
                    columnSpacing: 20.0,
                    headingRowColor: WidgetStateProperty.resolveWith<Color?>(
                      (Set<WidgetState> states) => const Color.fromARGB(255, 19, 58, 125),
                    ),
                    columns: [
                      const DataColumn(
                        label: Text(
                          "Jour",
                          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                      ),
                      for (var horaire in horaires)
                        DataColumn(
                          label: Text(
                            horaire,
                            style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                        ),
                    ],
                    rows: [
                      for (var jour in jours)
                        DataRow(
                          cells: [
                            DataCell(
                              Container(
                                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                                child: Text(
                                  jour,
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ),
                            ),
                            for (var horaire in horaires)
                              DataCell(Center(child: Text(emploiDuTemps[jour]?[horaire] ?? ""))),
                          ],
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
        },
      ),
    );
  }
}
