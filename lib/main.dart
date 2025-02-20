import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart'; // Importez ce fichier après l'avoir généré
import '/utils/profile_page.dart';
import '/screens/login_page/login_page.dart';
import 'screens/ens_pages/ens_home_page.dart';
import 'screens/etudiant_pages/etud_home_page.dart';
import 'screens/cond_pages/cond_home_page.dart';
import '/services/matiere_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => MatiereService()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: Color.fromARGB(255, 31, 34, 72),
          selectedItemColor: Color.fromARGB(255, 45, 123, 220),
          unselectedItemColor: Color.fromARGB(255, 87, 99, 108),
        ),
      ),
      debugShowCheckedModeBanner: false,
      initialRoute: '/login',
      routes: {
        '/login': (context) => const LoginPage(),
        '/homeEns': (context) => const TeacherHomePage(),
        '/homeEtud': (context) => const EtudiantHomePage(),
        '/homeCond': (context) => const CondHomePage(),
        '/profile': (context) => const ProfilePage(),
      },
    );
  }
}