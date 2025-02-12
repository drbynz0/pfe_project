import 'package:flutter/material.dart';

class NotesPage extends StatefulWidget {
        const NotesPage({super.key});
  @override
  NotesPageState createState() => NotesPageState();
}

class NotesPageState extends State<NotesPage> {
  String selectedClass = "GI";
  TextEditingController searchController = TextEditingController();
  List<Map<String, String>> students = [
    {"name": "Ali Mohamed", "id": "GI001"},
    {"name": "Fatima Ahmed", "id": "GI002"},
    {"name": "Omar Said", "id": "GI003"},
    {"name": "Youssouf Ali", "id": "ARI001"},
    {"name": "Amina Salim", "id": "ARI002"},
  ];

  @override
  Widget build(BuildContext context) {
    List<Map<String, String>> filteredStudents = students
        .where((student) =>
            student["name"]!.toLowerCase().contains(searchController.text.toLowerCase()) &&
            student["id"]!.startsWith(selectedClass))
        .toList();

    return Scaffold(
        backgroundColor: const Color(0xFF082E4A),
      appBar: AppBar(
        title: const Text('Saisie des notes',
            style: TextStyle(color: Colors.white, fontFamily: 'Inter Tight')),
            backgroundColor: const Color(0xFF140C5F),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Menu des classes
          Container(
            color: Colors.blue[50],
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildClassButton("GI"),
                const SizedBox(width: 8),
                _buildClassButton("ARI"),
              ],
            ),
          ),
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              "Liste des élèves",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
            ),
          ),
          // Barre de recherche
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              controller: searchController,
              decoration: InputDecoration(
                labelText: "Rechercher un élève",
                labelStyle: const TextStyle(color: Colors.white),
                hintStyle: const TextStyle(color: Colors.white),
                border: OutlineInputBorder(
                  borderSide: const BorderSide(color: Colors.white),
                  borderRadius: BorderRadius.circular(20),
                ),
                prefixIcon: const Icon(Icons.search, color: Colors.white),
              ),
              style: const TextStyle(color: Colors.white),
              onChanged: (value) {
                setState(() {});
              },
            ),
          ),
          // Liste des élèves
          Expanded(
            child: ListView.builder(
              itemCount: filteredStudents.length,
              itemBuilder: (context, index) {
                final student = filteredStudents[index];
                return Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: ListTile(
                    leading: const CircleAvatar(
                      backgroundColor: Colors.blue,
                      child:  Icon(Icons.person, color: Colors.white),
                    ),
                    title: Text(
                      student["name"]!,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(student["id"]!),
                    trailing: const Icon(Icons.arrow_forward),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => NoteEntryPage(student: student),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClassButton(String className) {
    return ElevatedButton(
      onPressed: () {
        setState(() {
          selectedClass = className;
        });
      },
      style: ElevatedButton.styleFrom(
        backgroundColor:
            selectedClass == className ? Colors.blue : Colors.grey[300],
        foregroundColor:
            selectedClass == className ? Colors.white : Colors.black,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
      child: Text(className),
    );
  }
}

class NoteEntryPage extends StatelessWidget {
  final Map<String, String> student;

const NoteEntryPage({required this.student, super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Saisie des notes - ${student['name']}",
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: const Color(0xFF140C5F),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Center(
        child: Text(
          "Page de saisie des notes pour ${student['name']} (${student['id']})",
          style: const TextStyle(fontSize: 20),
        ),
      ),
    );
  }
}
