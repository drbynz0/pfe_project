import 'package:flutter/material.dart';
import '/screens/login_page/login_page.dart';
import 'screens/ens_pages/ens_home_page.dart';
void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
    const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      initialRoute: '/login', // Définit l'écran de démarrage
      routes: {
        '/login': (context) => const LoginPage(),
        '/home': (context) => const TeacherHomePage(),
      },
    );
  }
}