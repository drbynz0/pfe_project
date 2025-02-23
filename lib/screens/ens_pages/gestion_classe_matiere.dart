import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '/services/matiere_service.dart';

class GestionClassesMatieres extends StatefulWidget {
  const GestionClassesMatieres({super.key});

  @override
  GestionClassesMatieresState createState() => GestionClassesMatieresState();
}

class GestionClassesMatieresState extends State<GestionClassesMatieres> {
  String selectedClass = "GI";
    late MatiereService matiereService;
     @override
    void didChangeDependencies() {
      super.didChangeDependencies();
      matiereService = Provider.of<MatiereService>(context, listen: false);
    }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor: const Color(0xFF082E4A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF140C5F),
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text("Gestion des Classes & Matières",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontFamily: "inter Tight")
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: Colors.blue),
            onPressed: () => _afficherFormulaireAjout(context),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildClassSelection(),
          Expanded(
            child: ListView.builder(
              itemCount: matiereService.getMatieres(selectedClass).length,
              itemBuilder: (context, index) {
                final matiere = matiereService.getMatieres(selectedClass)[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white, // Fond blanc
                      borderRadius: BorderRadius.circular(12), // Bord arrondi
                      boxShadow: [
                        BoxShadow(
                          // ignore: deprecated_member_use
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 4,
                          spreadRadius: 2,
                          offset: const Offset(2, 2), // Ombre légère
                        ),
                      ],
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      title: Text(
                        matiere['matiere'] ?? "Nom inconnu",
                        style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
                      ),
                      subtitle: Text(
                        "Jours : ${matiere['jours']} | Horaire : ${matiere['horaire']}",
                        style: const TextStyle(color: Colors.grey),
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () {
                          Provider.of<MatiereService>(context, listen: false)
                          .supprimerMatiere(selectedClass, matiere['matiere']);

                          setState(() {});
                        },
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

    Widget _buildClassSelection() {
    return Container(
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
    );
  }

void _afficherFormulaireAjout(BuildContext context) {
  TextEditingController matiereController = TextEditingController();
  TextEditingController coefficientController = TextEditingController();
  TextEditingController joursController = TextEditingController();
  TextEditingController horaireController = TextEditingController();

  showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: const Text("Ajouter une matière"),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: matiereController,
                decoration: const InputDecoration(labelText: "Nom de la matière"),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: coefficientController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: "Coefficient"),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: joursController,
                decoration: const InputDecoration(labelText: "Jours d'enseignement (ex: Lundi, Mercredi)"),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: horaireController,
                decoration: const InputDecoration(labelText: "Horaire (ex: 08:00 - 10:00)"),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Annuler"),
          ),
          ElevatedButton(
            onPressed: () {
              if (matiereController.text.isNotEmpty &&
                  coefficientController.text.isNotEmpty &&
                  joursController.text.isNotEmpty &&
                  horaireController.text.isNotEmpty) {
                Provider.of<MatiereService>(context, listen: false).ajouterMatiere(selectedClass, {
                  'matiere': matiereController.text,
                  'coefficient': int.tryParse(coefficientController.text) ?? 1, // Par défaut, coefficient = 1
                  'jours': joursController.text,
                  'horaire': horaireController.text,
                });
                setState(() {});
                Navigator.pop(context);
              }
            },
            child: const Text("Ajouter"),
          ),
        ],
      );
    },
  );
}

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
}
