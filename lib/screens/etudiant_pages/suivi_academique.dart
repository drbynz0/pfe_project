import 'package:flutter/material.dart';
import 'notes_page.dart';
import 'bulletin_page.dart';

class SuiviAcademique extends StatelessWidget {
  const SuiviAcademique({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Suivi Académique"),
          backgroundColor: const Color.fromARGB(255, 31, 34, 72),
          bottom: const TabBar(
            indicatorColor: Color.fromARGB(255, 45, 123, 220),
            labelColor: Colors.white,
            unselectedLabelColor: Colors.grey,
            tabs: [
              Tab(text: "Notes"),
              Tab(text: "Bulletin"),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            NotesPage(),  // Page des notes
            BulletinPage(), // Page du bulletin
          ],
        ),
      ),
    );
  }
}
