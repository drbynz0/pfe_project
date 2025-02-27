import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ProfilePage extends StatelessWidget {
  final String studentId;

  const ProfilePage({super.key, required this.studentId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1E293B), // Fond sombre
      appBar: AppBar(
        title: const Text(
          'Profil',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: const Color(0xFF140C5F),
        iconTheme: const IconThemeData(color: Colors.white),
        centerTitle: true,
        elevation: 0,
      ),
      body: FutureBuilder<QuerySnapshot>(
        future: FirebaseFirestore.instance
            .collection('Etudiants')
            .where('uid', isEqualTo: studentId)
            .limit(1)
            .get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Text(
                "Aucune donnée trouvée pour $studentId",
                style: const TextStyle(color: Colors.white, fontSize: 16),
              ),
            );
          }

          var doc = snapshot.data!.docs.first;
          var data = doc.data() as Map<String, dynamic>;

          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Carte du profil avec design personnalisé
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF334155),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: 50,
                          backgroundImage: NetworkImage(data['photo_url'] ?? 'https://placeimg.com/640/480/people'), // Remplacez par l'URL de l'image
                        ),
                        const SizedBox(height: 15),
                        Text(
                          "${data['nom']} ${data['prenom']}",
                          style: const TextStyle(
                            fontSize: 24,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Text(
                          "Etudiant",
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.lightBlueAccent,
                          ),
                        ),
                        const SizedBox(height: 10),
                        _infoRow("Identifiant", doc.id),
                        _infoRow("Email", data['email']),
                        _infoRow("Date de naissance", data['date_naissance']),
                        _infoRow("Lieu de naissance", data['lieu_naissance']),
                        _infoRow("Classe", data['classe']),
                        _infoRow("Année scolaire", data['annee_scolaire']),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    "Classe & Matières :",
                    style: TextStyle(
                      fontSize: 20,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: data['classe'] != null ? 1 : 0,
                    itemBuilder: (context, index) {
                      var classe = data['classe'];

                      return FutureBuilder<DocumentSnapshot>(
                        future: FirebaseFirestore.instance.collection('Matieres').doc(classe).get(),
                        builder: (context, matieresSnapshot) {
                          if (matieresSnapshot.connectionState == ConnectionState.waiting) {
                            return const Center(child: CircularProgressIndicator());
                          }

                          if (!matieresSnapshot.hasData || !matieresSnapshot.data!.exists) {
                            return const Center(
                              child: Text(
                                "Aucune matière trouvée",
                                style: TextStyle(color: Colors.white, fontSize: 16),
                              ),
                            );
                          }

                          var matieresData = matieresSnapshot.data!.data() as Map<String, dynamic>;

                          // Filtrer les matières (en excluant des champs comme 'nom' si nécessaire)
                          List<Map<String, dynamic>> matieresList = matieresData.entries
                              .where((entry) => entry.value is Map<String, dynamic>) // On s'assure que c'est une Map
                              .map((entry) => entry.value as Map<String, dynamic>)
                              .toList();

                          return _classeCard(classe, matieresList);
                        },
                      );
                    },
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueAccent,
                      padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text(
                      'Retour',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // Function to display the information rows in a styled way
  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.white70, fontSize: 16)),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              value,
              style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  // Function to display classes and subjects as a card with buttons
  Widget _classeCard(String classe, List matieres) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            classe,
            style: const TextStyle(
              fontSize: 18,
              color: Colors.black87,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8.0,
            runSpacing: 8.0,
            children: matieres.map<Widget>((matiere) {
              return ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple, // button color
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      matiere['nom'],
                      style: const TextStyle(fontSize: 14, color: Colors.white),
                    ),
                    Text(
                      matiere['prof'],
                      style: const TextStyle(fontSize: 12, color: Colors.white70),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}