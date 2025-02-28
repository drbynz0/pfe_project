import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class GestionClassesEleves extends StatefulWidget {
  const GestionClassesEleves({super.key});

  @override
  GestionClassesElevesState createState() => GestionClassesElevesState();
}

class GestionClassesElevesState extends State<GestionClassesEleves> {
  String? selectedClass;
  String? selectedMatiere;
  String horaireMatiere = "";
  String? teacherDocId;
  List<String> classNames = [];
  List<Map<String, String>> matieres = [];
  List<Map<String, dynamic>> students = [];
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  void initState() {
    super.initState();
    _findTeacherDocument();
  }

  Future<void> _findTeacherDocument() async {
    String? uid = _auth.currentUser?.uid;
    if (uid == null) return;

    var querySnapshot = await FirebaseFirestore.instance
        .collection('Enseignants')
        .where('uid', isEqualTo: uid)
        .limit(1)
        .get();

    if (querySnapshot.docs.isNotEmpty) {
      setState(() {
        teacherDocId = querySnapshot.docs.first.id;
      });
      _loadClassNames();
    }
  }

  Future<void> _loadClassNames() async {
    if (teacherDocId == null) return;

    var snapshot = await FirebaseFirestore.instance
        .collection('Enseignants')
        .doc(teacherDocId)
        .collection('Matieres')
        .get();

    setState(() {
      classNames = snapshot.docs.map((doc) => doc.id).toList();
      if (classNames.isNotEmpty) {
        selectedClass = classNames.first;
        _loadMatieres();
        _loadStudents();
      }
    });
  }

  Future<void> _loadMatieres() async {
    if (teacherDocId == null || selectedClass == null) return;

    var doc = await FirebaseFirestore.instance
        .collection('Enseignants')
        .doc(teacherDocId)
        .collection('Matieres')
        .doc(selectedClass)
        .get();

    if (doc.exists) {
      setState(() {
        matieres = List<Map<String, String>>.from(
          (doc['matieres'] as List).map((item) => {
            'nom': item['nom'] as String,
            'horaire': item['horaire'] as String,
          }),
        );
      });
    }
  }

  Future<void> _loadStudents() async {
    if (selectedClass == null) return;

    var snapshot = await FirebaseFirestore.instance
        .collection('Etudiants')
        .where('classe', isEqualTo: selectedClass)
        .get();

    setState(() {
      students = snapshot.docs.map((doc) {
        var data = doc.data();
        return {
          'id': doc.id,
          'nom': data['nom'],
          'prenom': data['prenom'],
          'present': false,
          'absent': false,
        };
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF082E4A),
      appBar: AppBar(
        title: const Text(
          "Gestion des Classes & Élèves",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontFamily: 'Inter Tight'),
        ),
        backgroundColor: const Color(0xFF140C5F),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.send, color: Color.fromARGB(255, 72, 144, 226)),
            onPressed: () => _envoyerListePresence(),
          ),
        ],
      ),
      body: Column(
        children: [
          // Barre de sélection de classe
          Container(
            color: Colors.blue[50],
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: classNames.map((className) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4.0),
                  child: _buildClassButton(className),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 10),

          // Sélection de la matière et affichage de l'horaire
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Row(
              children: [
                // Choix de la matière
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: selectedMatiere,
                    hint: const Text("Sélectionner une matière"),
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                    items: matieres
                        .map((matiere) => DropdownMenuItem<String>(
                              value: matiere["nom"],
                              child: Text(matiere["nom"]!),
                            ))
                        .toList(),
                    onChanged: (value) {
                      setState(() {
                        selectedMatiere = value;
                        horaireMatiere = matieres
                            .firstWhere((matiere) => matiere["nom"] == value)["horaire"]!;
                      });
                    },
                  ),
                ),
                const SizedBox(width: 10),
                // Affichage automatique de l'horaire
                Expanded(
                  child: TextField(
                    controller: TextEditingController(text: horaireMatiere),
                    readOnly: true,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      labelText: "Horaire",
                      filled: true,
                      fillColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // Tableau des élèves
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: _buildDataTable(),
            ),
          ),

          // Bouton pour envoyer la liste
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton.icon(
              onPressed: () => _envoyerListePresence(),
              icon: const Icon(Icons.check_circle),
              label: const Text("Envoyer la liste"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// **Boutons de sélection de classe**
  Widget _buildClassButton(String className) {
    return ElevatedButton(
      onPressed: () {
        setState(() {
          selectedClass = className;
          selectedMatiere = null;
          horaireMatiere = "";
          _loadMatieres();
          _loadStudents();
        });
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: selectedClass == className ? Colors.blue : Colors.grey[300],
        foregroundColor: selectedClass == className ? Colors.white : Colors.black,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
      child: Text(className),
    );
  }

  /// **Table des élèves**
  Widget _buildDataTable() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          boxShadow: const [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 5,
              spreadRadius: 2,
            )
          ],
        ),
        padding: const EdgeInsets.all(8),
        child: DataTable(
          border: TableBorder.all(
            color: Colors.blue[200]!,
            borderRadius: BorderRadius.circular(12),
            width: 1,
          ),
          columnSpacing: 20,
          headingRowColor: WidgetStateProperty.resolveWith<Color?>(
            (Set<WidgetState> states) => Colors.blue[200],
          ),
          columns: const [
            DataColumn(label: Text("Identifiant", style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text("Nom", style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text("Prénom", style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text("Présent", style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text("Absent", style: TextStyle(fontWeight: FontWeight.bold))),
          ],
          rows: students.map((eleve) {
            return DataRow(
              cells: [
                DataCell(Text(eleve["id"]!)),
                DataCell(Text(eleve["nom"]!)),
                DataCell(Text(eleve["prenom"]!)),
                DataCell(Checkbox(
                  value: eleve["present"],
                  onChanged: (bool? value) {
                    setState(() {
                      eleve["present"] = value!;
                      eleve["absent"] = !value;
                    });
                  },
                )),
                DataCell(Checkbox(
                  value: eleve["absent"],
                  onChanged: (bool? value) {
                    setState(() {
                      eleve["absent"] = value!;
                      eleve["present"] = !value;
                    });
                  },
                )),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  /// **Méthode pour envoyer la liste des présences**
  void _envoyerListePresence() async {
    String jourActuel = DateFormat('EEEE', 'fr_FR').format(DateTime.now());
    for (var eleve in students) {
      if (eleve["absent"] == true) {
        var docRef = FirebaseFirestore.instance.collection('Etudiants').doc(eleve["id"]);
        await docRef.update({
          "nbabsence": FieldValue.increment(1),
          "absences": FieldValue.arrayUnion([
            {
              "matiere": selectedMatiere,
              "horaire": horaireMatiere,
              "jour": jourActuel,
            }
          ]),
        });
      }
    }
    // ignore: use_build_context_synchronously
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Liste de présence envoyée avec succès"), backgroundColor: Colors.green),
    );
  }
}