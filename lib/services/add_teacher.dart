import 'package:cloud_firestore/cloud_firestore.dart';

class TeacherService {
  final CollectionReference teacherCollection = FirebaseFirestore.instance.collection('Enseignants');

  Future<void> addTeacher(String identifier, String nom, String prenom, String email, String dateNaissance, String lieuNaissance) async {
    try {
      await teacherCollection.doc(identifier).set({
        'nom': nom,
        'prenom': prenom,
        'email': email,
        'date_naissance': dateNaissance,
        'lieu_naissance': lieuNaissance,
      });
    } catch (e) {
      throw Exception("Erreur lors de l'ajout de l'enseignant : ${e.toString()}");
    }
  }
}