import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: const Color(0xFF1A1462), // Couleur principale
        scaffoldBackgroundColor: const Color(0xFF0A1B2A), // Fond de l'application
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF1A1462),
          foregroundColor: Colors.white,
        ),
      ),
      home: const ParentHomePage(),
      routes: {
        '/homePar': (context) => const ParentHomePage(),
        '/messages': (context) => const MessagesPage(),
        '/busTracking': (context) => const BusTrackingPage(),
        '/settings': (context) => const SettingsPage(),
      },
    );
  }
}

// 🔹 PAGE D'ACCUEIL PARENT
class ParentHomePage extends StatelessWidget {
  const ParentHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: customAppBar(),
      body:const Center(
        child: Text(
          "Page d'accueil du parent",
          style: TextStyle(color: Colors.white70, fontSize: 18),
        ),
      ),
      bottomNavigationBar: const ParentNavBar(),
    );
  }
}

// 🔹 PAGE MESSAGES
class MessagesPage extends StatefulWidget {
  const MessagesPage({super.key}); 

  Widget build(BuildContext context) {
    return Scaffold(
      appBar: customAppBar(),
      body:const Center(
        child: Text(
          "Messagerie Parent",
          style: TextStyle(color: Colors.white70, fontSize: 18),
        ),
      ),
      bottomNavigationBar: const ParentNavBar(),
    );
  }
  
  @override
  // ignore: no_logic_in_create_state
  State<StatefulWidget> createState() {
  
    throw UnimplementedError();
  }
}

// 🔹 PAGE SUIVI DU BUS
class BusTrackingPage extends StatelessWidget {
  const BusTrackingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: customAppBar(),
      body: const Center(
        child: Text(
          "Suivi du Bus",
          style: TextStyle(color: Colors.white70, fontSize: 18),
        ),
      ),
      bottomNavigationBar: const ParentNavBar(),
    );
  }
}

// 🔹 PAGE PARAMÈTRES
class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: customAppBar(),
      body: const Center(
        child: Text(
          "Paramètres du compte",
          style: TextStyle(color: Colors.white70, fontSize: 18),
        ),
      ),
      bottomNavigationBar: const ParentNavBar(),
    );
  }
}


class ParentNavBar extends StatelessWidget {
  const ParentNavBar({super.key});

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      backgroundColor:const Color(0xFF1A1462),
      selectedItemColor: Colors.blueAccent,
      unselectedItemColor: Colors.white70,
      onTap: (index) {
        switch (index) {
          case 0:
            Navigator.pushReplacementNamed(context, '/homePar');
            break;
          case 1:
            Navigator.pushReplacementNamed(context, '/messages');
            break;
          case 2:
            Navigator.pushReplacementNamed(context, '/busTracking');
            break;
          case 3:
            Navigator.pushReplacementNamed(context, '/settings');
            break;
        }
      },
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
        BottomNavigationBarItem(icon: Icon(Icons.message), label: 'Messages'),
        BottomNavigationBarItem(icon: Icon(Icons.directions_bus), label: 'Suivi Bus'),
        BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Settings'),
      ],
    );
  }
}

// 🔹 BARRE D'APPLICATION PERSONNALISÉE
PreferredSizeWidget customAppBar() {
  return AppBar(
    backgroundColor:const Color(0xFF1A1462),
    title: const Text(
      'School App',
      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
    ),
    actions: [
      IconButton(
        icon: const Icon(Icons.notifications),
        onPressed: () {},
      ),
      IconButton(
        icon: const Icon(Icons.account_circle),
        onPressed: () {},
      ),
    ],
  );
}
