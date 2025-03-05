import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SaisieNotesPage extends StatefulWidget {
  final Map<String, dynamic> student;
  final List<Map<String, dynamic>> matieres;

  const SaisieNotesPage({super.key, required this.student, required this.matieres});

  @override
  SaisieNotesPageState createState() => SaisieNotesPageState();
}

class SaisieNotesPageState extends State<SaisieNotesPage> {
  String selectedTab = "saisie";
  Map<String, List<double>> notes = {};

  @override
  void initState() {
    super.initState();
    _initializeNotes();
  }

  void _initializeNotes() {
    for (var matiere in widget.matieres) {
      String nomMatiere = matiere["nom"]; // Utiliser "nom" au lieu de "matiere"
      var storedNotes = widget.student["notes"][nomMatiere];

      if (storedNotes is String) {
        // Si la valeur est une String (ex: "13.5"), on la convertit en liste [13.5]
        notes[nomMatiere] = [double.tryParse(storedNotes) ?? 0.0];
      } else if (storedNotes is List) {
        // Si c'est déjà une liste, on la garde
        notes[nomMatiere] = List<double>.from(storedNotes.map((e) => double.tryParse(e.toString()) ?? 0.0));
      } else {
        // Si aucune note n'est enregistrée, on initialise une liste vide
        notes[nomMatiere] = [];
      }
    }
  }

  void _ajouterNote(String matiere) {
    setState(() {
      notes[matiere]!.add(0.0);
    });
  }

  double _calculerSousMoyenne(List<double> notes) {
    if (notes.isEmpty) return 0.0;
    return notes.reduce((a, b) => a + b) / notes.length;
  }

  Future<void> _enregistrerNotes() async {
    Map<String, dynamic> updatedNotes = {};

    for (var matiere in widget.matieres) {
      String nomMatiere = matiere["nom"];
      updatedNotes[nomMatiere] = notes[nomMatiere];
    }

    // Mettre à jour Firestore
    await FirebaseFirestore.instance
        .collection('Etudiants')
        .doc(widget.student['id'])
        .update({
          'Notes.${widget.student['annee_scolaire']}': updatedNotes,
        });

    // Retourner les notes mises à jour à la page précédente
    // ignore: use_build_context_synchronously
    Navigator.pop(context, updatedNotes);
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: const Color(0xFF082E4A),
        appBar: AppBar(
          title: Text("Notes - ${widget.student['nom']} ${widget.student['prenom']}",
              style: const TextStyle(color: Colors.white)),
          backgroundColor: const Color(0xFF140C5F),
          bottom: const TabBar(
            indicatorColor: Color.fromARGB(255, 45, 123, 220),
            labelColor: Colors.white,
            unselectedLabelColor: Colors.grey,
            tabs: [
              Tab(text: "Saisie des Notes"),
              Tab(text: "Consultation des Notes"),
            ],
          ),
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        body: TabBarView(
          children: [
            _buildSaisieNotes(),
            _buildConsultationNotes(),
          ],
        ),
      ),
    );
  }

  Widget _buildSaisieNotes() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        ...widget.matieres.map((matiere) {
          String nomMatiere = matiere["nom"];
          return Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.only(bottom: 16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "$nomMatiere (Coef: ${matiere["coef"]})",
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  ...notes[nomMatiere]!.asMap().entries.map((entry) {
                    int index = entry.key;
                    return Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            initialValue: entry.value.toString(),
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                              labelText: "Note ${index + 1}",
                            ),
                            onChanged: (value) {
                              setState(() {
                                notes[nomMatiere]![index] = double.tryParse(value) ?? 0.0;
                              });
                            },
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () {
                            setState(() {
                              notes[nomMatiere]!.removeAt(index);
                            });
                          },
                        ),
                      ],
                    );
                  }),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Sous-moyenne: ${_calculerSousMoyenne(notes[nomMatiere]!).toStringAsFixed(2)}",
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                      ),
                      IconButton(
                        icon: const Icon(Icons.add, color: Colors.blue),
                        onPressed: () => _ajouterNote(nomMatiere),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        }),
        ElevatedButton(
          onPressed: _enregistrerNotes,
          style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
          child: const Text("Enregistrer", style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }

  Widget _buildConsultationNotes() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 5, spreadRadius: 2)],
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Center(
                child: Text("Bulletin des Notes", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 16),
              Table(
                border: TableBorder.all(color: Colors.black),
                columnWidths: const {
                  0: FlexColumnWidth(2),
                  1: FlexColumnWidth(1),
                  2: FlexColumnWidth(1),
                },
                children: [
                  _buildTableHeader(),
                  ...widget.matieres.map((matiere) => _buildTableRow(matiere)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  TableRow _buildTableHeader() {
    return TableRow(
      decoration: BoxDecoration(color: Colors.blue[200]),
      children: const [
        Padding(padding: EdgeInsets.all(8), child: Text("Matière", style: TextStyle(fontWeight: FontWeight.bold))),
        Padding(padding: EdgeInsets.all(8), child: Text("Notes", style: TextStyle(fontWeight: FontWeight.bold))),
        Padding(padding: EdgeInsets.all(8), child: Text("Sous-moyenne", style: TextStyle(fontWeight: FontWeight.bold))),
      ],
    );
  }

  TableRow _buildTableRow(Map<String, dynamic> matiere) {
    String nomMatiere = matiere["nom"];
    List<double> notesList = notes[nomMatiere]!;
    String notesStr = notesList.isEmpty ? "-" : notesList.map((n) => n.toStringAsFixed(1)).join(", ");
    double sousMoyenne = _calculerSousMoyenne(notesList);

    return TableRow(
      children: [
        Padding(padding: const EdgeInsets.all(8), child: Text(nomMatiere)),
        Padding(padding: const EdgeInsets.all(8), child: Text(notesStr)),
        Padding(padding: const EdgeInsets.all(8), child: Text(sousMoyenne.toStringAsFixed(2))),
      ],
    );
  }
}