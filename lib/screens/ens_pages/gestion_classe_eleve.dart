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
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _findTeacherDocument();
  }

  // [Conserver toutes vos méthodes existantes comme _findTeacherDocument, _loadClassNames, etc.]
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
      backgroundColor: const Color.fromARGB(255, 25, 35, 51),
      appBar: AppBar(
        title: const Text(
          "Gestion des Présences",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        backgroundColor: const Color.fromARGB(255, 25, 40, 62),
        iconTheme: const IconThemeData(color: Colors.white),
        centerTitle: true,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.send, color: Colors.white),
            onPressed: _envoyerListePresence,
            tooltip: "Envoyer les présences",
          ),
        ],
      ),
      body: Column(
        children: [
          // Section de filtrage
          _buildFilterSection(),
          
          // Liste des élèves
          Expanded(
            child: _buildStudentList(),
          ),
          
          // Bouton d'envoi
          _buildSubmitButton(),
        ],
      ),
    );
  }

  Widget _buildFilterSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(20), bottomRight: Radius.circular(20)),
        color: const Color.fromARGB(255, 33, 44, 71),
        boxShadow: [
          BoxShadow(
            // ignore: deprecated_member_use
            color: const Color.fromARGB(255, 119, 119, 119).withOpacity(0.3),
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        children: [
          // Barre de recherche
          TextField(
            style: const TextStyle(color: Colors.white),
            controller: _searchController,
            decoration: InputDecoration(
              hintText: "Rechercher un élève...",
              prefixIcon: const Icon(Icons.search, color: Colors.white),
              hintStyle: const TextStyle(color: Colors.white54),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(30),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: const Color.fromARGB(183, 28, 34, 58),
              contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
            ),
            onChanged: (value) => setState(() {}),
          ),
          const SizedBox(height: 16),
          
          // Sélecteurs de classe et matière
          Row(
            children: [
              Expanded(
                child: _buildClassDropdown(),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildSubjectDropdown(),
              ),
            ],
          ),
          const SizedBox(height: 8),
          
          // Horaire
          if (selectedMatiere != null) _buildScheduleInfo(),
        ],
      ),
    );
  }

  Widget _buildClassDropdown() {
    return DropdownButtonFormField<String>(
      value: selectedClass,
      style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
      decoration: InputDecoration(
        labelText: "Classe",
        labelStyle: const TextStyle(color: Colors.white),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
        ),
        filled: true,
        fillColor: const Color.fromARGB(183, 255, 255, 255),
      ),
      items: classNames.map((className) {
        return DropdownMenuItem(
          value: className,
          child: Text(className, style: const TextStyle(color: Colors.black)),
        );
      }).toList(),
      onChanged: (value) {
        setState(() {
          selectedClass = value;
          selectedMatiere = null;
          horaireMatiere = "";
          _loadMatieres();
          _loadStudents();
        });
      },
    );
  }

  Widget _buildSubjectDropdown() {
    return DropdownButtonFormField<String>(
      value: selectedMatiere,
      style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
      decoration: InputDecoration(
        labelText: "Matière",
        labelStyle: const TextStyle(color: Colors.white),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
        ),
        filled: true,
        fillColor: const Color.fromARGB(183, 255, 255, 255),
      ),
      items: matieres.map((matiere) {
        return DropdownMenuItem(
          value: matiere["nom"],
          child: Text(matiere["nom"]!, style: const TextStyle(color: Colors.black)),
        );
      }).toList(),
      onChanged: (value) {
        setState(() {
          selectedMatiere = value;
          horaireMatiere = matieres.firstWhere(
            (matiere) => matiere["nom"] == value)["horaire"]!;
        });
      },
    );
  }

  Widget _buildScheduleInfo() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: const Color.fromARGB(183, 28, 34, 58),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.access_time, color: Colors.white),
          const SizedBox(width: 8),
          Text(
            "Horaire: $horaireMatiere",
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStudentList() {
    if (selectedClass == null) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.group, size: 48, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              "Veuillez sélectionner une classe",
              style: TextStyle(color: Colors.grey, fontSize: 16),
            ),
          ],
        ),
      );
    }

    if (students.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              "Aucun élève trouvé dans cette classe",
              style: TextStyle(color: Colors.grey, fontSize: 16),
            ),
          ],
        ),
      );
    }

    final filteredStudents = students.where((student) {
      final searchTerm = _searchController.text.toLowerCase();
      final fullName = "${student['nom']} ${student['prenom']}".toLowerCase();
      return fullName.contains(searchTerm);
    }).toList();

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: filteredStudents.length,
      separatorBuilder: (context, index) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final student = filteredStudents[index];
        return _buildStudentCard(student);
      },
    );
  }

  Widget _buildStudentCard(Map<String, dynamic> student) {
    return Card(
      color: const Color.fromARGB(255, 51, 66, 91),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
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
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    fontSize: 16,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color.fromARGB(255, 30, 40, 63),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    student['id']!,
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            // Boutons de présence/absence
            Row(
              children: [
                Expanded(
                  child: _buildPresenceButton(student),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildAbsenceButton(student),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPresenceButton(Map<String, dynamic> student) {
    return ElevatedButton(
      onPressed: () {
        setState(() {
          student['present'] = !(student['present'] ?? false);
          if (student['present']) student['absent'] = false;
        });
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: student['present'] == true 
            ? Colors.green[400]
            : const Color.fromARGB(153, 238, 238, 238),
        foregroundColor: student['present'] == true 
            ? Colors.white 
            : Colors.black,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        padding: const EdgeInsets.symmetric(vertical: 12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            student['present'] == true 
                ? Icons.check_circle 
                : Icons.circle_outlined,
            size: 18,
          ),
          const SizedBox(width: 8),
          const Text("Présent"),
        ],
      ),
    );
  }

  Widget _buildAbsenceButton(Map<String, dynamic> student) {
    return ElevatedButton(
      onPressed: () {
        setState(() {
          student['absent'] = !(student['absent'] ?? false);
          if (student['absent']) student['present'] = false;
        });
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: student['absent'] == true 
            ? Colors.red[400]
            : const Color.fromARGB(153, 238, 238, 238),
        foregroundColor: student['absent'] == true 
            ? Colors.white 
            : Colors.black,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        padding: const EdgeInsets.symmetric(vertical: 12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            student['absent'] == true 
                ? Icons.cancel 
                : Icons.circle_outlined,
            size: 18,
          ),
          const SizedBox(width: 8),
          const Text("Absent"),
        ],
      ),
    );
  }

  Widget _buildSubmitButton() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: _envoyerListePresence,
          icon: const Icon(Icons.send, size: 20),
          label: const Text(
            "ENVOYER LES PRÉSENCES",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color.fromARGB(255, 30, 129, 175),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ),
    );
  }

  void _envoyerListePresence() async {
    if (selectedMatiere == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Veuillez sélectionner une matière"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    String jourActuel = DateFormat('EEEE', 'fr_FR').format(DateTime.now());
    int absencesEnregistrees = 0;

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
              "date": DateTime.now().toIso8601String(),
            }
          ]),
        });
        absencesEnregistrees++;
      }
    }

    // ignore: use_build_context_synchronously
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          absencesEnregistrees > 0
              ? "$absencesEnregistrees absence(s) enregistrée(s)"
              : "Aucune absence à enregistrer",
        ),
        backgroundColor: absencesEnregistrees > 0 ? Colors.green : Colors.blue,
      ),
    );
  }
}