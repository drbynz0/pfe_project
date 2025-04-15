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

Future<String?> _showFileNameDialog(BuildContext context) async {
  TextEditingController fileNameController = TextEditingController();
  return showDialog<String>(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: const Text('Mes notes'),
        content: TextField(
          controller: fileNameController,
          decoration: const InputDecoration(hintText: 'Entrez le nom du fichier'),
        ),
        actions: <Widget>[
          TextButton(
            child: const Text('Annuler'),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
          TextButton(
            child: const Text('OK'),
            onPressed: () {
              Navigator.of(context).pop(fileNameController.text);
            },
          ),
        ],
      );
    },
  );
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

    var doc = await FirebaseFirestore.instance
        .collection('Etudiants')
        .doc(studentDocId)
        .get();

    if (doc.exists && doc.data() != null) {
      Map<String, dynamic> data = doc.data()!;
      return data['Notes'] != null ? (data['Notes'] as Map<String, dynamic>).keys.toList() : [];
    }
    return [];
  }

Future<void> _loadNotes(String year) async {
  if (studentDocId == null) return;

  var doc = await FirebaseFirestore.instance
      .collection('Etudiants')
      .doc(studentDocId)
      .get();

  if (doc.exists && doc.data() != null) {
    Map<String, dynamic> data = doc.data()!;

    if (data['Notes'] is Map<String, dynamic> && data['Notes'][year] is Map<String, dynamic>) {
      setState(() {
        selectedYear = year;
        notes = Map<String, dynamic>.from(data['Notes'][year]); // ✅ Correction ici
      });
    } else {
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Aucune note disponible pour l\'année $year.')),
      );
    }
  }
}

  Future<void> _exportToPDF() async {
    if (selectedYear == null || notes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Aucune note à exporter.")),
      );
      return;
    }

    // Afficher la boîte de dialogue pour saisir le nom du fichier
    String? fileName = await _showFileNameDialog(context);
    if (fileName == null || fileName.isEmpty) {
      // L'utilisateur a annulé la boîte de dialogue
      return;
    }

    final pdf = pw.Document();
    pdf.addPage(
      pw.Page(
        build: (pw.Context context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text("Année académique : $selectedYear", style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
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

    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/$fileName.pdf');
    await file.writeAsBytes(await pdf.save());

    // ignore: use_build_context_synchronously
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("PDF enregistré dans ${file.path}")));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 25, 35, 51),
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
                    if (snapshot.hasData && selectedYear == null && snapshot.data!.isNotEmpty) {
                      selectedYear = snapshot.data!.first;
                      _loadNotes(selectedYear!);
                    }
                    return Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: 200,
                          child: DropdownButtonFormField<String>(
                            isExpanded: true,
                            value: selectedYear,
                            hint: const Text("Sélectionner une année"),
                            decoration: const InputDecoration(
                              border: OutlineInputBorder(),
                              filled: true,
                              fillColor: Colors.white,
                            ),
                            items: snapshot.data!.map((year) => DropdownMenuItem(
                              value: year,
                              child: Align(
                                alignment: Alignment.centerLeft,
                                child: Text(year, style: const TextStyle(color: Color.fromARGB(255, 0, 0, 0))),
                              ),
                            )).toList(),
                            onChanged: (value) {
                              if (value != null) _loadNotes(value);
                            },
                          ),
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 20),
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
                Row(
                  children: [
                    const Spacer(),
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
              ],
            ),
          ),
        ),
      ),
    );
  }
}
