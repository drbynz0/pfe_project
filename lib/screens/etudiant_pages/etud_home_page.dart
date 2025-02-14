import 'package:flutter/material.dart';
import '/services/auth_service.dart';
import 'messages_page.dart';
import 'settings.dart';
import 'suivi_bus.dart';
<<<<<<< HEAD
import 'suivi_academique.dart';
//hiba
=======
//ikram
>>>>>>> origin/branchikram
class EtudiantHomePage extends StatefulWidget {
  const EtudiantHomePage({super.key});
  @override
  EtudiantHomePageState createState() => EtudiantHomePageState();
}

class EtudiantHomePageState extends State<EtudiantHomePage> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    const EtudiantHomePageContent(),
    const SuiviAcademique(),
    const MessagesPage(),
    const SuiviBusPage(),
    const SettingsPage(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF082E4A),
      appBar: AppBar(
        title: const Text(
          'App School',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontFamily: 'Inter Tight'),
        ),
        backgroundColor: const Color(0xFF140C5F),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications, color: Colors.white, size: 24),
            onPressed: () {},
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.account_circle, color: Colors.white, size: 30),
            offset: const Offset(0, 40),
            onSelected: (value) {
              if (value == 'profile') {
                // Rediriger vers la page de profil
                Navigator.pushNamed(context, '/profile');
              } else if (value == 'logout') {
                AuthService.logout(context);
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'profile',
                child: Text('Voir profil'),
              ),
              const PopupMenuItem(
                value: 'logout',
                child: Text('Déconnexion'),
              ),
            ],
          ),
        ],
      ),
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.note),
            label: 'Suivi Academique',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.message),
            label: 'Messages',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.directions_bus),
            label: 'Suivi Bus',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
        type: BottomNavigationBarType.fixed,
        backgroundColor: const Color.fromARGB(255, 31, 34, 72),
        selectedItemColor: const Color.fromARGB(255, 45, 123, 220),
        unselectedItemColor: const Color.fromARGB(255, 87, 99, 108),      
      ),
    );
  }
}

class EtudiantHomePageContent extends StatelessWidget {
  const EtudiantHomePageContent({super.key});
  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        'Page d\'accueil de l\'étudiant',
        style: TextStyle(fontSize: 24),
      ),
    );
  }
}