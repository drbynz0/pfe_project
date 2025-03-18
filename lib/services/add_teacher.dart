import 'package:cloud_firestore/cloud_firestore.dart';
class TeacherService {
  final CollectionReference teacherCollection = FirebaseFirestore.instance.collection('Enseignants');

  Future<void> addTeacher(
    String uid,
    String identifier,
    String nom,
    String prenom,
    String email,
    String dateNaissance,
    String lieuNaissance,
    Map<String, List<Map<String, dynamic>>> matieresParClasse, // Matières par classe
  ) async {
    try {
      // Ajouter les informations de base de l'enseignant
      await teacherCollection.doc(identifier).set({
        'uid': uid,
        'nom': nom,
        'prenom': prenom,
        'email': email,
        'date_naissance': dateNaissance,
        'lieu_naissance': lieuNaissance,
      });

      // Ajouter les matières par classe dans la sous-collection Matieres
      for (var entry in matieresParClasse.entries) {
        String classe = entry.key;
        List<Map<String, dynamic>> matieres = entry.value;

        // Ajouter les matières dans la sous-collection Matieres
        await teacherCollection
            .doc(identifier)
            .collection("Matieres")
            .doc(classe)
            .set({
          'matieres': matieres,
        });

        // Créer un document correspondant dans la sous-collection Notes
        await teacherCollection
            .doc(identifier)
            .collection("Notes")
            .doc(classe)
            .set({});
      }
    } catch (e) {
      throw Exception("Erreur lors de l'ajout de l'enseignant : ${e.toString()}");
    }
  }
}