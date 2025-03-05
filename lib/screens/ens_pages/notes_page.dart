import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '/services/export_service.dart';
import 'saisie_notes.dart';

class NotesPage extends StatefulWidget {
  const NotesPage({super.key});

  @override
  NotesPageState createState() => NotesPageState();
}

class NotesPageState extends State<NotesPage> {
  String? selectedClass;
  String? teacherDocId;
  List<String> classNames = [];
  List<Map<String, dynamic>> matieres = [];
  TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _findTeacherDocument();
  }

  Future<void> _findTeacherDocument() async {
    String? uid = FirebaseAuth.instance.currentUser?.uid;
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
        matieres = List<Map<String, dynamic>>.from(doc['matieres']);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF082E4A),
      appBar: AppBar(
        title: const Text('Saisie des notes', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF140C5F),
        actions: [
          IconButton(
            icon: const Icon(Icons.download, color: Colors.green),
            onPressed: () => _showExportOptions(context),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildClassSelection(),
          _buildSearchBar(),
          Expanded(child: _buildStudentStream()),
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
        children: classNames.map((className) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4.0),
            child: _buildClassButton(className),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: TextField(
        controller: searchController,
        decoration: InputDecoration(
          hintStyle: TextStyle(color: Colors.grey[400]),
          filled: true,
          fillColor: Colors.white,
          labelText: "Rechercher un élève",
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: const BorderSide(color: Colors.white)),
          prefixIcon: const Icon(Icons.search),
        ),
        onChanged: (value) {
          setState(() {});
        },
      ),
    );
  }

  Widget _buildClassButton(String className) {
    return ElevatedButton(
      onPressed: () {
        setState(() {
          selectedClass = className;
          _loadMatieres();
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

  // StreamBuilder pour écouter les changements dans Firestore
 Widget _buildStudentStream() {
    if (selectedClass == null) return const Center(child: Text("Veuillez sélectionner une classe"));

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('Etudiants')
          .where('classe', isEqualTo: selectedClass)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return const Center(child: Text('Erreur de chargement des étudiants'));
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text('Aucun étudiant trouvé'));
        }

        var students = snapshot.data!.docs.map((doc) {
          var data = doc.data() as Map<String, dynamic>;
          var notes = data['Notes'] as Map<String, dynamic>? ?? {};
          var anneeScolaire = data['annee_scolaire'] ?? "Inconnue"; // Sécurité si null

          // Vérifier si les notes de l'année existent bien
          var notesAnneeEnCours = notes[anneeScolaire] is Map<String, dynamic> 
            ? notes[anneeScolaire] as Map<String, dynamic> 
            : {};

          // Filtrer les notes pour ne garder que celles des matières enseignées
          Map<String, dynamic> filteredNotes = {};
          for (var matiere in matieres) {
            String matiereNom = matiere["nom"]; // Récupérer le nom de la matière

            if (notesAnneeEnCours is Map<String, dynamic> && notesAnneeEnCours.containsKey(matiereNom)) {
              filteredNotes[matiereNom] = notesAnneeEnCours[matiereNom];
            }
          }

          return {
            'id': doc.id,
            'nom': data['nom'],
            'prenom': data['prenom'],
            'annee_scolaire': anneeScolaire,
            'notes': filteredNotes,
          };
        }).toList();

        return _buildDataTable(students);
      },
    );
  }

  Widget _buildDataTable(List<Map<String, dynamic>> students) {
    List<Map<String, dynamic>> filteredStudents = students
        .where((student) =>
            student["nom"]!.toLowerCase().contains(searchController.text.toLowerCase()))
        .toList();

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
          border: TableBorder.all(color: Colors.blue[200]!),
          headingRowColor: WidgetStateProperty.resolveWith((_) => Colors.blue[200]),
          columns: [
            const DataColumn(label: Text("Code Étudiant", style: TextStyle(fontWeight: FontWeight.bold))),
            const DataColumn(label: Text("Nom & Prénom", style: TextStyle(fontWeight: FontWeight.bold))),
            ...matieres.map((matiere) => DataColumn(label: Text(
              "${matiere["nom"]} (Coef: ${matiere["coef"]})",
              style: const TextStyle(fontWeight: FontWeight.bold),
            ))),
            const DataColumn(label: Text("Action", style: TextStyle(fontWeight: FontWeight.bold))),
          ],
          rows: filteredStudents.map((student) {
            return DataRow(
              cells: [
                DataCell(Text(student["id"]!)),
                DataCell(Text("${student["nom"]} ${student["prenom"]}")),
                ...matieres.map((matiere) =>
                  DataCell(Center(child: Text(student["notes"][matiere["nom"]] ?? "-")))),
                DataCell(
                  Center(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => SaisieNotesPage(student: student, matieres: matieres),
                          ),
                        ).then((value) {
                          if (value != null) {
                            setState(() {
                              student["notes"] = value;
                            });
                          }
                        });
                      },
                      child: const Text("Saisir / Modifier"),
                    ),
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  void _showExportOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (_) => Wrap(
        children: [
          ListTile(
            leading: const Icon(Icons.picture_as_pdf, color: Colors.red),
            title: const Text("Exporter en PDF"),
            onTap: () => ExportService.exportToPDF(context, []), // Mettre les étudiants ici
          ),
          ListTile(
            leading: const Icon(Icons.table_chart, color: Colors.green),
            title: const Text("Exporter en Excel"),
            onTap: () => ExportService.exportToExcel(context, []), // Mettre les étudiants ici
          ),
        ],
      ),
    );
  }
}