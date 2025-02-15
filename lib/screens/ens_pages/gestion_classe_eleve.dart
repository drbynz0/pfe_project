import 'package:flutter/material.dart';

class GestionClassesEleves extends StatefulWidget {
  const GestionClassesEleves({super.key});

  @override
  GestionClassesElevesState createState() => GestionClassesElevesState();
}

class GestionClassesElevesState extends State<GestionClassesEleves> {
  String selectedClass = "GI"; // Classe par défaut sélectionnée
  String? selectedMatiere; // Matière sélectionnée
  String horaireMatiere = ""; // Horaire affiché automatiquement

  // Liste des matières et horaires par classe
  final Map<String, List<Map<String, String>>> matieresData = {
    "GI": [
      {"matiere": "Programmation Mobile", "horaire": "08:00 - 10:00"},
      {"matiere": "Base de Données", "horaire": "14:00 - 16:00"},
      {"matiere": "Algorithmes", "horaire": "10:00 - 12:00"},
    ],
    "ARI": [
      {"matiere": "Administration Réseau", "horaire": "09:00 - 11:00"},
      {"matiere": "Sécurité Informatique", "horaire": "13:00 - 15:00"},
      {"matiere": "Virtualisation", "horaire": "15:00 - 17:00"},
    ],
  };

  // Liste des élèves par classe
  final Map<String, List<Map<String, dynamic>>> classesData = {
    "GI": [
      {"nom": "Mohamed", "prenom": "Ali", "present": false, "absent": false},
      {"nom": "Said", "prenom": "Fatima", "present": false, "absent": false},
      {"nom": "Ahmed", "prenom": "Youssouf", "present": false, "absent": false},
    ],
    "ARI": [
      {"nom": "Hassan", "prenom": "Salim", "present": false, "absent": false},
      {"nom": "Abdou", "prenom": "Mariam", "present": false, "absent": false},
      {"nom": "Bacar", "prenom": "Ismael", "present": false, "absent": false},
    ],
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF082E4A),
      appBar: AppBar(
        title: const Text("Gestion des Classes & Élèves",
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
              children: [
                _buildClassButton("GI"),
                const SizedBox(width: 8),
                _buildClassButton("ARI"),
              ],
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
                    items: matieresData[selectedClass]!
                        .map((matiere) => DropdownMenuItem<String>(
                              value: matiere["matiere"],
                              child: Text(matiere["matiere"]!),
                            ))
                        .toList(),
                    onChanged: (value) {
                      setState(() {
                        selectedMatiere = value;
                        horaireMatiere = matieresData[selectedClass]!
                            .firstWhere((matiere) => matiere["matiere"] == value)["horaire"]!;
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
            DataColumn(label: Text("Nom", style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text("Prénom", style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text("Présent", style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text("Absent", style: TextStyle(fontWeight: FontWeight.bold))),
          ],
          rows: classesData[selectedClass]!.map((eleve) {
            return DataRow(
              cells: [
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
  void _envoyerListePresence() {
    // Implémentation pour envoyer la liste des absents avec la matière et l'horaire
  }
}
