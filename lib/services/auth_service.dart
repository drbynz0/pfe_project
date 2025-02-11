import 'package:flutter/material.dart';

class AuthService {
  static void logout(BuildContext context) {
    // Ajoute ici ta logique de déconnexion (ex: suppression des tokens, redirection...)
    Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
  }
}
