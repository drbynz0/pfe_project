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
  List<Map<String, dynamic>> students = [];
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
        matieres = List<Map<String, dynamic>>.from(doc['matieres']);
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
          'notes': data['notes'] ?? {},
        };
      }).toList();
    });

    // Charger les notes des étudiants pour l'année scolaire en cours
    await _loadStudentNotes();
  }

  Future<void> _loadStudentNotes() async {
    for (var student in students) {
      var doc = await FirebaseFirestore.instance
          .collection('Etudiants')
          .doc(student['id'])
          .collection('Notes')
          .orderBy('annee', descending: true)
          .limit(1)
          .get();

      if (doc.docs.isNotEmpty) {
        var notesData = doc.docs.first.data();
        setState(() {
          student['notes'] = notesData;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    List<Map<String, dynamic>> filteredStudents = students
        .where((student) =>
            student["nom"]!.toLowerCase().contains(searchController.text.toLowerCase()) &&
            student["id"]!.startsWith(selectedClass!))
        .toList();

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
          Expanded(child: _buildDataTable(filteredStudents, matieres)),
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
          labelText: "Rechercher un élève",
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(20)),
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

  Widget _buildDataTable(List<Map<String, dynamic>> students, List<Map<String, dynamic>> matieres) {
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
          rows: students.map((student) {
            return DataRow(
              cells: [
                DataCell(Text(student["id"]!)),
                DataCell(Text("${student["nom"]} ${student["prenom"]}")),
                ...matieres.map((matiere) =>
                  DataCell(Center(child: Text(student["notes"][matiere["nom"]] ?? "-")))
                ),
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
            onTap: () => ExportService.exportToPDF(context, students),
          ),
          ListTile(
            leading: const Icon(Icons.table_chart, color: Colors.green),
            title: const Text("Exporter en Excel"),
            onTap: () => ExportService.exportToExcel(context, students),
          ),
        ],
      ),
    );
  }
}
