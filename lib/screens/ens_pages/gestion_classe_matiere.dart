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
  final TextEditingController _searchController = TextEditingController();

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
      backgroundColor: const Color.fromARGB(255, 25, 35, 51),
      appBar: AppBar(
        title: const Text(
          "Gestion des Matières",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        backgroundColor: const Color.fromARGB(255, 25, 40, 62),
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: Column(
        children: [
          // Section de filtrage
          _buildFilterSection(),
          
          // Liste des matières
          Expanded(
            child: _buildSubjectList(),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 33, 44, 71),
        boxShadow: [
          BoxShadow(
            // ignore: deprecated_member_use
            color: Colors.grey.withOpacity(0.1),
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
              hintText: "Rechercher une matière...",
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
          
          // Sélecteur de classe
          _buildClassDropdown(),
        ],
      ),
    );
  }

  Widget _buildClassDropdown() {
    return DropdownButtonFormField<String>(
      value: selectedClass,
      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      decoration: InputDecoration(
        labelText: "Classe",
        labelStyle: const TextStyle(color: Color.fromARGB(255, 71, 25, 25)),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
        ),
        filled: true,
        fillColor: const Color.fromARGB(183, 255, 255, 255),
      ),
      items: classNames.map((className) {
        return DropdownMenuItem(
          value: className,
          child: Text(
            className,
            style: const TextStyle(fontSize: 16, color: Colors.black87),
          ),
        );
      }).toList(),
      onChanged: (value) {
        setState(() {
          selectedClass = value;
        });
      },
    );
  }

  Widget _buildSubjectList() {
    if (teacherDocId == null || selectedClass == null) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.book, size: 48, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              "Chargement des matières...",
              style: TextStyle(color: Colors.grey, fontSize: 16),
            ),
          ],
        ),
      );
    }

    return FutureBuilder<DocumentSnapshot>(
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
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 48, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  "Aucune matière trouvée pour cette classe",
                  style: TextStyle(color: Colors.grey, fontSize: 16),
                ),
              ],
            ),
          );
        }

        var matieres = List<Map<String, dynamic>>.from(snapshot.data!['matieres']);
        final filteredMatieres = matieres.where((matiere) {
          final searchTerm = _searchController.text.toLowerCase();
          final matiereName = matiere['nom'].toString().toLowerCase();
          return matiereName.contains(searchTerm);
        }).toList();

        if (filteredMatieres.isEmpty) {
          return const Center(
            child: Text(
              "Aucune matière ne correspond à votre recherche",
              style: TextStyle(color: Colors.grey, fontSize: 16),
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: filteredMatieres.length,
          separatorBuilder: (context, index) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final matiere = filteredMatieres[index];
            return _buildSubjectCard(matiere);
          },
        );
      },
    );
  }

  Widget _buildSubjectCard(Map<String, dynamic> matiere) {
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
            // Nom de la matière
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  matiere['nom'] ?? "Nom inconnu",
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: Colors.white,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color.fromARGB(255, 30, 40, 63),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    "Coef: ${matiere['coef']?.toString() ?? "N/A"}",
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            // Détails
            Row(
              children: [
                _buildDetailItem(Icons.calendar_today, matiere['jour'] ?? "N/A"),
                const SizedBox(width: 16),
                _buildDetailItem(Icons.access_time, matiere['horaire'] ?? "N/A"),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailItem(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 18, color: Colors.white),
        const SizedBox(width: 4),
        Text(
          text,
          style: TextStyle(
            color: Colors.white,
            fontSize: 14,
          ),
        ),
      ],
    );
  }
}