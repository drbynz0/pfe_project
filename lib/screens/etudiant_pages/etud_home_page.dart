import 'package:flutter/material.dart';
import 'notes_page.dart';
import 'messages_page.dart';
import 'settings.dart';
import 'suivi_bus.dart';

class EtudiantHomePage extends StatefulWidget {
  const EtudiantHomePage({super.key});
  @override
  EtudiantHomePageState createState() => EtudiantHomePageState();
}

class EtudiantHomePageState extends State<EtudiantHomePage> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    const EtudiantHomePageContent(),
    const NotesPage(),
    const MessagesPage(),
    const SettingsPage(),
    const SuiviBusPage(),
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
          IconButton(
            icon: const Icon(Icons.account_circle, color: Colors.white, size: 30),
            onPressed: () {},
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
            label: 'Notes',
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