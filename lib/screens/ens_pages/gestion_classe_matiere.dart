import 'package:flutter/material.dart';

class GestionClassesMatieres extends StatefulWidget {
  const GestionClassesMatieres({super.key});

  @override
  GestionClassesMatieresState createState() => GestionClassesMatieresState();
}

class GestionClassesMatieresState extends State<GestionClassesMatieres> {
  String selectedClass = "GI"; // Classe par défaut sélectionnée

  // Stockage des matières et horaires
  final Map<String, List<Map<String, String>>> classesData = {
    "GI": [
      {"matiere": "Programmation Mobile", "jour": "Lundi, Mercredi", "horaire": "08:00 - 10:00"},
      {"matiere": "Base de Données", "jour": "Mardi, Jeudi", "horaire": "14:00 - 16:00"},
      {"matiere": "Algorithmes", "jour": "Vendredi", "horaire": "10:00 - 12:00"},
    ],
    "ARI": [
      {"matiere": "Administration Réseau", "jour": "Lundi, Jeudi", "horaire": "09:00 - 11:00"},
      {"matiere": "Sécurité Informatique", "jour": "Mardi, Mercredi", "horaire": "13:00 - 15:00"},
      {"matiere": "Virtualisation", "jour": "Vendredi", "horaire": "15:00 - 17:00"},
    ],
  };

  // Contrôleurs pour le formulaire d’ajout
  final TextEditingController _matiereController = TextEditingController();
  final TextEditingController _jourController = TextEditingController();
  final TextEditingController _horaireController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF082E4A),
      appBar: AppBar(
        title: const Text("Gestion des Classes & Matières",
        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: const Color(0xFF140C5F),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _afficherFormulaireAjout(context),
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
          // Tableau des matières
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: _buildDataTable(),
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

  

  /// **Table des matières**
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
          dataRowColor: WidgetStateProperty.resolveWith<Color?>(
            (Set<WidgetState> states) => Colors.white,
          ),
          headingRowColor: WidgetStateProperty.resolveWith<Color?>(
            (Set<WidgetState> states) => Colors.blue[200],
          ),
          columns: const [
            DataColumn(
              label: Text("Matière", style: TextStyle(fontWeight: FontWeight.bold)),
            ),
            DataColumn(
              label: Text("Jour", style: TextStyle(fontWeight: FontWeight.bold)),
            ),
            DataColumn(
              label: Text("Horaire", style: TextStyle(fontWeight: FontWeight.bold)),
            ),
            DataColumn(
              label: Text("Action", style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
          rows: classesData[selectedClass]!.map((matiere) {
            return DataRow(
              cells: [
                DataCell(Text(matiere["matiere"]!)),
                DataCell(Text(matiere["jour"]!)),
                DataCell(Text(matiere["horaire"]!)),
                DataCell(
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => _supprimerMatiere(matiere),
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  /// **Afficher le formulaire d'ajout de matière**
  void _afficherFormulaireAjout(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Ajouter une matière"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _matiereController,
                decoration: const InputDecoration(labelText: "Nom de la matière"),
              ),
              TextField(
                controller: _jourController,
                decoration: const InputDecoration(labelText: "Jours d'enseignement"),
              ),
              TextField(
                controller: _horaireController,
                decoration: const InputDecoration(labelText: "Horaire"),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                _matiereController.clear();
                _jourController.clear();
                _horaireController.clear();
                Navigator.pop(context);
              },
              child: const Text("Annuler"),
            ),
            ElevatedButton(
              onPressed: () {
                _ajouterMatiere();
                Navigator.pop(context);
              },
              child: const Text("Ajouter"),
            ),
          ],
        );
      },
    );
  }

  /// **Ajouter une matière**
  void _ajouterMatiere() {
    if (_matiereController.text.isEmpty || _jourController.text.isEmpty || _horaireController.text.isEmpty) {
      return;
    }

    setState(() {
      classesData[selectedClass]!.add({
        "matiere": _matiereController.text,
        "jour": _jourController.text,
        "horaire": _horaireController.text,
      });
    });

    _matiereController.clear();
    _jourController.clear();
    _horaireController.clear();
  }

  /// **Supprimer une matière**
  void _supprimerMatiere(Map<String, String> matiere) {
    setState(() {
      classesData[selectedClass]!.remove(matiere);
    });
  }
}
