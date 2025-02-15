import 'package:flutter/material.dart';
import '/services/export_service.dart';
import 'saisie_notes.dart';

class NotesPage extends StatefulWidget {
  const NotesPage({super.key});

  @override
  NotesPageState createState() => NotesPageState();
}

class NotesPageState extends State<NotesPage> {
  String selectedClass = "GI";
  TextEditingController searchController = TextEditingController();

  List<Map<String, dynamic>> students = [
    {"id": "GI001", "nom": "Mohamed", "prenom": "Ali", "note": ""},
    {"id": "GI002", "nom": "Ahmed", "prenom": "Fatima", "note": ""},
    {"id": "GI003", "nom": "Omar", "prenom": "Said", "note": ""},
    {"id": "ARI001", "nom": "Youssouf", "prenom": "Ali", "note": ""},
    {"id": "ARI002", "nom": "Amina", "prenom": "Salim", "note": ""},
  ];

  @override
  Widget build(BuildContext context) {
    List<Map<String, dynamic>> filteredStudents = students
        .where((student) =>
            student["nom"]!.toLowerCase().contains(searchController.text.toLowerCase()) &&
            student["id"]!.startsWith(selectedClass))
        .toList();

    return Scaffold(
      backgroundColor: const Color(0xFF082E4A),
      appBar: AppBar(
        title: const Text(
          'Saisie des notes',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontFamily: 'Inter Tight'),
        ),
        backgroundColor: const Color(0xFF140C5F),
        actions: [
          IconButton(
            icon: const Icon(Icons.download, color: Color.fromARGB(255, 56, 196, 107)),
            onPressed: () => _showExportOptions(context), // Affiche les options d'export
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
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
              style: TextStyle(fontSize: 20, color: Colors.white),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              controller: searchController,
              decoration: InputDecoration(
                labelText: "Rechercher un élève",
                labelStyle: const TextStyle(color: Colors.white),
                border: OutlineInputBorder(
                  borderSide: const BorderSide(color: Colors.white),
                  borderRadius: BorderRadius.circular(20),
                ),
                prefixIcon: const Icon(Icons.search, color: Colors.white),
              ),
              style: const TextStyle(color: Colors.white),
              onChanged: (value) {
                setState(() {}); // Met à jour la liste filtrée
              },
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: _buildDataTable(filteredStudents),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// **Affiche les options d'export**
  void _showExportOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.picture_as_pdf, color: Colors.red),
              title: const Text("Exporter en PDF"),
              onTap: () {
                ExportService.exportToPDF(context, students);
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.table_chart, color: Colors.green),
              title: const Text("Exporter en Excel"),
              onTap: () {
                ExportService.exportToExcel(context, students);
                Navigator.pop(context);
              },
            ),
          ],
        );
      },
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
        backgroundColor: selectedClass == className ? Colors.blue : Colors.grey[300],
        foregroundColor: selectedClass == className ? Colors.white : Colors.black,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
      child: Text(className),
    );
  }

  Widget _buildDataTable(List<Map<String, dynamic>> filteredStudents) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 5,
            spreadRadius: 2,
          )
        ],
      ),
      padding: const EdgeInsets.all(8),
      child: DataTable(
        border: TableBorder.all(
          color: Colors.blue[200]!,
          width: 1,
        ),
        columnSpacing: 20,
        headingRowColor: WidgetStateProperty.resolveWith<Color?>(
          (Set<WidgetState> states) => Colors.blue[200],
        ),
        columns: const [
          DataColumn(label: Text("Code Étudiant", style: TextStyle(fontWeight: FontWeight.bold))),
          DataColumn(label: Text("Nom & Prénom", style: TextStyle(fontWeight: FontWeight.bold)), ),
          DataColumn(label: Text("Note", style: TextStyle(fontWeight: FontWeight.bold)), headingRowAlignment: MainAxisAlignment.center),
          DataColumn(label: Text("Action", style: TextStyle(fontWeight: FontWeight.bold)), headingRowAlignment: MainAxisAlignment.center),
        ],
        rows: filteredStudents.map((student) {
          return DataRow(

            cells: [
              DataCell(Text(student["id"]!)),
              DataCell(Text("${student["nom"]} ${student["prenom"]}")),
              DataCell(Center(child: Text(student["note"].isEmpty ? "-" : student["note"]))),
              DataCell( Center(child: ElevatedButton( onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => SaisieNotesPage(student: student),
                      ),
                    ).then((value) {
                      if (value != null) {
                        setState(() {
                          student["note"] = value;
                        });
                      }
                    });
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                  child: const Text("Saisir /\n Modifier",
                  style: TextStyle(color: Colors.white)),
                ),
              )),
            ],
          );
        }).toList(),
      ),
    );
  }
}
