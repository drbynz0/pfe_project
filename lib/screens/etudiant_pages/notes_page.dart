import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'dart:io';

class NotesPage extends StatefulWidget {
  const NotesPage({super.key});

  @override
  NotesPageState createState() => NotesPageState();
}

class NotesPageState extends State<NotesPage> {
  String? studentDocId;
  String? selectedYear;
  String? selectedClass;
  Map<String, dynamic> notes = {};
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  void initState() {
    super.initState();
    _findStudentDocument();
  }

  Future<void> _findStudentDocument() async {
    String? uid = _auth.currentUser?.uid;
    if (uid == null) return;

    var querySnapshot = await FirebaseFirestore.instance
        .collection('Etudiants')
        .where('uid', isEqualTo: uid)
        .limit(1)
        .get();

    if (querySnapshot.docs.isNotEmpty) {
      setState(() {
        studentDocId = querySnapshot.docs.first.id;
      });
    }
  }

  Future<List<String>> _loadYears() async {
    if (studentDocId == null) return [];

    var snapshot = await FirebaseFirestore.instance
        .collection('Etudiants')
        .doc(studentDocId)
        .collection('Notes')
        .get();

    return snapshot.docs.map((doc) => doc.id).toList();
  }

  Future<void> _loadNotes(String year) async {
    if (studentDocId == null) return;

    var doc = await FirebaseFirestore.instance
        .collection('Etudiants')
        .doc(studentDocId)
        .collection('Notes')
        .doc(year)
        .get();

    if (doc.exists && doc.data() != null) {
      Map<String, dynamic> data = doc.data()!;
      String firstClass = data.keys.first;
      setState(() {
        selectedYear = year;
        selectedClass = firstClass;
        notes = Map<String, dynamic>.from(data[firstClass]);
      });
    }
  }

  Future<void> _exportToPDF() async {
    if (selectedYear == null || selectedClass == null || notes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Aucune note à exporter.")),
      );
      return;
    }

    final pdf = pw.Document();
    pdf.addPage(
      pw.Page(
        build: (pw.Context context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text("Année académique : $selectedYear", style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
            pw.Text("Classe : $selectedClass", style: pw.TextStyle(fontSize: 16)),
            pw.SizedBox(height: 10),
            // ignore: deprecated_member_use
            pw.Table.fromTextArray(
              context: context,
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              cellAlignment: pw.Alignment.centerLeft,
              data: [
                ["Matière", "Note"],
                ...notes.entries.map((e) => [e.key, e.value.toString()]),
              ],
            ),
          ],
        ),
      ),
    );

    final dir = await getApplicationDocumentsDirectory();
    final file = File("${dir.path}/notes_$selectedYear.pdf");
    await file.writeAsBytes(await pdf.save());

    // ignore: use_build_context_synchronously
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("PDF enregistré dans ${file.path}")));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(221, 34, 57, 94),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Center(
          child: SizedBox(
            width: MediaQuery.of(context).size.width * 0.9,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FutureBuilder<List<String>>(
                  future: _loadYears(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) return const CircularProgressIndicator();
                    return DropdownButton<String>(
                      focusColor: Colors.white,
                      dropdownColor: Colors.white,
                      value: selectedYear,
                      hint: const Text("Sélectionner une année", style: TextStyle(color: Color.fromARGB(255, 0, 0, 0))),
                      items: snapshot.data!.map((year) => DropdownMenuItem(
                        value: year,
                        child: Row(
                          children: [
                            const Spacer(),
                            Text(year, style: const TextStyle(color: Color.fromARGB(255, 0, 0, 0))),
                          ],
                        ),
                      )).toList(),
                      onChanged: (value) {
                        if (value != null) _loadNotes(value);
                      },
                    );
                  },
                ),
                const SizedBox(height: 20),
                if (selectedClass != null)
                  Text("Classe : $selectedClass", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                const SizedBox(height: 10),
                if (notes.isNotEmpty)
                  Expanded(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.vertical,
                      child: Center(
                        child: SizedBox(
                          width: MediaQuery.of(context).size.width * 0.9,
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
                              border: TableBorder.all(
                                color: Colors.blue[200]!,
                                borderRadius: BorderRadius.circular(12),
                                width: 1,
                              ),
                              columnSpacing: 60.0,
                              headingRowColor: WidgetStateProperty.resolveWith<Color?>(
                                (Set<WidgetState> states) => Colors.blue[200],
                              ),
                              dataRowColor: WidgetStateColor.resolveWith((states) => Colors.black54),
                              columns: const [
                                DataColumn(label: Text("Matière", style: TextStyle(fontWeight: FontWeight.bold, color: Color.fromARGB(255, 0, 0, 0)))),
                                DataColumn(label: Text("Note", style: TextStyle(fontWeight: FontWeight.bold, color: Color.fromARGB(255, 0, 0, 0)))),
                              ],
                              rows: notes.entries.map((entry) => DataRow(cells: [
                                DataCell(Text(entry.key, style: const TextStyle(color: Colors.black))), // Met du noir pour la lisibilité
                                DataCell(Text(entry.value.toString(), style: const TextStyle(color: Colors.black))),
                              ])).toList(),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: _exportToPDF,
                  icon: const Icon(Icons.download, color: Colors.white),
                  label: const Text("Exporter en PDF", style: TextStyle(color: Colors.white)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
