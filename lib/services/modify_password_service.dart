import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

Future<void> showModifyPasswordDialog(BuildContext context) async {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController currentPasswordController = TextEditingController();
  final User? currentUser = FirebaseAuth.instance.currentUser;

  showDialog(
    context: context,
    builder: (context) {
      return Theme(
        data: ThemeData.dark(), // Appliquer un thème sombre
        child: AlertDialog(
          title: const Text("Réinitialiser le mot de passe"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text("Entrez votre adresse email et votre mot de passe actuel pour recevoir un lien de réinitialisation de mot de passe."),
              const SizedBox(height: 10),
              TextField(
                controller: emailController,
                decoration: const InputDecoration(
                  labelText: "Email",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: currentPasswordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: "Mot de passe actuel",
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Annuler"),
            ),
            ElevatedButton(
              onPressed: () async {
                if (emailController.text != currentUser?.email) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("L'email ne correspond pas à votre email."),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }

                bool isPasswordCorrect = await _verifyCurrentPassword(currentPasswordController.text);
                if (isPasswordCorrect) {
                  // ignore: use_build_context_synchronously
                  await _sendPasswordResetEmail(context, emailController.text);
                  // ignore: use_build_context_synchronously
                  Navigator.pop(context);
                } else {
                  // ignore: use_build_context_synchronously
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Mot de passe actuel incorrect."),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              child: const Text("Envoyer"),
            ),
          ],
        ),
      );
    },
  );
}

Future<bool> _verifyCurrentPassword(String currentPassword) async {
  User? user = FirebaseAuth.instance.currentUser;
  if (user == null) return false;

  AuthCredential credential = EmailAuthProvider.credential(
    email: user.email!,
    password: currentPassword,
  );

  try {
    await user.reauthenticateWithCredential(credential);
    return true;
  } catch (e) {
    return false;
  }
}

Future<void> _sendPasswordResetEmail(BuildContext context, String email) async {
  try {
    await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
    // ignore: use_build_context_synchronously
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Email de réinitialisation envoyé."),
        backgroundColor: Colors.green, // Couleur de fond verte
      ),
    );
  } catch (e) {
    // ignore: use_build_context_synchronously
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Erreur: ${e.toString()}"),
        backgroundColor: Colors.red, // Couleur de fond rouge pour les erreurs
      ),
    );
  }
}