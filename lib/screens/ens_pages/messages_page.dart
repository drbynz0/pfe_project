import 'package:flutter/material.dart';

class MessagesPage extends StatefulWidget {
  const MessagesPage({super.key});

  @override
  MessagesPageState createState() => MessagesPageState();
}

class MessagesPageState extends State<MessagesPage> {
  TextEditingController searchController = TextEditingController();
  List<Map<String, dynamic>> conversations = [
    {"name": "Administration", "lastMessage": "Réunion prévue demain.", "time": "08:30"},
    {"name": "Classe GI 1", "lastMessage": "Prochain contrôle : lundi.", "time": "10:15"},
    {"name": "Élève Ahmed", "lastMessage": "Monsieur, j’ai une question sur...", "time": "11:45"},
  ];
  List<String> classes = ["GI 1", "GI 2", "ARI 1", "Administration"];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF082E4A),
      appBar: AppBar(
        title: const Text("Messagerie", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF140C5F),
      ),
      body: Column(
        children: [
          _buildSearchBar(),
          _buildClassStatus(),
          Expanded(child: _buildConversationList()),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showNewMessageOptions(context),
        backgroundColor: Colors.blue,
        child: const Icon(Icons.message, color: Colors.white),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: TextField(
        controller: searchController,
        decoration: InputDecoration(
          labelText: "Rechercher une conversation",
          prefixIcon: const Icon(Icons.search, color: Colors.white),
          filled: true,
          // ignore: deprecated_member_use
          fillColor: Colors.white.withOpacity(0.2),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(20)),
        ),
        style: const TextStyle(color: Colors.white),
      ),
    );
  }

Widget _buildClassStatus() {
  return SizedBox(
    height: 80,
    child: ListView.builder(
      scrollDirection: Axis.horizontal,
      itemCount: classes.length,
      itemBuilder: (context, index) {
        return GestureDetector(
          onTap: () {
            // Logique pour envoyer un message à toute la classe
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.blue,
                  child: Text(classes[index][0], style: const TextStyle(color: Colors.white, fontSize: 20)),
                ),
                const SizedBox(height: 5),
                Flexible(
                  child: Text(classes[index], style: const TextStyle(color: Colors.white)),
                ),
              ],
            ),
          ),
        );
      },
    ),
  );
}

  Widget _buildConversationList() {
    return ListView.builder(
      itemCount: conversations.length,
      itemBuilder: (context, index) {
        final conversation = conversations[index];
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ListTile(
            leading: const CircleAvatar(
              backgroundColor: Colors.blue,
              child: Icon(Icons.person, color: Colors.white),
            ),
            title: Text(conversation["name"], style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text(conversation["lastMessage"], maxLines: 1, overflow: TextOverflow.ellipsis),
            trailing: Text(conversation["time"], style: const TextStyle(color: Colors.grey)),
            onTap: () {},
          ),
        );
      },
    );
  }

  void _showNewMessageOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.person, color: Colors.blue),
              title: const Text("Étudiant"),
              onTap: () {},
            ),
            ListTile(
              leading: const Icon(Icons.group, color: Colors.green),
              title: const Text("Parent"),
              onTap: () {},
            ),
            ListTile(
              leading: const Icon(Icons.business, color: Colors.red),
              title: const Text("Administration"),
              onTap: () {},
            ),
            ListTile(
              leading: const Icon(Icons.people, color: Colors.purple),
              title: const Text("Conversation groupée"),
              onTap: () {
                Navigator.pop(context);
                _showGroupChatSelection(context);
              },
            ),
          ],
        );
      },
    );
  }

  void _showGroupChatSelection(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return DefaultTabController(
          length: 2, // Nombre d'onglets
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const TabBar(
                labelColor: Colors.blue,
                unselectedLabelColor: Colors.grey,
                indicatorColor: Colors.blue,
                tabs: [
                  Tab(text: "Étudiants"),
                  Tab(text: "Parents"),
                ],
              ),
              SizedBox(
                height: 300, // Définit une hauteur fixe pour éviter l'overflow
                child: TabBarView(
                  children: [
                    _buildUserSelectionList("Étudiant"),
                    _buildUserSelectionList("Parent"),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    // Ajouter la conversation groupée aux conversations en cours
                  },
                  child: const Text("Lancer la conversation"),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// **Construit la liste de sélection des utilisateurs**
  Widget _buildUserSelectionList(String type) {
    return ListView.builder(
      itemCount: 10, // Exemple d'affichage de 10 utilisateurs
      itemBuilder: (context, index) {
        return CheckboxListTile(
          title: Text("$type $index"),
          value: false,
          onChanged: (bool? value) {},
        );
      },
    );
  }
}
