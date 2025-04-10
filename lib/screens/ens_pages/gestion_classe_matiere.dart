import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class GestionClassesMatieres extends StatefulWidget {
  const GestionClassesMatieres({super.key});

  @override
  GestionClassesMatieresState createState() => GestionClassesMatieresState();
}

class GestionClassesMatieresState extends State<GestionClassesMatieres> {
  String? selectedClass;
  String? teacherDocId;
  List<String> classNames = [];
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
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF082E4A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF140C5F),
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          "Gestion des Classes & Matières",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontFamily: "Inter Tight",
          ),
        ),
      ),
      body: Column(
        children: [
          _buildClassSelection(),
          const SizedBox(height: 10),
          Expanded(
            child: teacherDocId == null || selectedClass == null
                ? const Center(child: CircularProgressIndicator())
                : FutureBuilder<DocumentSnapshot>(
                    future: FirebaseFirestore.instance
                        .collection('Enseignants')
                        .doc(teacherDocId)
                        .collection('Matieres')
                        .doc(selectedClass)
                        .get(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      if (!snapshot.hasData || !snapshot.data!.exists) {
                        return const Center(
                          child: Text(
                            "Aucune matière trouvée",
                            style: TextStyle(color: Colors.white, fontSize: 16),
                          ),
                        );
                      }

                      var matieres = List<Map<String, dynamic>>.from(snapshot.data!['matieres']);
                  
                      return SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: DataTable(
                          columns: const [
                            DataColumn(
                              label: Center(
                                child: Text(
                                  "Matière",
                                  style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
                                ),
                              ),
                            ),
                            DataColumn(
                              label: Center(
                                child: Text(
                                  "Jours",
                                  style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
                                ),
                              ),
                            ),
                            DataColumn(
                              label: Center(
                                child: Text(
                                  "Horaire",
                                  style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
                                ),
                              ),
                            ),
                            DataColumn(
                              label: Center(
                                child: Text(
                                  "Coefficient",
                                  style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
                                ),
                              ),
                            ),
                          ],
                          rows: matieres.map((matiere) {
                            return DataRow(
                              cells: [
                                DataCell(
                                  Center(
                                    child: Text(
                                      matiere['nom'] ?? "Nom inconnu",
                                      style: const TextStyle(color: Colors.black),
                                    ),
                                  ),
                                ),
                                DataCell(
                                  Center(
                                    child: Text(
                                      matiere['jour'] ?? "N/A",
                                      style: const TextStyle(color: Colors.black),
                                    ),
                                  ),
                                ),
                                DataCell(
                                  Center(
                                    child: Text(
                                      matiere['horaire'] ?? "N/A",
                                      style: const TextStyle(color: Colors.black),
                                    ),
                                  ),
                                ),
                                DataCell(
                                  Center(
                                    child: Text(
                                      matiere['coef']?.toString() ?? "N/A",
                                      style: const TextStyle(color: Colors.black),
                                    ),
                                  ),
                                ),
                              ],
                            );
                          }).toList(),
                          headingRowColor: WidgetStateProperty.all(const Color.fromARGB(255, 104, 135, 238)),
                          dataRowColor: WidgetStateProperty.all(Colors.white),
                          border: TableBorder.all(
                            color: Colors.white,
                            width: 1,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          columnSpacing: 20,
                          horizontalMargin: 16,
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
