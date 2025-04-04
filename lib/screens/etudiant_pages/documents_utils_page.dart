import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class DocumentsUtilsPage extends StatelessWidget {
  const DocumentsUtilsPage({super.key});

  // Liste des documents avec leurs liens de téléchargement
  final List<Map<String, String>> documents = const [
    {"nom": "Cours de Mathématiques", "url": "https://example.com/math.pdf"},
    {"nom": "Cours de Physique", "url": "https://example.com/physique.pdf"},
    {"nom": "Cours d'Informatique", "url": "https://example.com/info.pdf"},
    {"nom": "Cours d'Anglais", "url": "https://example.com/anglais.pdf"},
  ];

  void _telechargerPDF(String url) async {
    // ignore: deprecated_member_use
    if (await canLaunch(url)) {
      // ignore: deprecated_member_use
      await launch(url);
    } else {
      throw 'Impossible d\'ouvrir le lien $url';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF082E4A),
      appBar: AppBar(
        title: const Text("Documents utils", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontFamily: 'Inter Tight'),),
        backgroundColor: const Color(0xFF140C5F),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(10),
        itemCount: documents.length,
        itemBuilder: (context, index) {
          return Card(
            margin: const EdgeInsets.symmetric(vertical: 8),
            elevation: 3,
            child: ListTile(
              leading: const Icon(Icons.picture_as_pdf, color: Colors.red),
              title: Text(documents[index]["nom"]!),
              trailing: ElevatedButton(
                onPressed: () => _telechargerPDF(documents[index]["url"]!),
                child: const Text("Télécharger"),
              ),
            ),
          );
        },
      ),
    );
  }
}
