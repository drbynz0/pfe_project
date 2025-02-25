import 'package:flutter/material.dart';

class MatiereService extends ChangeNotifier {
  // Stockage des matières avec leurs détails pour chaque classe
  final Map<String, List<Map<String, dynamic>>> _matieresParClasse = {
    "GI": [
      {"matiere": "Programmation Mobile", "coefficient": 3, "jours": "Lundi, Mercredi", "horaire": "08:00 - 10:00"},
      {"matiere": "Base de Données", "coefficient": 4, "jours": "Mardi, Jeudi", "horaire": "14:00 - 16:00"},
      {"matiere": "Algorithmes", "coefficient": 2, "jours": "Vendredi", "horaire": "10:00 - 12:00"},
    ],
    "ARI": [
      {"matiere": "Administration Réseau", "coefficient": 3, "jours": "Lundi, Jeudi", "horaire": "09:00 - 11:00"},
      {"matiere": "Sécurité Informatique", "coefficient": 4, "jours": "Mardi, Mercredi", "horaire": "13:00 - 15:00"},
      {"matiere": "Virtualisation", "coefficient": 2, "jours": "Vendredi", "horaire": "15:00 - 17:00"},
    ],
  };

  // Récupérer les matières d'une classe
  List<Map<String, dynamic>> getMatieres(String classe) {
    return _matieresParClasse[classe] ?? [];
  }

  // Ajouter une nouvelle matière
  void ajouterMatiere(String classe, Map<String, dynamic> matiere) {
    _matieresParClasse[classe] ??= [];
    _matieresParClasse[classe]!.add(matiere);
    notifyListeners();
  }

  // Supprimer une matière
  void supprimerMatiere(String classe, String matiere) {
    _matieresParClasse[classe]?.removeWhere((m) => m["matiere"] == matiere);
    notifyListeners();
  }
}
