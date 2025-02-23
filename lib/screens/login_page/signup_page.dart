import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '/services/add_teacher.dart';

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  SignupPageState createState() => SignupPageState();
}

class SignupPageState extends State<SignupPage> {
  final TextEditingController _identifierController = TextEditingController();
  final TextEditingController _provisionalPasswordController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();

  bool _isVerified = false;
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  bool _isLoading = false;

  void _verifyIdentifier() async {
    String identifier = _identifierController.text.trim();
    String provisionalPassword = _provisionalPasswordController.text.trim();

    try {
      var userDoc = await FirebaseFirestore.instance.collection("Users").doc(identifier).get();
      if (userDoc.exists && userDoc.data()?['provisional_password'] == provisionalPassword) {
        setState(() {
          _emailController.text = userDoc.data()?['email'];
          _isVerified = true;
        });
      } else {
        _showErrorDialog("Identifiant ou mot de passe provisoire incorrect.");
      }
    } catch (e) {
      _showErrorDialog("Erreur lors de la vérification : ${e.toString()}");
    }
  }

  void _createAccount() async {
    if (_passwordController.text != _confirmPasswordController.text) {
      _showErrorDialog("Les mots de passe ne correspondent pas");
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      UserCredential userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      String identifier = _identifierController.text.trim();
      await FirebaseFirestore.instance.collection("Users").doc(identifier).update({
        "uid": userCredential.user!.uid,
        "is_registered": true,
        "provisional_password": FieldValue.delete(),
      });

      // Vérifier le type d'utilisateur et ajouter l'enseignant à la collection Enseignant
      var userDoc = await FirebaseFirestore.instance.collection("Users").doc(identifier).get();
      if (userDoc.exists && userDoc.data()?['type'] == 'enseignant') {
        String nom = userDoc.data()?['nom'];
        String prenom = userDoc.data()?['prenom'];
        String email = userDoc.data()?['email'];

        TeacherService teacherService = TeacherService();
        await teacherService.addTeacher(identifier, nom, prenom, email);
      }

      await userCredential.user!.sendEmailVerification();

      _showSuccessDialog("Compte créé ! Un email de confirmation a été envoyé.", true);
    } catch (e) {
      _showErrorDialog("Erreur : ${e.toString()}");
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.error, color: Colors.red),
            SizedBox(width: 10),
            Text('Erreur'),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showSuccessDialog(String message, bool redirectToLogin) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green),
            SizedBox(width: 10),
            Text('Succès'),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              if (redirectToLogin) {
                Navigator.pushReplacementNamed(context, '/login');
              }
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color.fromARGB(255, 20, 12, 95),
                Color.fromARGB(255, 206, 44, 204),
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: Center(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Text(
                      "App School",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 40),
                    Container(
                      width: double.infinity,
                      constraints: const BoxConstraints(
                        maxWidth: 570.0,
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Column(
                        children: [
                          const Text(
                            "Inscription",
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 10),
                          if (!_isVerified) ...[
                            Text(
                              "Veuillez vérifier votre identifiant et mot de passe provisoire fournis par l'administrateur.",
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[700],
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 20),
                            TextField(
                              controller: _identifierController,
                              decoration: InputDecoration(
                                hintText: "Identifiant",
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                filled: true,
                                fillColor: Colors.grey[200],
                              ),
                            ),
                            const SizedBox(height: 15),
                            TextField(
                              obscureText: !_isPasswordVisible,
                              controller: _provisionalPasswordController,
                              decoration: InputDecoration(
                                hintText: "Mot de passe provisoire",
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                filled: true,
                                fillColor: Colors.grey[200],
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _isPasswordVisible = !_isPasswordVisible;
                                    });
                                  },
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),
                            ElevatedButton(
                              onPressed: _verifyIdentifier,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF4B2DFD),
                                minimumSize: const Size(double.infinity, 50),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              child: const Text(
                                "Vérifier l'identifiant",
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ] else ...[
                            Text(
                              "Identifiant vérifié. Veuillez créer votre compte.",
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[700],
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 20),
                            TextField(
                              controller: _emailController,
                              decoration: InputDecoration(
                                hintText: "Email",
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                filled: true,
                                fillColor: Colors.grey[200],
                              ),
                              enabled: false,
                            ),
                            const SizedBox(height: 15),
                            TextField(
                              obscureText: !_isPasswordVisible,
                              controller: _passwordController,
                              decoration: InputDecoration(
                                hintText: "Nouveau mot de passe",
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                filled: true,
                                fillColor: Colors.grey[200],
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _isPasswordVisible = !_isPasswordVisible;
                                    });
                                  },
                                ),
                              ),
                            ),
                            const SizedBox(height: 15),
                            TextField(
                              obscureText: !_isConfirmPasswordVisible,
                              controller: _confirmPasswordController,
                              decoration: InputDecoration(
                                hintText: "Confirmer le mot de passe",
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                filled: true,
                                fillColor: Colors.grey[200],
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _isConfirmPasswordVisible ? Icons.visibility : Icons.visibility_off,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _isConfirmPasswordVisible = !_isConfirmPasswordVisible;
                                    });
                                  },
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),
                            _isLoading
                                ? const CircularProgressIndicator()
                                : ElevatedButton(
                                    onPressed: _createAccount,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF4B2DFD),
                                      minimumSize: const Size(double.infinity, 50),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                    ),
                                    child: const Text(
                                      "Créer un compte",
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}