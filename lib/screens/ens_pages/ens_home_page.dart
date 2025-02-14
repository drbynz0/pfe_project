import 'package:flutter/material.dart';
import '/services/auth_service.dart';
import 'notes_page.dart';
import 'messages_page.dart';
import 'settings.dart';
import '/widgets/custom_card.dart';
//hiba
class TeacherHomePage extends StatefulWidget {
      const TeacherHomePage({super.key});
  @override
  TeacherHomePageState createState() => TeacherHomePageState();
}

class TeacherHomePageState extends State<TeacherHomePage> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    const TeacherHomePageContent(),
    const NotesPage(),
    const MessagesPage(),
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
            label: 'Notes',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.message),
            label: 'Messages',
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

class TeacherHomePageContent extends StatelessWidget {
  const TeacherHomePageContent({super.key});
  
  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: const [
        CustomCard(
          
          columns: [
            DataColumn(label: Text("Classe")),
            DataColumn(label: Text("Nombre de matières")),
          ],
          rows: [
            DataRow(cells: [
              DataCell(Text("GI")),
              DataCell(Text("5")),
            ]),
            DataRow(cells: [
              DataCell(Text("ARI")),
              DataCell(Text("4")),
            ]),
          ],
          title: "Gestion des classes et de matières",
          subtitle: "Affectation aux matières et classes",
          icon: Icons.arrow_forward,
          color: Colors.pinkAccent,
          tileColor: Color.fromARGB(0, 255, 255, 255),
          headerColor: Colors.pinkAccent,
        ),
         SizedBox(height: 16),
        CustomCard(
          columns: [
            DataColumn(label: Text("Classe")),
            DataColumn(label: Text("Nombre d'élèves")),
          ],
          rows: [
            DataRow(cells: [
              DataCell(Text("GI")),
              DataCell(Text("25")),
            ]),
            DataRow(cells: [
              DataCell(Text("ARI")),
              DataCell(Text("30")),
            ]),
          ],
          title: "Gestion des classes et des élèves",
          subtitle: "Liste des élèves par classe",
          icon: Icons.arrow_forward,
          color: Colors.lightBlueAccent,
          tileColor: Color.fromARGB(0, 255, 255, 255),
          headerColor: Colors.lightBlueAccent,
        ),
         SizedBox(height: 16),
        CustomCard(
          title: "Gestion des bulletins",
          subtitle: "Bulletin des élèves",
          icon: Icons.arrow_forward,
          color: Colors.orangeAccent,
          tileColor: Color.fromARGB(1, 25, 139, 201),
          headerColor: Colors.orangeAccent,
          columns: null,
          rows: null,
        ),
      ],
    );
  }
}