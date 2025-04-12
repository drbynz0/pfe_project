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

  // [Garder toutes vos méthodes existantes comme _findTeacherDocument, _loadClassNames, etc...]
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
      backgroundColor: const Color.fromARGB(255, 25, 35, 51),
      body: Column(
        children: [
          _buildClassSelection(),
          _buildSearchAndExportRow(), // Modifié pour inclure l'export
          Expanded(child: _buildStudentStream()),
        ],
      ),
    );
  }

  Widget _buildSearchAndExportRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: searchController,
              decoration: InputDecoration(
                hintStyle: TextStyle(color: Colors.grey[400]),
                filled: true,
                fillColor: Colors.white,
                labelText: "Rechercher un élève",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: const BorderSide(color: Colors.white),
                ),
                prefixIcon: const Icon(Icons.search),
              ),
              onChanged: (value) => setState(() {}),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.save, color: Colors.white),
            onPressed: () => _showExportOptions(context),
            tooltip: "Exporter les notes",
            style: IconButton.styleFrom(
              backgroundColor: Colors.blue[700],
              padding: const EdgeInsets.all(13),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // [Garder _buildClassSelection, _buildClassButton, etc...]
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

  Widget _buildStudentStream() {
    if (selectedClass == null) {
      return const Center(
        child: Text(
          "Veuillez sélectionner une classe",
          style: TextStyle(color: Colors.white)),
      );
    }

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
          return Center(
              child: Text('Erreur de chargement: ${snapshot.error}',
                  style: const TextStyle(color: Colors.white)));
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(
              child: Text('Aucun étudiant trouvé',
                  style: TextStyle(color: Colors.white)));
        }

        var students = snapshot.data!.docs.map((doc) {
          // [Garder votre logique existante de traitement des données]
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
            'nom': doc['nom'],
            'prenom': doc['prenom'],
            'annee_scolaire': doc['annee_scolaire'] ?? "Inconnue",
            'notes': filteredNotes, // [Garder votre logique de traitement des notes]
          };

        }).toList();

        return _buildStudentCards(students);
      },
    );
  }

  Widget _buildStudentCards(List<Map<String, dynamic>> students) {
    List<Map<String, dynamic>> filteredStudents = students.where((student) {
      final fullName = "${student['nom']} ${student['prenom']}".toLowerCase();
      return fullName.contains(searchController.text.toLowerCase());
    }).toList();

    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: filteredStudents.length,
      itemBuilder: (context, index) {
        final student = filteredStudents[index];
        return Card(
          elevation: 4,
          margin: const EdgeInsets.symmetric(vertical: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "${student['nom']} ${student['prenom']}",
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      "ID: ${student['id']}",
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Divider(),
                const SizedBox(height: 8),
                ...matieres.map((matiere) {
                  final note = student['notes'][matiere['nom']] ?? "-";
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          matiere['nom'],
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 4),
                              decoration: BoxDecoration(
                                color: _getNoteColor(note),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                student['notes'][matiere['nom']] ?? "-",
                                style: TextStyle(
                                  color: note == "-" ? Colors.black : Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              "(Coef ${matiere['coef']})",
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                }),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerRight,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.edit, size: 18, color: Color.fromARGB(255, 39, 8, 90)),
                    label: const Text("Saisir/Modifier", 
                        style: TextStyle(color: Color.fromARGB(255, 39, 8, 90))),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => SaisieNotesPage(
                            student: student,
                            matieres: matieres,
                          ),
                        ),
                      ).then((value) {
                        if (value != null) setState(() {});
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color.fromARGB(255, 145, 187, 230),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Color _getNoteColor(dynamic note) {
    if (note == "-") return Colors.grey[200]!;
    final numericNote = double.tryParse(note.toString()) ?? 0;
    if (numericNote < 8) return Colors.red;
    if (numericNote < 12) return Colors.orange;
    if (numericNote < 15) return Colors.lightGreen;
    return Colors.green;
  }

  void _showExportOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (_) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              "Exporter les notes",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildExportButton(
                  icon: Icons.picture_as_pdf,
                  color: Colors.red,
                  label: "PDF",
                  onTap: () {
                    Navigator.pop(context);
                    ExportService.exportToPDF(context, []);
                  },
                ),
                _buildExportButton(
                  icon: Icons.table_chart,
                  color: Colors.green,
                  label: "Excel",
                  onTap: () {
                    Navigator.pop(context);
                    ExportService.exportToExcel(context, []);
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildExportButton({
    required IconData icon,
    required Color color,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              // ignore: deprecated_member_use
              color: color.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 30),
          ),
          const SizedBox(height: 8),
          Text(label, style: TextStyle(color: color, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}