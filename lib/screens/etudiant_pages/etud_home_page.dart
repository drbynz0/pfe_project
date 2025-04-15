import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';
import '/services/auth_service.dart';
import 'messages_page.dart';
import 'settings.dart';
import 'suivi_bus.dart';
import 'suivi_academique.dart';
import 'profile_page.dart';
import 'notifications_page.dart';
import 'emploi_du_temps_page.dart';
import 'documents_utils_page.dart';

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
    final String? studentId = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 25, 35, 51),
      appBar: AppBar(
        title: const Text(
          'School App',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontFamily: 'Inter Tight',
          ),
        ),
        backgroundColor: const Color.fromARGB(255, 25, 40, 62),
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications, color: Colors.white, size: 24),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const NotificationsPage()),
              );
            },
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.account_circle, color: Colors.white, size: 30),
            offset: const Offset(0, 40),
            onSelected: (value) {
              if (value == 'profile' && studentId != null) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ProfilePage(studentId: studentId),
                  ),
                );
              } else if (value == 'logout') {
                AuthService.logout(context);
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'profile', child: Text('Voir profil')),
              const PopupMenuItem(value: 'logout', child: Text('Déconnexion')),
            ],
          ),
        ],
      ),
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Accueil'),
          BottomNavigationBarItem(icon: Icon(Icons.note), label: 'Suivi Académique'),
          BottomNavigationBarItem(icon: Icon(Icons.message), label: 'Messages'),
          BottomNavigationBarItem(icon: Icon(Icons.directions_bus), label: 'Suivi Bus'),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Settings'),
        ],
        type: BottomNavigationBarType.fixed,
        backgroundColor: const Color.fromARGB(255, 19, 20, 40),
        unselectedItemColor: const Color.fromARGB(255, 87, 99, 108),
        selectedItemColor: const Color.fromARGB(255, 255, 255, 255),
      ),
    );
  }
}

class EtudiantHomePageContent extends StatelessWidget {
  const EtudiantHomePageContent({super.key});

  void _ouvrirLienNouvelles() async {
    const String url = 'https://www.estbm.ac.ma/new/';
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url));
    } else {
      throw 'Impossible d\'ouvrir le lien $url';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildCard(
            context,
            title: "Consulter l'emploi du temps",
            icon: Icons.schedule,
            color: Colors.blue,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const EmploiDuTempsPage()),
              );
            },
          ),
          const SizedBox(height: 20),
          _buildCard(
            context,
            title: "Documents utiles",
            icon: Icons.folder,
            color: Colors.green,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const DocumentsUtilsPage()),
              );
            },
          ),
          const SizedBox(height: 20),
          _buildCard(
            context,
            title: "Voir les nouvelles",
            icon: Icons.newspaper,
            color: Colors.orange,
            onTap: _ouvrirLienNouvelles,
          ),
        ],
      ),
    );
  }

  Widget _buildCard(BuildContext context, {
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            // ignore: deprecated_member_use
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(15),
          ),
          child: Row(
            children: [
              Icon(icon, size: 40, color: color),
              const SizedBox(width: 20),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
