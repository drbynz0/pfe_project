// lib/screens/cond_pages/cond_home_page.dart

import 'package:flutter/material.dart';
import 'package:p_f_e_project/services/auth_service.dart';
import 'messages_page.dart';
import '/screens/cond_pages/settings.dart';

class CondHomePage extends StatefulWidget {
    const CondHomePage({super.key});
  @override
  CondHomePageState createState() => CondHomePageState();
}

class CondHomePageState extends State<CondHomePage> {
  int _selectedIndex = 0;
  final List<Widget> _pages = [
    const HomeScreen(),
    const MessagesPage(),
    const SuiviBusPage(),
    const SettingsPage(),
  ];

  // Liste des notifications simulées
  List<String> notifications = [];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void addNotification(String message) {
    setState(() {
      notifications.add(message);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF082E4A),
      appBar: AppBar(
        title: const Text(
          'School App',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontFamily: 'Inter Tight',
          ),
        ),
        backgroundColor: const Color(0xFF140C5F),
        actions: [
          // Icone de notification
          IconButton(
            icon: const Icon(Icons.notifications, color: Colors.white, size: 24),
            onPressed: () {
              // Afficher les notifications lorsqu'on clique dessus
              showDialog(
                context: context,
                builder: (_) => AlertDialog(
                  title: const Text('Boîte de Notifications'),
                  content: notifications.isEmpty
                      ? const Text('Aucune nouvelle notification.')
                      : SizedBox(
                          height: 200,
                          width: 300,
                          child: ListView(
                            children: notifications
                                .map((msg) => ListTile(
                                      title: Text(msg),
                                    ))
                                .toList(),
                          ),
                        ),
                  actions: [
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      child: const Text('Fermer'),
                    ),
                  ],
                ),
              );
            },
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
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.message), label: 'Messages'),
          BottomNavigationBarItem(icon: Icon(Icons.directions_bus), label: 'Suivi Bus'),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'settings'),
        ],
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
        backgroundColor: const Color.fromARGB(255, 31, 34, 72),
        unselectedItemColor: const Color.fromARGB(255, 87, 99, 108),
      ),
    );
  }
}

// Home Screen
class HomeScreen extends StatelessWidget {
    const HomeScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        'Bienvenue Conducteur',
        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
      ),
    );
  }
}

// lib/screens/cond_pages/suivi_bus.dart
class SuiviBusPage extends StatelessWidget {
    const SuiviBusPage({super.key});
  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        'Suivi des Bus',
        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
      ),
    );
  }
}
