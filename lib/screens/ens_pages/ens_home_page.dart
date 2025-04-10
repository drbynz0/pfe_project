import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '/services/auth_service.dart';
import 'notes_page.dart';
import 'messages_page.dart';
import 'settings.dart';
import '/widgets/custom_card.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '/providers/locale_provider.dart';
import '/generated/l10n.dart';
import 'profile_page.dart';
import 'notifications_page.dart';

class TeacherHomePage extends StatefulWidget {
  const TeacherHomePage({super.key});

  @override
  TeacherHomePageState createState() => TeacherHomePageState();
}

class TeacherHomePageState extends State<TeacherHomePage> {
  int _selectedIndex = 0;
  String? currentUserId;

  final List<Widget> _pages = [];

  @override
  void initState() {
    super.initState();
    _getCurrentUserId();
  }

  Future<void> _getCurrentUserId() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      String uid = user.uid;
      QuerySnapshot userSnapshot = await FirebaseFirestore.instance
          .collection('Users')
          .where('uid', isEqualTo: uid)
          .limit(1)
          .get();

      if (userSnapshot.docs.isNotEmpty) {
        setState(() {
          currentUserId = userSnapshot.docs.first.id;
          _pages.addAll([
            TeacherHomePageContent(teacherId: currentUserId),
            const NotesPage(),
            const MessagesPage(),
            SettingsPage(onLocaleChange: (locale) {
              Provider.of<LocaleProvider>(context, listen: false).setLocale(locale);
            }),
          ]);
        });
      }
    }
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
              if (value == 'profile') {
                // Rediriger vers la page de profil
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ProfilePage(teacherId: teacherId!),
                  ),
                );
              } else if (value == 'logout') {
                _showLogoutDialog(context);
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
      body: _pages.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : _pages[_selectedIndex],
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
  final String? teacherId;

  const TeacherHomePageContent({super.key, required this.teacherId});

  Future<Map<String, int>> _getStudentCounts(List<String> classNames) async {
    Map<String, int> studentCounts = {};
    QuerySnapshot studentSnapshot = await FirebaseFirestore.instance.collection('Etudiants').get();

    for (var student in studentSnapshot.docs) {
      String studentClass = student['classe'];
      if (classNames.contains(studentClass)) {
        if (studentCounts.containsKey(studentClass)) {
          studentCounts[studentClass] = studentCounts[studentClass]! + 1;
        } else {
          studentCounts[studentClass] = 1;
        }
      }
    }

    return studentCounts;
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('Enseignants').doc(teacherId).collection('Matieres').snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return const Center(child: Text("Aucune classe trouvée"));
            }

            var classes = snapshot.data!.docs;
            List<String> classNames = classes.map((doc) => doc.id).toList();

            return FutureBuilder<Map<String, int>>(
              future: _getStudentCounts(classNames),
              builder: (context, studentCountSnapshot) {
                if (studentCountSnapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!studentCountSnapshot.hasData) {
                  return const Center(child: Text("Erreur de chargement des étudiants"));
                }

                return CustomCard(
                  columns: [
                    DataColumn(label: Text(S.of(context).classLabel)), // Utilisez les traductions ici
                    DataColumn(label: Text(S.of(context).numberOfSubjects)), // Utilisez les traductions ici
                  ],
                  rows: classes.map((doc) {
                    var className = doc.id;
                    var numberOfSubjects = (doc['matieres'] as List).length;

                    return DataRow(cells: [
                      DataCell(Text(className)),
                      DataCell(Text(numberOfSubjects.toString())),
                    ]);
                  }).toList(),                 
                  title: S.of(context).classManagement,
                  subtitle: S.of(context).classAndStudentManagement,
                  indice: 'ClasseMatieres', // Utilisez les traductions ici
                  icon: Icons.arrow_forward,
                  color: Colors.pinkAccent,
                  tileColor: const Color.fromARGB(0, 255, 255, 255),
                  headerColor: Colors.pinkAccent,
                );
              },
            );
          },
        ),
        const SizedBox(height: 16),
        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('Enseignants').doc(teacherId).collection('Matieres').snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return const Center(child: Text("Aucune classe trouvée"));
            }

            var classes = snapshot.data!.docs;
            List<String> classNames = classes.map((doc) => doc.id).toList();

            return FutureBuilder<Map<String, int>>(
              future: _getStudentCounts(classNames),
              builder: (context, studentCountSnapshot) {
                if (studentCountSnapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!studentCountSnapshot.hasData) {
                  return const Center(child: Text("Erreur de chargement des étudiants"));
                }

                var studentCounts = studentCountSnapshot.data!;

                return CustomCard(
                  columns: [
                    DataColumn(label: Text(S.of(context).classLabel)), // Utilisez les traductions ici
                    DataColumn(label: Text(S.of(context).numberOfStudents)), // Utilisez les traductions ici
                  ],
                  rows: classes.map((doc) {
                    var className = doc.id;
                    var numberOfStudents = studentCounts[className] ?? 0;

                    return DataRow(cells: [
                      DataCell(Text(className)),
                      DataCell(Text(numberOfStudents.toString())),
                    ]);
                  }).toList(),
                  title: S.of(context).classAndStudentManagement, // Utilisez les traductions ici
                  subtitle: S.of(context).studentListByClass,
                  indice: 'ClasseEleves', // Utilisez les traductions ici
                  icon: Icons.arrow_forward,
                  color: Colors.lightBlueAccent,
                  tileColor: const Color.fromARGB(0, 255, 255, 255),
                  headerColor: Colors.lightBlueAccent,
                );
              },
            );
          },
        ),
        const SizedBox(height: 16),
        CustomCard(
          title: S.of(context).bulletinManagement, // Utilisez les traductions ici
          subtitle: S.of(context).studentBulletin,
          indice: 'bulletins',
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

void _showLogoutDialog(BuildContext context) {
  showDialog(
    context: context,
    builder: (context) {
      return Theme(
        data: ThemeData.dark().copyWith(
          textTheme: const TextTheme(
            bodyLarge: TextStyle(color: Colors.white),
            bodyMedium: TextStyle(color: Colors.white),
          ),
          iconTheme: const IconThemeData(color: Colors.white),
          cardColor: const Color.fromARGB(255, 47, 48, 81), dialogTheme: DialogThemeData(backgroundColor: const Color.fromARGB(255, 35, 43, 77)),
        ),
        child: AlertDialog(
          title: Text(S.of(context).logout, style: TextStyle(color: Colors.white)),
          content: const Text("Voulez-vous vraiment vous déconnecter ?", style: TextStyle(color: Colors.white),),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Annuler"),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color.fromARGB(255, 35, 31, 65),
              ),
              onPressed: () async {
                AuthService.logout(context);
              },
              child: Text(S.of(context).logout),
            ),
          ],
        ),
      );   
    }
  );
}

