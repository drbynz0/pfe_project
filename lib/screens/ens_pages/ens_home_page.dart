import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '/services/auth_service.dart';
import 'notes_page.dart';
import 'messages_page.dart';
import 'settings.dart';
import '/widgets/custom_card.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '/providers/locale_provider.dart';
import '/generated/l10n.dart';

class TeacherHomePage extends StatefulWidget {
  const TeacherHomePage({super.key});

  @override
  TeacherHomePageState createState() => TeacherHomePageState();
}

class TeacherHomePageState extends State<TeacherHomePage> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [];

  @override
  void initState() {
    super.initState();
    _pages.addAll([
      const TeacherHomePageContent(),
      const NotesPage(),
      const MessagesPage(),
      SettingsPage(onLocaleChange: (locale) {
        Provider.of<LocaleProvider>(context, listen: false).setLocale(locale);
      }),
    ]);
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final String? teacherId = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      backgroundColor: const Color(0xFF082E4A),
      appBar: AppBar(
        title: Text(
          S.of(context).appTitle, // Utilisez les traductions ici
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontFamily: 'Inter Tight'),
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
                Navigator.pushNamed(
                  context,
                  '/profile',
                  arguments: {'teacherId': teacherId}, // Utilisez teacherId ici
                );
              } else if (value == 'logout') {
                AuthService.logout(context);
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'profile',
                child: Text(S.of(context).profile), // Utilisez les traductions ici
              ),
              PopupMenuItem(
                value: 'logout',
                child: Text(S.of(context).logout), // Utilisez les traductions ici
              ),
            ],
          ),
        ],
      ),
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        items: [
          BottomNavigationBarItem(
            icon: const Icon(Icons.home),
            label: S.of(context).home, // Utilisez les traductions ici
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.note),
            label: S.of(context).notes, // Utilisez les traductions ici
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.message),
            label: S.of(context).messages, // Utilisez les traductions ici
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.settings),
            label: S.of(context).settings, // Utilisez les traductions ici
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
      children: [
        CustomCard(
          columns: [
            DataColumn(label: Text(S.of(context).classLabel)), // Utilisez les traductions ici
            DataColumn(label: Text(S.of(context).numberOfSubjects)), // Utilisez les traductions ici
          ],
          rows: const [
            DataRow(cells: [
              DataCell(Text("GI")),
              DataCell(Text("5")),
            ]),
            DataRow(cells: [
              DataCell(Text("ARI")),
              DataCell(Text("4")),
            ]),
          ],
          title: S.of(context).classManagement, // Utilisez les traductions ici
          subtitle: S.of(context).classAndStudentManagement, // Utilisez les traductions ici
          icon: Icons.arrow_forward,
          color: Colors.pinkAccent,
          tileColor: const Color.fromARGB(0, 255, 255, 255),
          headerColor: Colors.pinkAccent,
        ),
        const SizedBox(height: 16),
        CustomCard(
          columns: [
            DataColumn(label: Text(S.of(context).classLabel)), // Utilisez les traductions ici
            DataColumn(label: Text(S.of(context).numberOfStudents)), // Utilisez les traductions ici
          ],
          rows: const [
            DataRow(cells: [
              DataCell(Text("GI")),
              DataCell(Text("25")),
            ]),
            DataRow(cells: [
              DataCell(Text("ARI")),
              DataCell(Text("30")),
            ]),
          ],
          title: S.of(context).classAndStudentManagement, // Utilisez les traductions ici
          subtitle: S.of(context).studentListByClass, // Utilisez les traductions ici
          icon: Icons.arrow_forward,
          color: Colors.lightBlueAccent,
          tileColor: const Color.fromARGB(0, 255, 255, 255),
          headerColor: Colors.lightBlueAccent,
        ),
        const SizedBox(height: 16),
        CustomCard(
          title: S.of(context).bulletinManagement, // Utilisez les traductions ici
          subtitle: S.of(context).studentBulletin, // Utilisez les traductions ici
          icon: Icons.arrow_forward,
          color: Colors.orangeAccent,
          tileColor: const Color.fromARGB(1, 25, 139, 201),
          headerColor: Colors.orangeAccent,
          columns: null,
          rows: null,
        ),
      ],
    );
  }
}