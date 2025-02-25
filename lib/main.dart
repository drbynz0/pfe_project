import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'firebase_options.dart'; // Importez ce fichier après l'avoir généré

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Gestion Scolaire',
      home: Scaffold(
        appBar: AppBar(title: const Text("Firebase Intégré 🚀")),
        body: const Center(child: Text("Firebase est prêt !")),
      ),
    );
  }
}