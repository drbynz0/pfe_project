import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '/services/matiere_service.dart';
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
  late MatiereService matiereService;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    matiereService = Provider.of<MatiereService>(context, listen: false);
  }

  // Liste des étudiants avec leurs notes
  List<Map<String, dynamic>> students = [
    {"id": "GI001", "nom": "Mohamed", "prenom": "Ali", "notes": {}},
    {"id": "GI002", "nom": "Ahmed", "prenom": "Fatima", "notes": {}},
    {"id": "GI003", "nom": "Omar", "prenom": "Said", "notes": {}},
    {"id": "ARI001", "nom": "Youssouf", "prenom": "Ali", "notes": {}},
    {"id": "ARI002", "nom": "Amina", "prenom": "Salim", "notes": {}},
  ];

  @override
  Widget build(BuildContext context) {
    final matieres = Provider.of<MatiereService>(context).getMatieres(selectedClass);

    List<Map<String, dynamic>> filteredStudents = students
        .where((student) =>
            student["nom"]!.toLowerCase().contains(searchController.text.toLowerCase()) &&
            student["id"]!.startsWith(selectedClass))
        .toList();

    return Scaffold(
      backgroundColor: const Color(0xFF082E4A),
      appBar: AppBar(
        title: const Text('Saisie des notes', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF140C5F),
        actions: [
          IconButton(
            icon: const Icon(Icons.download, color: Colors.green),
            onPressed: () => _showExportOptions(context),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildClassSelection(),
          _buildSearchBar(),
          Expanded(child: _buildDataTable(filteredStudents, matieres)),
        ],
      ),
    );
  }

  Widget _buildClassSelection() {
    return Container(
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
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: TextField(
        controller: searchController,
        decoration: InputDecoration(
          labelText: "Rechercher un élève",
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(20)),
          prefixIcon: const Icon(Icons.search),
        ),
        onChanged: (value) {
          setState(() {});
        },
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
        backgroundColor: selectedClass == className ? Colors.blue : Colors.grey[300],
        foregroundColor: selectedClass == className ? Colors.white : Colors.black,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
      child: Text(className),
    );
  }

  Widget _buildDataTable(List<Map<String, dynamic>> students, List<Map<String, dynamic>> matieres) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Container(
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
          border: TableBorder.all(color: Colors.blue[200]!),
          headingRowColor: WidgetStateProperty.resolveWith((_) => Colors.blue[200]),
          columns: [
            const DataColumn(label: Text("Code Étudiant", style: TextStyle(fontWeight: FontWeight.bold))),
            const DataColumn(label: Text("Nom & Prénom", style: TextStyle(fontWeight: FontWeight.bold))),
            ...matieres.map((matiere) => DataColumn(label: Text(
              "${matiere["matiere"]} (Coef: ${matiere["coefficient"]})",
              style: const TextStyle(fontWeight: FontWeight.bold),
            ))),
            const DataColumn(label: Text("Action", style: TextStyle(fontWeight: FontWeight.bold))),
          ],
          rows: students.map((student) {
            return DataRow(
              cells: [
                DataCell(Text(student["id"]!)),
                DataCell(Text("${student["nom"]} ${student["prenom"]}")),
                ...matieres.map((matiere) =>
                  DataCell(Center(child: Text(student["notes"][matiere["matiere"]] ?? "-")))
                ),
                DataCell(
                  Center(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => SaisieNotesPage(student: student, matieres: matieres),
                          ),
                        ).then((value) {
                          if (value != null) {
                            setState(() {
                              student["notes"] = value;
                            });
                          }
                        });
                      },
                      child: const Text("Saisir / Modifier"),
                    ),
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  void _showExportOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (_) => Wrap(
        children: [
          ListTile(
            leading: const Icon(Icons.picture_as_pdf, color: Colors.red),
            title: const Text("Exporter en PDF"),
            onTap: () => ExportService.exportToPDF(context, students),
          ),
          ListTile(
            leading: const Icon(Icons.table_chart, color: Colors.green),
            title: const Text("Exporter en Excel"),
            onTap: () => ExportService.exportToExcel(context, students),
          ),
        ],
      ),
    );
  }
}
