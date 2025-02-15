import 'package:flutter/material.dart';

class SaisieNotesPage extends StatefulWidget {
  final Map<String, dynamic> student;

  const SaisieNotesPage({super.key, required this.student});

  @override
  SaisieNotesPageState createState() => SaisieNotesPageState();
}

class SaisieNotesPageState extends State<SaisieNotesPage> {
  late TextEditingController noteController;

  @override
  void initState() {
    super.initState();
    noteController = TextEditingController(text: widget.student["note"]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Saisie des notes - ${widget.student['nom']} ${widget.student['prenom']}"),
        backgroundColor: const Color(0xFF140C5F),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: noteController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: "Entrez la note (0-20)",
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context, noteController.text);
              },
              child: const Text("Enregistrer"),
            ),
          ],
        ),
      ),
    );
  }
}
