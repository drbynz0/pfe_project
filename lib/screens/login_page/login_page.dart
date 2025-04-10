import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '/services/auth_service.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  LoginPageState createState() => LoginPageState();
}

class LoginPageState extends State<LoginPage> {
  final TextEditingController _idController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isPasswordVisible = false;
  bool _isLoading = false;

  Future<void> _login() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
    });

    String identifiant = _idController.text.trim();

    try {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection("Users").doc(identifiant).get();

      if (userDoc.exists) {
        String email = userDoc.get("email");

        if (!_isEmailValid(email)) {
          showErrorDialog("Veuillez saisir un email valide.");
          setState(() {
            _isLoading = false;
          });
          return;
        }

        UserCredential userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: email,
          password: _passwordController.text,
        );

        User? user = userCredential.user;
        if (user != null && !user.emailVerified) {
          await FirebaseAuth.instance.signOut();
          showErrorDialog("Veuillez vérifier votre email avant de vous connecter.");
          setState(() {
            _isLoading = false;
          });
          return;
        }
        // ignore: use_build_context_synchronously
        AuthService.login(context, userDoc, identifiant, _isLoading, _idController);
        await AuthService.createSession(identifiant);
        // Récupérer le rôle dans Firestore
      } else {
        showErrorDialog("Utilisateur non trouvé");
      }
    } on FirebaseAuthException catch (e) {
      showErrorDialog(e.message ?? 'Erreur de connexion');
    } finally {
      // ignore: control_flow_in_finally
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
    }
  }

  bool _isEmailValid(String email) {
    final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
    return emailRegex.hasMatch(email);
  }

  // Fonction pour afficher une boîte de dialogue en cas d'erreur
  void showErrorDialog(String message) {
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
                      "School App",
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
                            "Bienvenue",
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            "Connectez-vous à l'aide de vos identifiants.",
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[700],
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 20),
                          TextField(
                            controller: _idController,
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
                            controller: _passwordController,
                            decoration: InputDecoration(
                              hintText: "Mot de passe",
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
                          _isLoading
                              ? const CircularProgressIndicator()
                              : ElevatedButton(
                                  onPressed: _login,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF4B2DFD),
                                    minimumSize: const Size(double.infinity, 50),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                  child: const Text(
                                    "Se connecter",
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                          const SizedBox(height: 10),
                          TextButton(
                            onPressed: () {
                              Navigator.pushReplacementNamed(context, '/resetPwd');
                            },
                            child: const Text(
                              "Mot de passe oublié.",
                              style: TextStyle(color: Color(0xFF4B2DFD)),
                            ),
                          ),
                          const SizedBox(height: 10), // Ajout d'un espace entre les boutons
                          TextButton(
                            onPressed: () {
                              // Logique pour naviguer vers la page d'inscription
                              Navigator.pushNamed(context, '/signup');
                            },
                            child: const Text(
                              "S'inscrire",
                              style: TextStyle(color: Color(0xFF4B2DFD)),
                            ),
                          ),
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