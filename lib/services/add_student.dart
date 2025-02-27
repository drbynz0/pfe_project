import 'package:cloud_firestore/cloud_firestore.dart';

class StudentService {
  final CollectionReference studentCollection = FirebaseFirestore.instance.collection('Etudiants');

  Future<void> addStudent(String uid, String identifier, String nom, String prenom, String email, String dateNaissance, String lieuNaissance, String classe) async {
    try {
      await studentCollection.doc(identifier).set({
        'uid': uid,
        'nom': nom,
        'prenom': prenom,
        'email': email,
        'date_naissance': dateNaissance,
        'lieu_naissance': lieuNaissance,
        'classe': classe,
      });
    } catch (e) {
      throw Exception("Erreur lors de l'ajout de l'enseignant : ${e.toString()}");
    }
  }
}